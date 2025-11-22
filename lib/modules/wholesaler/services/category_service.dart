import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<String>> getCategories() {
    return _firestore.collection('products').doc('Categories').snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists || snapshot.data() == null) {
        return [];
      }
      final data = snapshot.data()!;
      final categoriesList = data['categoriesList'] as List<dynamic>?;
      if (categoriesList == null) {
        return [];
      }
      return categoriesList.map((e) => e.toString()).toList();
    });
  }
}
