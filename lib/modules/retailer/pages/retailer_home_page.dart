import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:local_mart/modules/customer_order/providers/order_provider.dart';
import 'package:local_mart/modules/customer_order/models/order_model.dart';


import 'package:local_mart/modules/retailer/pages/retailer_inventory_page.dart';




class RetailerHomePage extends StatelessWidget {
  final String userId;
  const RetailerHomePage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return RetailerDashboardContent(retailerId: userId);
  }
}

class RetailerDashboardContent extends StatelessWidget {
  final String retailerId;
  const RetailerDashboardContent({super.key, required this.retailerId});

  @override
  Widget build(BuildContext context) {
    final userId = retailerId;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, Retailer!',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),

          // Section for New Customer Orders
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'New Customer Orders',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<List<Order>>(
                    stream: Provider.of<OrderProvider>(context)
                        .getSellerOrders(userId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('No new orders at the moment.'));
                      }

                      final newOrders = snapshot.data!
                          .where((order) => order.status == 'order_placed')
                          .toList();

                      if (newOrders.isEmpty) {
                        return const Center(child: Text('No new orders at the moment.'));
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: newOrders.length,
                        itemBuilder: (context, index) {
                          final order = newOrders[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            child: ListTile(
                              title: Text('Order ID: ${order.id.substring(0, 8)}'),
                              subtitle: Text('Customer: ${order.customerName} - Total: ₹${order.totalAmount.toStringAsFixed(2)}'),
                              trailing: Text(order.status),
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/order-details',
                                  arguments: order,
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/retailer-orders'); // Assuming a route for all retailer orders
                      },
                      child: const Text('View All Customer Orders'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Section for Pending Wholesaler Orders
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pending Wholesaler Orders',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<List<Order>>(
                    stream: Provider.of<OrderProvider>(context)
                        .getRetailerWholesalerOrders(userId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('No pending wholesaler orders.'));
                      }

                      final pendingOrders = snapshot.data!
                          .where((order) =>
                              order.status != 'delivered' &&
                              order.status != 'cancelled' &&
                              order.status != 'pickup_cancelled')
                          .toList();

                      if (pendingOrders.isEmpty) {
                        return const Center(child: Text('No pending wholesaler orders.'));
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: pendingOrders.length,
                        itemBuilder: (context, index) {
                          final order = pendingOrders[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            child: ListTile(
                              title: Text('Order ID: ${order.id.substring(0, 8)}'),
                              subtitle: Text('Wholesaler: ${order.customerName} - Total: ₹${order.totalAmount.toStringAsFixed(2)}'),
                              trailing: Text(order.status),
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/wholesaler-order-details',
                                  arguments: order,
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/retailer-wholesaler-orders');
                      },
                      child: const Text('View All Wholesaler Orders'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Quick Links Section
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ActionChip(
                label: const Text('Manage Inventory'),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => RetailerInventoryPage(retailerId: retailerId)));
                },
                avatar: const Icon(Icons.inventory),
              ),
              ActionChip(
                label: const Text('Place New Wholesaler Order'),
                onPressed: () {
                  Navigator.pushNamed(context, '/retailer-wholesaler-order-form', arguments: retailerId);
                },
                avatar: const Icon(Icons.add_shopping_cart),
              ),
              ActionChip(
                label: const Text('View Customer History'),
                onPressed: () {
                  Navigator.pushNamed(context, '/retailer-customer-history', arguments: retailerId);
                },
                avatar: const Icon(Icons.people),
              ),
              // Add more quick links as needed
            ],
          ),
        ],
      ),
    );
  }
}