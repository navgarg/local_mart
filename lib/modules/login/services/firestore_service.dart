import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  Future<void> saveQuestionnaire({
    required String uid,
    required String role,
    required String address,
    required String gender,
    required String ageBand,
    String? gstNumber,
    String? productType,
  }) async {
    final data = <String, dynamic>{
      'role': role,
      'address': address,
      'gender': gender,
      'ageBand': ageBand,
      // timestamps help with ordering later
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (gstNumber != null) data['gstNumber'] = gstNumber;
    if (productType != null) data['productType'] = productType;

    await _db.collection('users').doc(uid).set(data, SetOptions(merge: true));
  }
}
