import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emailjs/emailjs.dart' as emailjs;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';

import '../models/order_model.dart' as models;
import '../services/order_service.dart';
import '../utils/calendar_helper.dart';
import '../utils/notification_helper.dart';
import '../utils/user_category_stats.dart';

class OrderProvider with ChangeNotifier {
  OrderProvider();

  final OrderService _service = OrderService();
  final Uuid _uuid = const Uuid();

  bool _isPlacing = false;
  bool get isPlacing => _isPlacing;

  models.Order? _activeOrder;
  models.Order? get activeOrder => _activeOrder;

  StreamSubscription<models.Order>? _orderSubscription;
  Timer? _statusTimer;

  // --------------------------------------------------------------------------
  // Firestore Notification Sender (per-user subcollection)
  // --------------------------------------------------------------------------
  Future<void> _sendNotification({
    required String userId,
    required String title,
    required String message,
    required String status,
    required String orderId,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
            'title': title,
            'message': message,
            'status': status,
            'orderId': orderId,
            'timestamp': FieldValue.serverTimestamp(),
            'read': false,
          });
    } catch (e) {
      debugPrint('Failed to send notification: $e');
    }
  }

  // --------------------------------------------------------------------------
  // Refresh order data manually (non-stream)
  // --------------------------------------------------------------------------
  Future<void> refreshOrder(String userId, String orderId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('orders')
          .doc(orderId)
          .get();

      if (!doc.exists) return;
      _activeOrder = models.Order.fromDoc(doc);
      notifyListeners();
    } catch (e) {
      debugPrint("Failed to refresh order: $e");
    }
  }

  // --------------------------------------------------------------------------
  // Razorpay key helper
  // --------------------------------------------------------------------------
  Future<String> getRazorpayKey() async {
    final key = dotenv.env['RAZORPAY_KEY'];
    if (key == null || key.isEmpty)
      throw Exception('Razorpay key missing in .env');
    return key;
  }

  // --------------------------------------------------------------------------
  // Place Order
  // --------------------------------------------------------------------------
  Future<String> placeOrder({
    required String userId,
    required String customerName,
    required models.Address address,
    required List<models.OrderItem> items,
    required String paymentMethod, // 'online' | 'cod'
    required String receivingMethod, // 'delivery' | 'pickup'
    DateTime? pickupDate,
    required dynamic cartProvider,
    String? razorpayPaymentId,
  }) async {
    _isPlacing = true;
    notifyListeners();

    final now = DateTime.now();

    // Validate pickup conditions
    if (receivingMethod == 'pickup') {
      if (pickupDate == null ||
          pickupDate.isAfter(now.add(const Duration(days: 3)))) {
        _isPlacing = false;
        notifyListeners();
        throw Exception('Pickup date must be within 3 days.');
      }
      if (paymentMethod == 'cod') {
        _isPlacing = false;
        notifyListeners();
        throw Exception('COD not available for pickup orders.');
      }
    }

    // Compute total
    double total = 0.0;
    try {
      total = double.parse(
        (cartProvider.finalTotal as double).toStringAsFixed(2),
      );
    } catch (_) {}

    // Group items by seller
    final Map<String, List<models.OrderItem>> groupedBySeller = {};
    for (var item in items) {
      groupedBySeller.putIfAbsent(item.sellerId, () => []).add(item);
    }

    // Get ETA map
    Map<String, String> sellerEtas = {};
    int maxEtaDays = 5;
    try {
      sellerEtas = await _service.calculateEtaForAllRetailers(
        groupedByRetailer: groupedBySeller,
        customerLat: address.lat,
        customerLng: address.lng,
      );

      // Parse day numbers
      final days = sellerEtas.values
          .map((e) => _extractDaysFromEta(e))
          .where((d) => d != null)
          .cast<int>()
          .toList();

      if (days.isNotEmpty) maxEtaDays = days.reduce((a, b) => a > b ? a : b);
    } catch (e) {
      debugPrint('ETA calc failed: $e');
    }

    final orderId = _uuid.v4();

    // Build order model
    final order = models.Order(
      id: orderId,
      userId: userId,
      customerName: customerName,
      deliveryAddress: address,
      items: items,
      totalAmount: total,
      paymentMethod: paymentMethod,
      receivingMethod: receivingMethod,
      status: receivingMethod == 'pickup' ? 'preparing' : 'order_placed',
      createdAt: Timestamp.now(),
      placedAt: DateTime.now(),
      perRetailerDelivery: sellerEtas.map(
        (id, eta) => MapEntry(id, {'eta': eta}),
      ),
      pickupDate: pickupDate,
      etaDays: maxEtaDays,
      expectedDelivery: now.add(Duration(days: maxEtaDays)),
      razorpayPaymentId: razorpayPaymentId,
    );

    try {
      await _service.placeOrder(
        order,
        perRetailerDelivery: order.perRetailerDelivery,
      );
      //Update category stats in user's document
      try {
        await updateUserCategoryStats(userId, items);
      } catch (e) {
        debugPrint(' Failed to update category stats: $e');
      }

      // Notify retailers
      for (var item in items) {
        try {
          await FirebaseFirestore.instance
              .collection("users")
              .doc(item.sellerId)
              .collection("customer_orders")
              .add({
                "customerId": userId,
                "orderId": orderId,
                "type": "new_order",
                "deliveryMethod": receivingMethod,
                "timestamp": FieldValue.serverTimestamp(),
                if (receivingMethod == "pickup" && pickupDate != null)
                  "pickupDate": pickupDate.toIso8601String(),
              });
        } catch (e) {
          debugPrint('Failed to notify seller ${item.sellerId}: $e');
        }
      }

      // Schedule reminders
      try {
        if (receivingMethod == 'delivery' && order.expectedDelivery != null) {
          await CalendarHelper.addOrderEvent(
            title: 'Delivery Expected',
            description: 'Your LocalMart order arrives today',
            date: order.expectedDelivery!,
          );

          await NotificationHelper.scheduleReminder(
            title: 'Delivery Reminder',
            body: 'Your LocalMart order arrives today!',
            date: DateTime(
              order.expectedDelivery!.year,
              order.expectedDelivery!.month,
              order.expectedDelivery!.day,
              8,
            ),
          );
        } else if (pickupDate != null) {
          await CalendarHelper.addOrderEvent(
            title: 'Pickup Reminder',
            description: 'Pick up your LocalMart order today',
            date: pickupDate,
          );
        }
      } catch (e) {
        debugPrint('Reminder scheduling failed: $e');
      }

      cartProvider.clear();
      if (receivingMethod == 'pickup' && pickupDate != null) {
        _simulatePickupProgress(userId, orderId, pickupDate);
      } else {
        _simulateOrderProgress(userId, orderId, maxEtaDays);
      }

      await _sendNotification(
        userId: userId,
        title: 'Order Placed',
        message: 'Your order has been placed successfully!',
        status: order.status,
        orderId: orderId,
      );
      await _sendEmailIfNeeded(
        userId: userId,
        status: 'order_placed',
        orderId: orderId,
      );

      _isPlacing = false;
      notifyListeners();
      return orderId;
    } catch (e) {
      _isPlacing = false;
      notifyListeners();
      rethrow;
    }
  }

  // --------------------------------------------------------------------------
  // Listen to order updates
  // --------------------------------------------------------------------------
  void listenToOrder(String userId, String orderId) {
    stopListeningToOrder();
    _orderSubscription = _service
        .orderStream(userId, orderId)
        .listen(
          (order) {
            _activeOrder = order;
            notifyListeners();
          },
          onError: (e) {
            debugPrint('Order stream error: $e');
          },
        );
  }

  void stopListeningToOrder() {
    _orderSubscription?.cancel();
    _statusTimer?.cancel();
    _orderSubscription = null;
    _statusTimer = null;
  }

  // --------------------------------------------------------------------------
  // Cancel pickup order
  // --------------------------------------------------------------------------
  Future<void> cancelPickupOrder(String orderId, String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('orders')
          .doc(orderId)
          .get();

      if (!doc.exists) throw Exception("Order not found");

      final order = models.Order.fromDoc(doc);
      if (order.status != "preparing") {
        throw Exception("Pickup order cannot be cancelled now.");
      }

      await _service.restoreStockForCancelledOrder(
        order,
        cancelStatus: "pickup_cancelled",
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('orders')
          .doc(orderId)
          .update({
            "status": "pickup_cancelled",
            "cancelledAt": FieldValue.serverTimestamp(),
          });

      await _sendNotification(
        userId: order.userId,
        title: "Pickup Cancelled",
        message: "Your pickup order has been cancelled.",
        status: "pickup_cancelled",
        orderId: orderId,
      );
      await _sendEmailIfNeeded(
        userId: userId,
        status: 'pickup_cancelled',
        orderId: orderId,
      );

      notifyListeners();
    } catch (e) {
      debugPrint("Cancel pickup failed: $e");
      rethrow;
    }
  }

  // --------------------------------------------------------------------------
  // Cancel delivery order
  // --------------------------------------------------------------------------
  Future<void> cancelOrder(String userId, String orderId) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('orders')
        .doc(orderId)
        .get();

    if (!doc.exists) throw Exception('Order not found');
    final order = models.Order.fromDoc(doc);

    if (order.status != 'order_placed') {
      throw Exception('Order cannot be cancelled now.');
    }

    await _service.restoreStockForCancelledOrder(
      order,
      cancelStatus: "cancelled",
    );

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('orders')
        .doc(orderId)
        .update({
          "status": "cancelled",
          "cancelledAt": FieldValue.serverTimestamp(),
        });

    await _sendNotification(
      userId: userId,
      title: 'Order Cancelled',
      message: 'Your order has been cancelled.',
      orderId: orderId,
      status: 'cancelled',
    );
    await _sendEmailIfNeeded(
      userId: userId,
      status: 'cancelled',
      orderId: orderId,
    );

    notifyListeners();
  }

  // --------------------------------------------------------------------------
  // Simulated status progression (demo only)
  // --------------------------------------------------------------------------
  void _simulateOrderProgress(String userId, String orderId, int etaDays) {
    _statusTimer?.cancel();

    final shippedAt = Duration(days: (etaDays * 0.25).round());
    final outForDeliveryAt = Duration(days: (etaDays * 0.75).round());
    final totalDuration = Duration(days: etaDays);

    _statusTimer = Timer.periodic(const Duration(hours: 1), (timer) async {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('orders')
            .doc(orderId)
            .get();

        if (!doc.exists) {
          timer.cancel();
          return;
        }

        final order = models.Order.fromDoc(doc);

        // STOP IF NON-SIMULATABLE STATE
        if (order.status == 'cancelled' ||
            order.status == 'pickup_cancelled' ||
            order.status == 'delivered') {
          timer.cancel();
          return;
        }

        //  STOP IF PICKUP ORDER
        if (order.receivingMethod == 'pickup') {
          timer.cancel();
          return;
        }

        final elapsed = DateTime.now().difference(order.placedAt);

        String? newStatus;
        if (elapsed >= totalDuration) {
          newStatus = 'delivered';
        } else if (elapsed >= outForDeliveryAt) {
          newStatus = 'out_for_delivery';
        } else if (elapsed >= shippedAt) {
          newStatus = 'shipped';
        }

        if (newStatus != null && newStatus != order.status) {
          await _service.updateOrderStatus(userId, orderId, newStatus);

          await _sendNotification(
            userId: userId,
            title: 'Order $newStatus',
            message: 'Your order is now $newStatus.',
            status: newStatus,
            orderId: orderId,
          );

          if (newStatus == 'delivered') {
            await _sendEmailIfNeeded(
              userId: userId,
              status: 'delivered',
              orderId: order.id,
            );
            timer.cancel(); //delivery finished
          }
        }
      } catch (e) {
        debugPrint('Sim progress error: $e');
      }
    });
  }

  void _simulatePickupProgress(
    String userId,
    String orderId,
    DateTime pickupDate,
  ) {
    _statusTimer?.cancel();

    _statusTimer = Timer.periodic(const Duration(hours: 1), (timer) async {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('orders')
            .doc(orderId)
            .get();

        if (!doc.exists) {
          timer.cancel();
          return;
        }

        final order = models.Order.fromDoc(doc);

        //STOP if cancelled or finished
        if (order.status == 'pickup_cancelled' || order.status == 'picked') {
          timer.cancel();
          return;
        }

        final elapsedDays = DateTime.now().difference(order.placedAt).inDays;

        String? newStatus;

        // After 1 day → READY
        if (elapsedDays >= 1 && order.status == "preparing") {
          newStatus = "ready";
        }

        // On pickup day → PICKED
        final now = DateTime.now();
        if (order.status == "ready" &&
            pickupDate.year == now.year &&
            pickupDate.month == now.month &&
            pickupDate.day == now.day) {
          newStatus = "picked";
        }

        if (newStatus != null) {
          await _service.updateOrderStatus(userId, orderId, newStatus);

          await _sendNotification(
            userId: userId,
            title: "Order $newStatus",
            message: "Your pickup order is now $newStatus.",
            status: newStatus,
            orderId: orderId,
          );

          if (newStatus == "picked") {
            await _sendEmailIfNeeded(
              userId: userId,
              status: "delivered",
              orderId: orderId,
            );
            timer.cancel();
          }
        }
      } catch (e) {
        debugPrint("Pickup sim error: $e");
      }
    });
  }

  // --------------------------------------------------------------------------
  // ETA Parser (no ~ symbol)
  // --------------------------------------------------------------------------
  int? _extractDaysFromEta(String eta) {
    final match = RegExp(r'(\d+)\s*days').firstMatch(eta);
    if (match != null) return int.tryParse(match.group(1)!);
    return null;
  }

  @override
  void dispose() {
    stopListeningToOrder();
    super.dispose();
  }

  //Sending email
  Future<void> _sendEmailIfNeeded({
    required String userId,
    required String
    status, // order_placed | cancelled | pickup_cancelled | delivered
    required String orderId,
  }) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      final toEmail = (userDoc.data()?['email'] ?? '').toString().trim();
      if (toEmail.isEmpty) return; // no email on file → skip

      String subject;
      String body;

      switch (status) {
        case 'order_placed':
          subject = 'Your LocalMart Order is Confirmed ';
          body = 'Hello! Your order $orderId has been successfully placed.';
          break;

        case 'cancelled':
        case 'pickup_cancelled':
          subject = 'Your LocalMart Order was Cancelled';
          body = 'Your order $orderId has been cancelled.';
          break;

        case 'delivered':
          subject = 'Your LocalMart Order was Delivered';
          body = 'Good news! Your order $orderId has been delivered.';
          break;

        default:
          return; // ignore other statuses
      }

      await emailjs.send(
        'EMAILJS_SERVICE_ID',
        'EMAILJS_TEMPLATE_ID',
        {'to_email': toEmail, 'subject': subject, 'message': body},
        const emailjs.Options(publicKey: 'EMAILJS_PUBLIC_KEY'),
      );
    } catch (e) {
      debugPrint('Email send skipped/failed: $e');
    }
  }

  Future<void> maybeAutoAdvanceOrderStatus(
    String userId,
    String orderId,
  ) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('orders')
        .doc(orderId)
        .get();

    if (!doc.exists) return;
    final order = models.Order.fromDoc(doc);

    // Skip pickup orders
    if (order.receivingMethod == 'pickup') return;

    //Skip cancelled/delivered
    if (order.status == 'delivered' ||
        order.status == 'cancelled' ||
        order.status == 'pickup_cancelled')
      return;

    final elapsed = DateTime.now().difference(order.placedAt);
    final etaDays = order.etaDays ?? 3;

    String? newStatus;

    if (elapsed.inDays >= etaDays)
      newStatus = "delivered";
    else if (elapsed.inDays >= (etaDays * 0.75).round())
      newStatus = "out_for_delivery";
    else if (elapsed.inDays >= (etaDays * 0.25).round())
      newStatus = "shipped";

    if (newStatus != null && newStatus != order.status) {
      await _service.updateOrderStatus(userId, orderId, newStatus);
      await _sendNotification(
        userId: order.userId,
        title: 'Order $newStatus',
        message: 'Your order is now $newStatus.',
        status: newStatus,
        orderId: orderId,
      );
      notifyListeners();
    }
  }

  Future<void> autoRefreshAllOrders(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('orders')
        .get();

    for (final doc in snapshot.docs) {
      final order = models.Order.fromDoc(doc);

      //Skip finished or cancelled orders
      if (order.status == 'delivered' ||
          order.status == 'cancelled' ||
          order.status == 'pickup_cancelled' ||
          order.status == 'picked') {
        continue;
      }

      //Handle PICKUP ORDERS auto-progression
      if (order.receivingMethod == 'pickup') {
        final elapsedDays = DateTime.now().difference(order.placedAt).inDays;
        String? newStatus;

        // Preparing → Ready (after 1 day)
        if (elapsedDays >= 1 && order.status == "preparing") {
          newStatus = "ready";
        }

        // Ready → Picked (on pickup date)
        final pickupDate = order.pickupDate;
        if (pickupDate != null &&
            order.status == "ready" &&
            DateTime.now().year == pickupDate.year &&
            DateTime.now().month == pickupDate.month &&
            DateTime.now().day == pickupDate.day) {
          newStatus = "picked";
        }

        if (newStatus != null && newStatus != order.status) {
          await _service.updateOrderStatus(userId, order.id, newStatus);

          await _sendNotification(
            userId: userId,
            title: "Order $newStatus",
            message: "Your pickup order is now $newStatus.",
            status: newStatus,
            orderId: order.id,
          );

          await _sendEmailIfNeeded(
            userId: userId,
            status: newStatus == "picked" ? "delivered" : newStatus,
            orderId: order.id,
          );
        }

        continue; //move to next order safely
      }

      // Skip orders without ETA (just in case)
      if (order.etaDays == null) continue;

      final elapsed = DateTime.now().difference(order.placedAt);
      final etaDays = order.etaDays!;
      final shippedAt = Duration(days: (etaDays * 0.25).round());
      final outForDeliveryAt = Duration(days: (etaDays * 0.75).round());
      final deliveredAt = Duration(days: etaDays);

      String? newStatus;

      if (elapsed >= deliveredAt)
        newStatus = 'delivered';
      else if (elapsed >= outForDeliveryAt)
        newStatus = 'out_for_delivery';
      else if (elapsed >= shippedAt)
        newStatus = 'shipped';

      if (newStatus != null && newStatus != order.status) {
        await _service.updateOrderStatus(userId, order.id, newStatus);
        await _sendNotification(
          userId: userId,
          title: 'Order $newStatus',
          message: 'Your order is now $newStatus.',
          status: newStatus,
          orderId: order.id,
        );
        if (newStatus == 'delivered') {
          await _sendEmailIfNeeded(
            userId: userId,
            status: 'delivered',
            orderId: order.id,
          );
        }
      }
    }
  }
}
