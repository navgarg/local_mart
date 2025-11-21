import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:local_mart/modules/wholesaler/pages/wholesaler_inventory_page.dart';
import 'package:local_mart/modules/wholesaler/pages/wholesaler_retailer_history_list_page.dart';
import 'package:local_mart/modules/retailer_wholesaler_order/pages/retailer_wholesaler_order_list_page.dart';

class WholesalerHomePage extends StatefulWidget {
  const WholesalerHomePage({super.key});

  @override
  State<WholesalerHomePage> createState() => _WholesalerHomePageState();
}

class _WholesalerHomePageState extends State<WholesalerHomePage> {
  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wholesaler Dashboard'),
        automaticallyImplyLeading: false, // Wholesaler dashboard is a top-level page
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, Wholesaler!',
              style: Theme.of(context).textTheme.headlineMedium,
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
                    // TODO: Implement logic to fetch and display new retailer orders
                    const Text('No new orders at the moment.'),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/wholesaler-orders'); // Assuming a route for all wholesaler orders
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
                    // TODO: Implement logic to fetch and display inventory summary
                    const Text('Current stock: 1234 items'),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/wholesaler-inventory');
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
                    Navigator.pushNamed(context, '/wholesaler-orders');
                  },
                  avatar: const Icon(Icons.receipt_long),
                ),
                ActionChip(
                  label: const Text('View Retailer History'),
                  onPressed: () {
                    Navigator.pushNamed(context, '/wholesaler-retailer-history');
                  },
                  avatar: const Icon(Icons.people),
                ),
                // Add more quick links as needed
              ],
            ),
          ],
        ),
      ),
    );
  }
}