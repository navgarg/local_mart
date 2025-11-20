import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_mart/modules/wholesaler/services/wholesaler_retailer_history_service.dart';
import 'package:local_mart/modules/wholesaler/models/wholesaler_retailer_history_model.dart';

class WholesalerRetailerHistoryListPage extends StatelessWidget {
  const WholesalerRetailerHistoryListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final wholesalerRetailerHistoryService = Provider.of<WholesalerRetailerHistoryService>(context);

    // For demonstration, let's assume we have a wholesaler ID and a retailer ID
    // In a real application, these would come from authentication or navigation arguments
    const String currentWholesalerId = 'wholesaler123'; // Replace with actual wholesaler ID
    const String targetRetailerId = 'retailer456'; // Replace with actual retailer ID

    return Scaffold(
      appBar: AppBar(
        title: const Text('Retailer Purchase History'),
      ),
      body: StreamBuilder<RetailerPurchaseHistory?>(
        stream: wholesalerRetailerHistoryService.getRetailerPurchaseHistory(targetRetailerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data == null || snapshot.data!.transactions.isEmpty) {
            return const Center(child: Text('No purchase history found for this retailer.'));
          }

          final history = snapshot.data!;
          return ListView.builder(
            itemCount: history.transactions.length,
            itemBuilder: (context, index) {
              final transaction = history.transactions[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Transaction ID: ${transaction.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('Order ID: ${transaction.orderId}'),
                      Text('Total Amount: \$${transaction.totalAmount.toStringAsFixed(2)}'),
                      Text('Date: ${transaction.transactionDate.toDate().toLocal().toString().split(' ')[0]}'),
                      Text('Status: ${transaction.status}'),
                      const SizedBox(height: 10),
                      const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ...transaction.items.map((item) => Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text('- ${item.name} (x${item.quantity}) @ \$${item.price.toStringAsFixed(2)}'),
                      )).toList(),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}