import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_mart/modules/customer_order/models/order_model.dart' as local_mart_order;


class RetailerOrderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<local_mart_order.Order>> getRetailerOrders(String retailerId) {
    return _db
        .collectionGroup('orders') // Assuming orders are subcollections under users
        .where('items', arrayContains: {'sellerId': retailerId})
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => local_mart_order.Order.fromDoc(doc)).toList());
  }

  // TODO: Add methods for tracking customer purchase history details for a retailer
}