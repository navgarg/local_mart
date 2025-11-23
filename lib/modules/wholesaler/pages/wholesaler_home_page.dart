import 'package:flutter/material.dart';

import 'package:local_mart/data/dummy_data.dart';

class WholesalerHomePage extends StatelessWidget {
  final String sellerId;
  final Function(int) onNavigate;
  const WholesalerHomePage({
    super.key,
    required this.sellerId,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return WholesalerDashboardContent(
      onNavigate: onNavigate,
      sellerId: sellerId,
    );
  }
}

class WholesalerDashboardContent extends StatelessWidget {
  final Function(int) onNavigate;
  final String sellerId;
  const WholesalerDashboardContent({
    super.key,
    required this.onNavigate,
    required this.sellerId,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, Wholesaler!',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),

          // Section for New Retailer Orders
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'New Retailer Orders',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: dummyOrders.length,
                    itemBuilder: (context, index) {
                      final order = dummyOrders[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        child: ListTile(
                          title: Text(
                            'Order ID: ${order.id.substring(0, 8)}',
                          ),
                          subtitle: Text(
                            'Retailer: ${order.retailerId} - Total: ₹${order.totalAmount.toStringAsFixed(2)}',
                          ),
                          trailing: Text(order.status),
                          onTap: () {
                            // TODO: Navigate to order details page
                          },
                        ),
                      );
                    },
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: TextButton(
                      onPressed: () {
                        onNavigate(1); // Navigate to Orders tab
                      },
                      child: const Text('View All Retailer Orders'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Section for Inventory Summary
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Inventory Summary',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Unique products: ${dummyProducts.length}'),
                      const SizedBox(height: 15),
                      Text('Total stock: ${dummyProducts.fold(0, (sum, product) => sum + 1)} items'), // Assuming each dummy product has a stock of 1 for simplicity
                    ],
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: TextButton(
                      onPressed: () {
                        onNavigate(4); // Navigate to Inventory tab
                      },
                      child: const Text('Manage Inventory'),
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
                label: const Text('Process Orders'),
                onPressed: () {
                  onNavigate(1); // Navigate to Orders tab
                },
                avatar: const Icon(Icons.receipt_long),
              ),
              ActionChip(
                label: const Text('View Retailer History'),
                onPressed: () {
                  onNavigate(1); // Navigate to Orders tab
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
