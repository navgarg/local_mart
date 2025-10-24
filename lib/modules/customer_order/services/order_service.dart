import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_mart/modules/customer_order/models/order_model.dart' as models;

class OrderService
{
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String ordersColl = 'orders';
  final String cartsColl = 'temp_carts';

  // Create temporary cart in Firestore (optional)
  Future<String> createTempCart(String userId, List<models.OrderItem> items) async {
    final docRef = await _db.collection(cartsColl).add({
      'userId': userId,
      'items': items.map((e) => e.toJson()).toList(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  // Place order (creates order doc)
  Future<void> placeOrder(models.Order order) async {
    final docRef = _db.collection(ordersColl).doc(order.id);
    await docRef.set(order.toJson());
  }

  // Listen to order changes (real-time)
  Stream<models.Order> orderStream(String orderId) {
    final docRef = _db.collection(ordersColl).doc(orderId);
    return docRef.snapshots().map((snap) => models.Order.fromDoc(snap));
  }

  // Fetch orders for a user
  Future<List<models.Order>> fetchOrdersForUser(String userId) async {
    final snapshot = await _db
        .collection(ordersColl)
        .where('customerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((d) => models.Order.fromDoc(d)).toList();
  }

  // Update order status (used by retailer backend or cloud function)
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await _db.collection(ordersColl).doc(orderId).update({
      'status': newStatus,
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    });
  }
}

