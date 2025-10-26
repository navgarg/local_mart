import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart' as models;
import '../services/order_service.dart';
import 'dart:async';


class OrderProvider with ChangeNotifier {
  final OrderService _service = OrderService();
  final Uuid _uuid = const Uuid();

  bool _isPlacing = false;
  bool get isPlacing => _isPlacing;

  models.Order? _activeOrder;
  models.Order? get activeOrder => _activeOrder;

  StreamSubscription<DocumentSnapshot>? _orderSubscription;

  /// 🔹 Place a new order
  Future<String> placeOrder({
    required String customerId,
    required String customerName,
    required models.Address address,
    required List<models.OrderItem> items,
    required String paymentMethod, // 'online' | 'cod'
    required String receivingMethod, // 'delivery' | 'pickup'
    DateTime? pickupDate,
  }) async {
    _isPlacing = true;
    notifyListeners();

    final now = DateTime.now();

    // ⚠️ Pickup validation: must be within 3 days
    if (receivingMethod == 'pickup') {
      if (pickupDate == null ||
          pickupDate.isAfter(now.add(const Duration(days: 3)))) {
        _isPlacing = false;
        notifyListeners();
        throw Exception('Pickup date must be within 3 days from today.');
      }
    }

    final orderId = _uuid.v4();
    final total = items.fold(0.0, (sum, it) => sum + it.price * it.quantity);

    // Group items by retailer
    final groups = <String, List<models.OrderItem>>{};
    for (var it in items) {
      groups.putIfAbsent(it.retailerId, () => []).add(it);
    }

    // Compute per-retailer delivery only for delivery orders
    final perRetailer = <String, dynamic>{};
    if (receivingMethod == 'delivery') {
      for (var retailerId in groups.keys) {
        const processingDays = 1;
        final transitDays = await _fetchTransitDaysFromCourierAPI(
          pickupPincode: '110020', // TODO: replace with retailer pincode
          deliveryPincode: address.pincode,
        );

        final estimated =
        now.add(Duration(days: processingDays + transitDays + 2));
        perRetailer[retailerId] = estimated.toIso8601String();
      }
    }

    final order = models.Order(
      id: orderId,
      customerId: customerId,
      customerName: customerName,
      deliveryAddress: address,
      items: items,
      totalAmount: total,
      paymentMethod: paymentMethod,
      receivingMethod: receivingMethod,
      status: 'Not Yet Shipped', // 👈 default initial state
      createdAt: Timestamp.now(),
      perRetailerDelivery: perRetailer,
      pickupDate: pickupDate,
    );

    try {
      await _service.placeOrder(order);
      _isPlacing = false;
      notifyListeners();
      return orderId;
    } catch (e) {
      _isPlacing = false;
      notifyListeners();
      rethrow;
    }
  }

  /// 🔹 Listen to real-time order updates
  void listenToOrder(String orderId) {
    stopListeningToOrder(orderId); // prevent duplicate listeners
    _orderSubscription = FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        _activeOrder = models.Order.fromFirestore(snapshot);
        notifyListeners();
      }
    });
  }

  /// 🔹 Stop listening to a specific order
  void stopListeningToOrder(String orderId) {
    _orderSubscription?.cancel();
    _orderSubscription = null;
  }

  /// 🔹 Get order by ID
  models.Order? getOrderById(String orderId) {
    if (_activeOrder?.id == orderId) return _activeOrder;
    return null;
  }

  /// 🔹 Refresh order (manual reload)
  Future<void> refreshOrder(String orderId) async {
    final doc =
    await FirebaseFirestore.instance.collection('orders').doc(orderId).get();
    if (doc.exists) {
      _activeOrder = models.Order.fromFirestore(doc);
      notifyListeners();
    }
  }

  /// 🔹 Cancel order (only if not shipped)
  Future<void> cancelOrder(String orderId) async {
    if (_activeOrder == null) {
      throw Exception('Order not loaded yet. Please try again.');
    }

    final currentStatus = _activeOrder!.status;

    // Only cancel if not yet shipped
    if (currentStatus != 'Not Yet Shipped') {
      throw Exception('This order cannot be cancelled anymore.');
    }

    await _service.updateOrderStatus(orderId, 'Cancelled');
    _activeOrder = _activeOrder!.copyWith(status: 'Cancelled');
    notifyListeners();
  }

  /// 🔹 Fetch transit days from Shiprocket API
  Future<int> _fetchTransitDaysFromCourierAPI({
    required String pickupPincode,
    required String deliveryPincode,
  }) async {
    try {
      final url = Uri.parse(
          'https://apiv2.shiprocket.in/v1/external/courier/serviceability/');
      final token = 'YOUR_SHIPROCKET_API_TOKEN'; // ⚠️ Replace securely

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'pickup_postcode': pickupPincode,
          'delivery_postcode': deliveryPincode,
          'cod': 0,
          'weight': 0.5,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final estDays =
            data['data']['available_courier_companies'][0]['etd'] ?? '3-5 Days';
        final parts = estDays.split('-');
        if (parts.length == 2) {
          final avg = ((int.parse(parts[0]) + int.parse(parts[1])) / 2).round();
          return avg;
        }
      }

      return 3; // fallback
    } catch (e) {
      print('Transit fetch error: $e');
      return 3;
    }
  }
}






