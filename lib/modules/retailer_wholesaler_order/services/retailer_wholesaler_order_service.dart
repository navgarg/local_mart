import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_mart/modules/retailer_wholesaler_order/models/retailer_wholesaler_order_model.dart';

class RetailerWholesalerOrderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Place a new order from retailer to wholesaler
  Future<void> placeRetailerWholesalerOrder(RetailerWholesalerOrder order) async {
    await _db.collection('retailerWholesalerOrders').doc(order.id).set(order.toJson());
  }

  // Get all orders placed by a specific retailer
  Stream<List<RetailerWholesalerOrder>> getRetailerOrders(String retailerId) {
    return _db
        .collection('retailerWholesalerOrders')
        .where('retailerId', isEqualTo: retailerId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => RetailerWholesalerOrder.fromDoc(doc)).toList());
  }

  // Get all orders received by a specific wholesaler
  Stream<List<RetailerWholesalerOrder>> getWholesalerOrders(String wholesalerId) {
    return _db
        .collection('retailerWholesalerOrders')
        .where('wholesalerId', isEqualTo: wholesalerId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => RetailerWholesalerOrder.fromDoc(doc)).toList());
  }

  // Update an existing order
  Future<void> updateRetailerWholesalerOrder(RetailerWholesalerOrder order) async {
    await _db.collection('retailerWholesalerOrders').doc(order.id).update(order.toJson());
  }

  // Delete an order (might not be needed, but good for completeness)
  Future<void> deleteRetailerWholesalerOrder(String orderId) async {
    await _db.collection('retailerWholesalerOrders').doc(orderId).delete();
  }
}