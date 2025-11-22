import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_mart/models/wholesaler_product.dart';
import 'package:local_mart/services/category_service.dart';
import 'package:rxdart/rxdart.dart'; // For switchMap

class WholesalerProductService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Add a new wholesaler product
  Future<void> addWholesalerProduct(WholesalerProduct wholesalerProduct, String category) async {
    await _db
        .collection('wholesalerProducts')
        .doc('Categories')
        .collection(category)
        .add(wholesalerProduct.toFirestore());
  }

  // Get a wholesaler product by ID (requires category)
  Stream<WholesalerProduct> getWholesalerProduct(String wholesalerProductId, String category) {
    return _db
        .collection('wholesalerProducts')
        .doc('Categories')
        .collection(category)
        .doc(wholesalerProductId)
        .snapshots()
        .map((snapshot) => WholesalerProduct.fromFirestore(snapshot, snapshot.data()?['category'] ?? 'Unknown'));
  }

  // Get a wholesaler product by ID across all categories
  Stream<WholesalerProduct?> getWholesalerProductById(String wholesalerProductId) {
    final CategoryService categoryService = CategoryService();
    return categoryService.getCategories().switchMap((categories) {
      if (categories.isEmpty) {
        return Stream.value(null);
      }
      final List<Stream<WholesalerProduct?>> streams = categories.map((category) {
        return _db
            .collection('wholesalerProducts')
            .doc('Categories')
            .collection(category)
            .doc(wholesalerProductId)
            .snapshots()
            .map((snapshot) {
              if (snapshot.exists) {
                return WholesalerProduct.fromFirestore(snapshot, snapshot.data()?['category'] ?? 'Unknown');
              }
              return null;
            });
      }).toList();
      return Rx.combineLatestList<WholesalerProduct?>(streams).map((products) => products.firstWhere((product) => product != null, orElse: () => null));
    });
  }

  // Get all wholesaler products for a specific wholesaler
  Stream<List<WholesalerProduct>> getWholesalerProducts(String sellerId, String category) {
    return _db
        .collection('wholesalerProducts')
        .doc('Categories')
        .collection(category)
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WholesalerProduct.fromFirestore(doc, doc.data()['category'] ?? 'Unknown'))
            .toList());
  }

  // Get all wholesaler products for a specific wholesaler across all categories
  Stream<List<WholesalerProduct>> getAllWholesalerProducts(String sellerId) {
    final CategoryService categoryService = CategoryService();
    return categoryService.getCategories().switchMap((categories) {
      if (categories.isEmpty) {
        return Stream.value([]);
      }
      final List<Stream<List<WholesalerProduct>>> streams = categories.map((category) {
        return _db
            .collection('wholesalerProducts')
            .doc('Categories')
            .collection(category)
            .where('sellerId', isEqualTo: sellerId)
            .snapshots()
            .map((snapshot) => snapshot.docs
                .map((doc) => WholesalerProduct.fromFirestore(doc, doc.data()['category'] ?? 'Unknown'))
                .toList());
      }).toList();
      return Rx.combineLatestList<List<WholesalerProduct>>(streams).map((lists) => lists.expand((list) => list).toList());
    });
  }

  // Update an existing wholesaler product
  Future<void> updateWholesalerProduct(WholesalerProduct wholesalerProduct, String category) async {
    await _db
        .collection('wholesalerProducts')
        .doc('Categories')
        .collection(category)
        .doc(wholesalerProduct.id)
        .update(wholesalerProduct.toFirestore());
  }

  // Delete a wholesaler product
  Future<void> deleteWholesalerProduct(String? wholesalerProductId, String category) async {
    if (wholesalerProductId == null) {
      throw ArgumentError('Product ID cannot be null for deletion.');
    }
    await _db
        .collection('wholesalerProducts')
        .doc('Categories')
        .collection(category)
        .doc(wholesalerProductId)
        .delete();
  }
}