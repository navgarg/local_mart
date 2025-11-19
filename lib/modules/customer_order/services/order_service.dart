import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/order_model.dart' as app_models;

class OrderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --------------------------------------------------------------------------
  // PLACE ORDER
  // --------------------------------------------------------------------------
  Future<void> placeOrder(
    app_models.Order order, {
    Map<String, dynamic>? perRetailerDelivery,
  }) async {
    final userOrdersRef = _db
        .collection('users')
        .doc(order.userId)
        .collection('orders');

    try {
      await _db.runTransaction((txn) async {
        final orderRef = userOrdersRef.doc(order.id);

        // 1) PREPARE order map first
        final orderMap = Map<String, dynamic>.from(order.toJson());
        if (perRetailerDelivery != null) {
          orderMap['perRetailerDelivery'] = perRetailerDelivery;
        }
        orderMap['createdAt'] = FieldValue.serverTimestamp();
        orderMap['placedAt'] = FieldValue.serverTimestamp();

        // 2) READ STOCK FOR ALL ITEMS FIRST
        final Map<DocumentReference, int> stockMap = {};

        for (final item in order.items) {
          Logger().i("Processing item: ${item.toJson()}");
          Logger().i("Product path: ${item.productPath}");
          final productRef = _db.doc(item.productPath);
          final productSnap = await txn.get(productRef); //  READ FIRST

          if (!productSnap.exists) {
            throw Exception('Product ${item.productId} not found');
          }

          final currentStock = (productSnap.data()!['stock'] ?? 0) as int;
          if (currentStock < item.quantity) {
            throw Exception(
              'Insufficient stock for ${item.productId} '
              '(requested ${item.quantity}, available $currentStock)',
            );
          }

          stockMap[productRef] = currentStock; // store read result
        }

        // 3) NOW WRITE STOCK UPDATES
        stockMap.forEach((productRef, currentStock) {
          txn.update(productRef, {
            'stock':
                currentStock -
                order.items
                    .firstWhere((i) => _db.doc(i.productPath) == productRef)
                    .quantity,
          });
        });

        // 4) WRITE ORDER LAST
        txn.set(orderRef, orderMap);
      });
    } catch (e, st) {
      debugPrint('placeOrder failed: $e\n$st');
      rethrow;
    }
  }

  // --------------------------------------------------------------------------
  //  FETCH / STREAM USER ORDERS
  // --------------------------------------------------------------------------
  Stream<app_models.Order> orderStream(String userId, String orderId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('orders')
        .doc(orderId)
        .snapshots()
        .map((snap) => app_models.Order.fromDoc(snap));
  }

  Future<List<app_models.Order>> fetchOrdersForUser(String userId) async {
    final snapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((d) => app_models.Order.fromDoc(d)).toList();
  }

  Future<void> updateOrderStatus(
    String userId,
    String orderId,
    String newStatus,
  ) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('orders')
        .doc(orderId)
        .update({
          'status': newStatus,
          'lastUpdatedAt': FieldValue.serverTimestamp(),
        });
  }

  // --------------------------------------------------------------------------
  // RESTORE STOCK ON CANCELLATION
  // --------------------------------------------------------------------------
  Future<void> restoreStockForCancelledOrder(
    app_models.Order order, {
    required String cancelStatus,
  }) async {
    final orderRef = _db
        .collection('users')
        .doc(order.userId)
        .collection('orders')
        .doc(order.id);

    try {
      await _db.runTransaction((txn) async {
        // 1) Read order first
        final orderSnap = await txn.get(orderRef);
        if (!orderSnap.exists) throw Exception("Order not found");
        final currentStatus = orderSnap.data()!['status'] as String;

        if (currentStatus == 'cancelled') return;

        // 2) Read all product stocks first (NO updates yet)
        final productRefs = order.items
            .map((i) => _db.doc(i.productPath))
            .toList();
        final productSnaps = await Future.wait(productRefs.map(txn.get));

        // 3) THEN do writes
        for (int i = 0; i < order.items.length; i++) {
          final item = order.items[i];
          txn.update(productRefs[i], {
            'stock': FieldValue.increment(item.quantity),
          });
        }

        txn.update(orderRef, {
          'status': cancelStatus,
          'lastUpdatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      debugPrint("Cancel failed: $e");
      rethrow;
    }
  }

  // --------------------------------------------------------------------------
  // ETA CALCULATION (GROUPED BY RETAILER)
  // --------------------------------------------------------------------------
  Future<Map<String, String>> calculateEtaForAllRetailers({
    required Map<String, List<app_models.OrderItem>> groupedByRetailer,
    required double customerLat,
    required double customerLng,
  }) async {
    final Map<String, String> results = {};

    for (final sellerId in groupedByRetailer.keys) {
      try {
        // Get seller data (not product)
        final sellerDoc = await _db.collection("users").doc(sellerId).get();
        final address = sellerDoc.data()?["address"];

        if (address == null ||
            address["lat"] == null ||
            address["lng"] == null) {
          results[sellerId] = "Estimate unavailable";
          continue;
        }

        final sellerLat = (address["lat"]).toDouble();
        final sellerLng = (address["lng"]).toDouble();

        final meters = Geolocator.distanceBetween(
          sellerLat,
          sellerLng,
          customerLat,
          customerLng,
        );

        final km = meters / 1000.0;

        int days;
        if (km <= 5) {
          days = 1;
        } else if (km <= 200) {
          days = 2;
        } else if (km <= 800) {
          days = 3;
        } else if (km <= 1000) {
          days = 4;
        } else if (km <= 2000) {
          days = 5;
        } else {
          days = 7;
        }

        final etaDate = DateTime.now().add(Duration(days: days));
        results[sellerId] =
            '${km.toStringAsFixed(1)} km (~$days days, ETA ${etaDate.day}/${etaDate.month})';
      } catch (e) {
        debugPrint('ETA calc failed for retailer $sellerId: $e');
        results[sellerId] = 'Estimate unavailable';
      }
    }

    return results;
  }
}
