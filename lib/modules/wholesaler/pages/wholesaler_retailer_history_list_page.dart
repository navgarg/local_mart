import 'package:local_mart/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_mart/modules/wholesaler/services/wholesaler_retailer_history_service.dart';
import 'package:local_mart/modules/wholesaler/models/wholesaler_retailer_history_model.dart';

class WholesalerRetailerHistoryListPage extends StatelessWidget {
  final String? retailerId;

  const WholesalerRetailerHistoryListPage({super.key, this.retailerId});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final wholesalerRetailerHistoryService = Provider.of<WholesalerRetailerHistoryService>(context);

    // Use the retailerId from the constructor if provided, otherwise try to get it from UserProvider
    final String? actualRetailerId = retailerId ?? userProvider.retailerId;

    if (actualRetailerId == null) {
      return Scaffold(
                appBar: AppBar(
          title: Text('Retailer Purchase History'),
        ),
        body: Center(child: Text('Retailer ID not available.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Retailer Purchase History'),
      ),
      body: StreamBuilder<RetailerPurchaseHistory?>(
        stream: wholesalerRetailerHistoryService.getRetailerPurchaseHistory(actualRetailerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data == null || (snapshot.data!.transactions.isEmpty)) {
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
                      )),
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