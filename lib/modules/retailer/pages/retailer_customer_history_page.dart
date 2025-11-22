import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:local_mart/modules/retailer/services/retailer_order_service.dart';
import 'package:local_mart/modules/customer_order/models/order_model.dart' as local_mart_order;

class RetailerCustomerHistoryPage extends StatelessWidget {
  final String retailerId;
  const RetailerCustomerHistoryPage({super.key, required this.retailerId});


  @override
  Widget build(BuildContext context) {


    return Scaffold(
      appBar: AppBar(
    automaticallyImplyLeading: true,
    title: const Text('Customer Purchase History'),
  ),
      body: StreamBuilder<List<local_mart_order.Order>>(
        stream: Provider.of<RetailerOrderService>(context)
            .getRetailerOrders(retailerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No customer orders found.'));
          }

          final orders = snapshot.data!;
          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ExpansionTile(
                  title: Text('Order ID: ${order.id}'),
                  subtitle: Text('Customer: ${order.customerName}'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Amount: ₹${order.totalAmount.toStringAsFixed(2)}'),
                          Text('Status: ${order.status}'),
                          Text('Placed At: ${order.placedAt.toLocal().toString().split(' ')[0]}'),
                          const SizedBox(height: 10),
                          const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                          ...order.items.map((item) => Padding(
                            padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                            child: Text('${item.name} x ${item.quantity} (₹${item.price.toStringAsFixed(2)})'),
                          )),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}