import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_mart/models/wholesaler_product.dart';

class WholesalerProductService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Add a new wholesaler product
  Future<void> addWholesalerProduct(WholesalerProduct wholesalerProduct) async {
    await _db
        .collection('wholesalerProducts')
        .doc(wholesalerProduct.id)
        .set(wholesalerProduct.toFirestore());
  }

  // Get a wholesaler product by ID
  Stream<WholesalerProduct> getWholesalerProduct(String wholesalerProductId) {
    return _db
        .collection('wholesalerProducts')
        .doc(wholesalerProductId)
        .snapshots()
        .map((snapshot) => WholesalerProduct.fromFirestore(snapshot));
  }

  // Get all wholesaler products for a specific wholesaler
  Stream<List<WholesalerProduct>> getWholesalerProducts(String wholesalerId) {
    return _db
        .collection('wholesalerProducts')
        .where('wholesalerId', isEqualTo: wholesalerId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WholesalerProduct.fromFirestore(doc))
            .toList());
  }

  // Update an existing wholesaler product
  Future<void> updateWholesalerProduct(WholesalerProduct wholesalerProduct) async {
    await _db
        .collection('wholesalerProducts')
        .doc(wholesalerProduct.id)
        .update(wholesalerProduct.toFirestore());
  }

  // Delete a wholesaler product
  Future<void> deleteWholesalerProduct(String wholesalerProductId) async {
    await _db.collection('wholesalerProducts').doc(wholesalerProductId).delete();
  }
}