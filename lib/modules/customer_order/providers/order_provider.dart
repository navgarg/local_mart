import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import '../models/order_model.dart' as models;
import '../services/order_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderProvider with ChangeNotifier {
  final OrderService _service = OrderService();
  final Uuid _uuid = const Uuid();

  bool _isPlacing = false;
  bool get isPlacing => _isPlacing;

  /// 🔹 Place a new order
  /// Products from the same retailer will have same delivery time
  Future<String> placeOrder({
    required String customerId,
    required String customerName,
    required models.Address address,
    required List<models.OrderItem> items,
    required String paymentMethod,
    DateTime? pickupDate,
  }) async {
    _isPlacing = true;
    notifyListeners();

    // ⚠️ Pickup validation: must be within 3 days
    if (paymentMethod == 'pickup') {
      final now = DateTime.now();
      if (pickupDate == null || pickupDate.isAfter(now.add(const Duration(days: 3)))) {
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

    // Compute per-retailer delivery (processingDays = 1)
    final perRetailer = <String, dynamic>{};
    final now = DateTime.now();

    for (var retailerId in groups.keys) {
      const processingDays = 1; // Hardcoded as per team decision
      final transitDays = await _fetchTransitDaysFromCourierAPI(
        pickupPincode: '110020', // Replace with retailer pincode in future
        deliveryPincode: address.pincode,
      );

      final estimated =
      now.add(Duration(days: processingDays + transitDays + 2)); // buffer of 2
      perRetailer[retailerId] = estimated.toIso8601String();
    }

    // Create Order object
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
      pickupDate: pickupDate, // Store pickup date for order tracker
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

  /// 🔹 Stream an order in real time
  Stream<models.Order> watchOrder(String orderId) {
    return _service.orderStream(orderId);
  }

  /// 🔹 Cancel an existing order
  Future<void> cancelOrder(String orderId) async {
    await _service.updateOrderStatus(orderId, 'cancelled');
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
      final token = 'YOUR_SHIPROCKET_API_TOKEN'; // ⚠️ Store securely in production

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
        final estDays = data['data']['available_courier_companies'][0]['etd'] ?? '3-5 Days';
        final parts = estDays.split('-');
        if (parts.length == 2) {
          final avg = ((int.parse(parts[0]) + int.parse(parts[1])) / 2).round();
          return avg;
        }
      }

      return 3; // fallback
    } catch (e) {
      print('Transit fetch error: $e');
      return 3; // fallback
    }
  }
}





