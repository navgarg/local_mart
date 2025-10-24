import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/order_model.dart' as models;
import '../services/order_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderProvider with ChangeNotifier {
  final OrderService _service = OrderService();
  final Uuid _uuid = const Uuid();

  bool _isPlacing = false;
  bool get isPlacing => _isPlacing;

  Future<String> placeOrder({
    required String customerId,
    required String customerName,
    required models.Address address,
    required List<models.OrderItem> items,
    required String paymentMethod,
    DateTime? pickupDate, // when paymentMethod == 'pickup'
  }) async {
    _isPlacing = true;
    notifyListeners();

    final orderId = _uuid.v4();
    // compute total
    final total = items.fold(0.0, (s, it) => s + it.price * it.quantity);

    // compute per-retailer delivery estimate (mock logic)
    final perRetailer = <String, dynamic>{};
    final now = DateTime.now();
    final groups = <String, List<models.OrderItem>>{};
    for (var it in items) {
      groups.putIfAbsent(it.retailerId, () => []).add(it);
    }

    // For each retailer: processingDays should come from retailer info (mock 2)
    // transitDays from courier API (mocked as 3)
    for (var retailerId in groups.keys) {
      final int processingDays = 2; // ideally fetched from retailer profile
      final int transitDays = 3; // or fetched from courier API
      final estimated = now.add(Duration(days: processingDays + transitDays + 2)); // + buffer 2
      perRetailer[retailerId] = estimated.toIso8601String();
    }

    final order = models.Order(
      id: orderId,
      customerId: customerId,
      customerName: customerName,
      deliveryAddress: address,
      items: items,
      totalAmount: total,
      paymentMethod: paymentMethod,
      status: 'placed',
      createdAt: Timestamp.now(),
      perRetailerDelivery: perRetailer,
    );

    try {
      await _service.placeOrder(order);
      // optionally: create a temp cart doc before, or delete existing temp cart
      _isPlacing = false;
      notifyListeners();
      return orderId;
    } catch (e) {
      _isPlacing = false;
      notifyListeners();
      rethrow;
    }
  }

  Stream<models.Order> watchOrder(String orderId) {
    return _service.orderStream(orderId);
  }
}
