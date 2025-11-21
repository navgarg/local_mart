import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:local_mart/modules/retailer_wholesaler_order/models/retailer_wholesaler_order_model.dart';
import 'package:local_mart/modules/retailer_wholesaler_order/services/retailer_wholesaler_order_service.dart';
import 'package:local_mart/modules/retailer_wholesaler_order/pages/retailer_wholesaler_order_form_page.dart';
import 'package:provider/provider.dart';

class RetailerWholesalerOrderListPage extends StatefulWidget {
  const RetailerWholesalerOrderListPage({super.key});

  @override
  State<RetailerWholesalerOrderListPage> createState() =>
      _RetailerWholesalerOrderListPageState();
}

class _RetailerWholesalerOrderListPageState
    extends State<RetailerWholesalerOrderListPage> {
  String? _retailerId;

  @override
  void initState() {
    super.initState();
    _retailerId = FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  Widget build(BuildContext context) {
    if (_retailerId == null) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: true,
          title: const Text('My Wholesaler Orders')),
        body: const Center(child: Text('Please log in as a retailer.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text('My Wholesaler Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const RetailerWholesalerOrderFormPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<RetailerWholesalerOrder>>(
        stream: Provider.of<RetailerWholesalerOrderService>(context)
            .getRetailerOrders(_retailerId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No orders found.'));
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
                  subtitle: Text('Wholesaler: ${order.wholesalerId}'), // TODO: Display wholesaler name
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'Total Amount: ₹${order.totalAmount.toStringAsFixed(2)}'),
                          Text('Status: ${order.status}'),
                          Text(
                              'Placed At: ${order.placedAt.toLocal().toString().split(' ')[0]}'),
                          if (order.expectedDeliveryDate != null)
                            Text(
                                'Expected Delivery: ${order.expectedDeliveryDate!.toLocal().toString().split(' ')[0]}'),
                          const SizedBox(height: 10),
                          const Text('Items:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          ...order.items.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                              child: Text(
                                  '${item.name} x ${item.quantity} (₹${item.price.toStringAsFixed(2)})'),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            RetailerWholesalerOrderFormPage(
                                          order: order,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () async {
                                    await Provider.of<
                                            RetailerWholesalerOrderService>(
                                        context,
                                        listen: false)
                                        .deleteRetailerWholesalerOrder(
                                            order.id);
                                  },
                                ),
                              ],
                            ),
                          ),
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