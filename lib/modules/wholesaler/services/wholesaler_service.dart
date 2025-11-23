import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_mart/models/wholesaler.dart';

class WholesalerService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<Wholesaler?> getWholesalerById(String wholesalerId) {
    return _db.collection('users').doc(wholesalerId).snapshots().map((
      snapshot,
    ) {
      print('WholesalerService: Fetching wholesaler with ID: $wholesalerId');
      final data = snapshot.data();
      if (data == null) {
        print('WholesalerService: Document for ID $wholesalerId is null.');
        return null;
      } else {
        print('WholesalerService: Document data for ID $wholesalerId: $data');
        return Wholesaler.fromFirestore(snapshot);
      }
    });
  }

  Stream<List<Wholesaler>> getWholesalers() {
    return _db.collection('users').where('role', isEqualTo: 'wholesaler').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Wholesaler.fromFirestore(doc)).toList();
    });
  }
}
