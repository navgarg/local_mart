import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_mart/modules/wholesaler/models/wholesaler_retailer_history_model.dart';

class WholesalerRetailerHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add a new retailer purchase history entry
  Future<void> addRetailerPurchaseHistory(RetailerPurchaseHistory history) async {
    await _firestore.collection('retailerPurchaseHistory').doc(history.id).set(history.toJson());
  }

  // Get a retailer's purchase history by retailerId
  Stream<RetailerPurchaseHistory?> getRetailerPurchaseHistory(String retailerId) {
    return _firestore
        .collection('retailerPurchaseHistory')
        .where('retailerId', isEqualTo: retailerId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return RetailerPurchaseHistory.fromJson(snapshot.docs.first.data());
      }
      return null;
    });
  }

  // Update an existing retailer purchase history entry
  Future<void> updateRetailerPurchaseHistory(RetailerPurchaseHistory history) async {
    await _firestore.collection('retailerPurchaseHistory').doc(history.id).update(history.toJson());
  }

  // Add a new transaction to a retailer's purchase history
  Future<void> addTransactionToHistory(String historyId, RetailerTransaction transaction) async {
    await _firestore.collection('retailerPurchaseHistory').doc(historyId).update({
      'transactions': FieldValue.arrayUnion([transaction.toJson()])
    });
  }

  // Update a specific transaction within a retailer's purchase history
  Future<void> updateTransactionInHistory(String historyId, RetailerTransaction updatedTransaction) async {
    final historyRef = _firestore.collection('retailerPurchaseHistory').doc(historyId);
    final doc = await historyRef.get();
    if (doc.exists) {
      final history = RetailerPurchaseHistory.fromJson(doc.data()!);
      final updatedTransactions = history.transactions.map((transaction) {
        return transaction.id == updatedTransaction.id ? updatedTransaction : transaction;
      }).toList();
      await historyRef.update({
        'transactions': updatedTransactions.map((t) => t.toJson()).toList(),
      });
    }
  }

  // Delete a specific transaction from a retailer's purchase history
  Future<void> deleteTransactionFromHistory(String historyId, String transactionId) async {
    final historyRef = _firestore.collection('retailerPurchaseHistory').doc(historyId);
    final doc = await historyRef.get();
    if (doc.exists) {
      final history = RetailerPurchaseHistory.fromJson(doc.data()!);
      final updatedTransactions = history.transactions.where((transaction) => transaction.id != transactionId).toList();
      await historyRef.update({
        'transactions': updatedTransactions.map((t) => t.toJson()).toList(),
      });
    }
  }
}