import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_mart/models/alert.dart';

class AlertService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Alert>> getAlertsForUser(String userId) {
    return _firestore
        .collection('alerts')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Alert.fromFirestore(doc)).toList());
  }

  Future<void> markAlertAsRead(String alertId) async {
    await _firestore.collection('alerts').doc(alertId).update({'isRead': true});
  }

  Future<void> deleteAlert(String alertId) async {
    await _firestore.collection('alerts').doc(alertId).delete();
  }

  Future<void> addAlert(Alert alert) async {
    await _firestore.collection('alerts').add(alert.toFirestore());
  }
}