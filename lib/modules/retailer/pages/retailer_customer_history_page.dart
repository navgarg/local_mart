import 'package:flutter/material.dart';

import 'package:local_mart/data/dummy_data.dart';

class RetailerCustomerHistoryPage extends StatelessWidget {
  const RetailerCustomerHistoryPage({super.key});


  @override
  Widget build(BuildContext context) {


    return Scaffold(
      appBar: AppBar(
    automaticallyImplyLeading: true,
    title: const Text('Customer Purchase History'),
  ),
      body: ListView.builder(
        itemCount: dummyOrders.length,
        itemBuilder: (context, index) {
          final order = dummyOrders[index];
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
                      Text('Placed At: ${order.orderDate.toLocal().toString().split(' ')[0]}'),
                      const SizedBox(height: 10),
                      const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ...order.items.map((item) => Padding(
                        padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                        child: Text('${item.productName} x ${item.quantity} (₹${item.price.toStringAsFixed(2)})'),
                      )),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}