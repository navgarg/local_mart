import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_mart/models/retailer_product.dart';
import 'package:local_mart/services/category_service.dart';
import 'package:rxdart/rxdart.dart'; // For switchMap

class RetailerProductService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Add a new retailer product
  Future<void> addRetailerProduct(RetailerProduct retailerProduct) async {
    await _db
        .collection('retailerProducts')
        .doc('Categories')
        .collection(retailerProduct.category)
        .add(retailerProduct.toFirestore());
  }

  // Get a retailer product by ID
  Stream<RetailerProduct> getRetailerProduct(String retailerProductId, String category) {
    return _db
        .collection('retailerProducts')
        .doc('Categories')
        .collection(category)
        .doc(retailerProductId)
        .snapshots()
        .map((snapshot) => RetailerProduct.fromFirestore(snapshot));
  }

  // Get all retailer products for a specific retailer across all categories
  Stream<List<RetailerProduct>> getRetailerProducts(String retailerId) {
    final CategoryService categoryService = CategoryService();
    return categoryService.getCategories().switchMap((categories) {
      if (categories.isEmpty) {
        return Stream.value([]);
      }
      final List<Stream<List<RetailerProduct>>> streams = categories.map((category) {
        return _db
            .collection('retailerProducts')
            .doc('Categories')
            .collection(category)
            .where('retailerId', isEqualTo: retailerId)
            .snapshots()
            .map((snapshot) => snapshot.docs
                .map((doc) => RetailerProduct.fromFirestore(doc))
                .toList());
      }).toList();
      return Rx.combineLatestList<List<RetailerProduct>>(streams).map((lists) => lists.expand((list) => list).toList());
    });
  }

  // Update an existing retailer product
  Future<void> updateRetailerProduct(RetailerProduct retailerProduct, String category) async {
    await _db
        .collection('retailerProducts')
        .doc('Categories')
        .collection(category)
        .doc(retailerProduct.id)
        .update(retailerProduct.toFirestore());
  }

  // Delete a retailer product
  Future<void> deleteRetailerProduct(String retailerProductId, String category) async {
    await _db
        .collection('retailerProducts')
        .doc('Categories')
        .collection(category)
        .doc(retailerProductId)
        .delete();
  }
}