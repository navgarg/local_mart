import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_mart/models/retailer_product.dart';


class RetailerProductService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Add a new retailer product
  Future<void> addRetailerProduct(RetailerProduct retailerProduct) async {
    await _db
        .collection('products')
        .doc(retailerProduct.id)
        .set(retailerProduct.toFirestore());
  }

  // Get a retailer product by ID
  Stream<RetailerProduct> getRetailerProduct(String productId) {
    return _db
        .collection('products')
        .doc(productId)
        .snapshots()
        .map((snapshot) => RetailerProduct.fromFirestore(snapshot));
  }

  // Get all retailer products for a specific retailer
  Stream<List<RetailerProduct>> getRetailerProducts(String retailerId) {
    return _db
        .collection('products')
        .where('retailerId', isEqualTo: retailerId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RetailerProduct.fromFirestore(doc))
            .toList());
  }

  // Update an existing retailer product
  Future<void> updateRetailerProduct(RetailerProduct retailerProduct) async {
    await _db
        .collection('products')
        .doc(retailerProduct.id)
        .update(retailerProduct.toFirestore());
  }

  // Delete a retailer product
  Future<void> deleteRetailerProduct(String productId) async {
    await _db
        .collection('products')
        .doc(productId)
        .delete();
  }
}