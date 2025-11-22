import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_mart/models/product.dart';

class ProductService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<Product?> getProductById(String productId) async {
    try {
      final doc = await _db.collection('products').doc(productId).get();
      if (doc.exists) {
        return Product.fromFirestore(doc.data()!, doc.id);
      }
    } catch (e) {
      print('Error fetching product by ID: $e');
    }
    return null;
  }
}