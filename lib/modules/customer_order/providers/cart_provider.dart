import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:local_mart/services/alert_service.dart';

import '../models/order_model.dart' as app_models;
import '../services/order_service.dart';

class CartProvider with ChangeNotifier {
  final OrderService _orderService = OrderService();
  final AlertService _alertService = AlertService();

  // 🛒 Local cart items: productId -> OrderItem
  final Map<String, app_models.OrderItem> _items = {};

  // Cache and ETA helpers
  final Map<String, int> _stockCache = {};
  Map<String, String> _perRetailerEstimates = {};
  Map<String, String> _etaCache = {};
  DateTime? _lastFetchTime;

  // -------------------- Getters --------------------

  int getItemQuantity(String productId) => _items[productId]?.quantity ?? 0;

  bool get isEmpty => _items.isEmpty;
  List<app_models.OrderItem> get items => List.unmodifiable(_items.values);

  double get total => _items.values.fold(0, (s, i) => s + i.price * i.quantity);
  double get gst => total * 0.05;
  double get convenienceFee => 10.0;
  double get finalTotal => total + gst + convenienceFee;

  int get totalItems => _items.values.fold(0, (s, i) => s + i.quantity);

  Map<String, String> get perRetailerEstimates =>
      Map.unmodifiable(_perRetailerEstimates);

  // --------------------------------------------------------------------------
  // Firestore stock fetching + proper stock limiting
  // --------------------------------------------------------------------------
  Future<void> fetchStock(String productId, String productPath) async {
    try {
      debugPrint(
        'Fetching stock for productId: $productId, path: $productPath',
      );
      final doc = await FirebaseFirestore.instance.doc(productPath).get();
      if (doc.exists) {
        final data = doc.data();
        debugPrint('Fetched document data for $productId: $data');
        if (data?['stock'] != null) {
          _stockCache[productId] = (data!['stock'] as num).toInt();
          debugPrint('Stock for $productId set to: ${_stockCache[productId]}');
        } else {
          _stockCache[productId] = 0;
          debugPrint(
            'Stock field not found or is null for $productId. Setting to 0.',
          );
        }
      } else {
        _stockCache[productId] = 0;
        debugPrint(
          'Document does not exist for $productId. Setting stock to 0.',
        );
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to fetch stock for $productId: $e');
    }
  }

  void setStock(String productId, int stock) {
    _stockCache[productId] = stock;
  }

  int getStock(String productId) => _stockCache[productId] ?? 0;

  bool canIncrease(String productId) {
    final item = _items[productId];
    if (item == null) return false;
    final stock = getStock(productId);
    return stock == 0 ? true : item.quantity < stock;
  }

  // --------------------------------------------------------------------------
  // Cart Management
  // --------------------------------------------------------------------------
  void addItem(app_models.OrderItem item) {
    final maxStock = getStock(item.productId);

    if (_items.containsKey(item.productId)) {
      final existing = _items[item.productId]!;
      if (maxStock == 0 || existing.quantity < maxStock) {
        _items[item.productId] = existing.copyWith(
          quantity: existing.quantity + 1,
        );
      }
    } else {
      _items[item.productId] = item.copyWith(quantity: 1);
    }

    notifyListeners();
  }

  void increaseQuantity(String productId) {
    final item = _items[productId];
    if (item == null) return;
    if (canIncrease(productId)) addItem(item);
  }

  void decreaseQuantity(String productId) {
    final item = _items[productId];
    if (item == null) return;

    if (item.quantity > 1) {
      _items[productId] = item.copyWith(quantity: item.quantity - 1);
    } else {
      _items.remove(productId);
    }

    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  bool contains(String productId) => _items.containsKey(productId);

  void clear() {
    _items.clear();
    _stockCache.clear();
    _perRetailerEstimates.clear();
    _etaCache.clear();
    _lastFetchTime = null;
    notifyListeners();
  }

  // --------------------------------------------------------------------------
  // Group by Retailer
  // --------------------------------------------------------------------------
  Map<String, List<app_models.OrderItem>> groupedByRetailer() {
    final Map<String, List<app_models.OrderItem>> grouped = {};
    for (final item in _items.values) {
      grouped.putIfAbsent(item.sellerId, () => []).add(item);
    }
    return grouped;
  }

  // --------------------------------------------------------------------------
  // Order Placement
  // --------------------------------------------------------------------------
  Future<void> placeOrder({
    required String userId,
    required String customerName,
    required app_models.Address deliveryAddress,
    required String paymentMethod, // e.g. 'razorpay', 'cod'
    required String receivingMethod, // 'delivery' or 'pickup'
    Map<String, String>? perRetailerDelivery,
  }) async {
    if (_items.isEmpty) return;

    final List<app_models.OrderItem> orderItems = _items.values.toList();
    final Map<String, String> deliveryMap =
        perRetailerDelivery ?? _perRetailerEstimates;

    final order = app_models.Order(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      customerName: customerName,
      deliveryAddress: deliveryAddress,
      items: orderItems,
      totalAmount: finalTotal,
      paymentMethod: paymentMethod,
      receivingMethod: receivingMethod,
      status: 'order_placed',
      createdAt: Timestamp.now(),
      placedAt: DateTime.now(),
      perRetailerDelivery: deliveryMap,
      expectedDelivery: null,
      pickupDate: null,
      etaDays: null,
      razorpayOrderId: null,
      razorpayPaymentId: null,
      razorpaySignature: null,
    );

    await _orderService.placeOrder(order, perRetailerDelivery: deliveryMap);

    // Generate alerts for retailers
    final grouped = groupedByRetailer();
    // for (final retailerId in grouped.keys) {
    //   final retailerItems = grouped[retailerId]!;
    //   final message = "New order placed by ${customerName} for items: ${retailerItems.map((e) => e.name).join(', ')}.";
    //   _alertService.addAlert(Alert(
    //     id: DateTime.now().millisecondsSinceEpoch.toString(),
    //     userId: retailerId, // The retailer's ID
    //     message: message,
    //     type: "new_order",
    //     timestamp: Timestamp.now(),
    //   ));
    // }

    clear();
  }

  // --------------------------------------------------------------------------
  // ETA Calculation (Fix #1 - updated regex)
  // --------------------------------------------------------------------------
  Future<void> fetchEtas({
    required double customerLat,
    required double customerLng,
  }) async {
    if (_items.isEmpty) return;

    final cacheValid =
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) <
            const Duration(minutes: 30);

    if (cacheValid && _etaCache.isNotEmpty) {
      updateEtas(_etaCache);
      return;
    }

    try {
      final grouped = groupedByRetailer();
      final newEtas = await _orderService.calculateEtaForAllRetailers(
        groupedByRetailer: grouped,
        customerLat: customerLat,
        customerLng: customerLng,
      );
      _etaCache = newEtas;
      _lastFetchTime = DateTime.now();
      updateEtas(newEtas);
    } catch (e) {
      debugPrint('ETA fetch failed: $e');
    }
  }

  void updateEtas(Map<String, String> newEtas) {
    _perRetailerEstimates = Map.from(newEtas);
    notifyListeners();
  }

  // ETA parsing
  String get overallEstimate {
    if (_perRetailerEstimates.isEmpty) return 'Calculating...';

    final days = _perRetailerEstimates.values
        .map((txt) => RegExp(r'~\s*(\d+)\s*days').firstMatch(txt))
        .where((m) => m != null)
        .map((m) => int.parse(m!.group(1)!))
        .toList();

    if (days.isEmpty) return 'Estimate unavailable';
    final maxDays = days.reduce((a, b) => a > b ? a : b);
    final date = DateTime.now().add(Duration(days: maxDays));
    return '~$maxDays days (by ${DateFormat('d MMM').format(date)})';
  }
}
