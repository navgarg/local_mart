import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:local_mart/modules/customer_order/providers/order_provider.dart';
import 'package:local_mart/modules/customer_order/models/order_model.dart';
import 'package:local_mart/models/wholesaler_product.dart';
import 'package:local_mart/models/wholesaler.dart';
import 'package:local_mart/modules/wholesaler/services/wholesaler_product_service.dart';
import 'package:local_mart/modules/wholesaler/services/wholesaler_service.dart';

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
          StreamBuilder<Wholesaler?>(
            stream: Provider.of<WholesalerService>(
              context,
            ).getWholesalerById(sellerId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }
              final wholesaler = snapshot.data;
              print('WholesalerHomePage: Wholesaler object: $wholesaler, name: ${wholesaler?.name}');
              return Text(
                'Welcome, ${wholesaler?.name ?? 'Wholesaler'}!',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              );
            },
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
                  StreamBuilder<List<Order>>(
                    stream: Provider.of<OrderProvider>(
                      context,
                    ).getSellerOrders(sellerId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text('No new orders at the moment.'),
                        );
                      }

                      final newOrders = snapshot.data!
                          .where((order) => order.status == 'order_placed')
                          .toList();

                      if (newOrders.isEmpty) {
                        return const Center(
                          child: Text('No new orders at the moment.'),
                        );
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
                              title: Text(
                                'Order ID: ${order.id.substring(0, 8)}',
                              ),
                              subtitle: Text(
                                'Retailer: ${order.customerName} - Total: ₹${order.totalAmount.toStringAsFixed(2)}',
                              ),
                              trailing: Text(order.status),
                              onTap: () {
                                // TODO: Navigate to order details page
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
                  StreamBuilder<List<WholesalerProduct>>(
                    stream: Provider.of<WholesalerProductService>(
                      context,
                    ).getAllWholesalerProducts(sellerId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text('No products in inventory.'),
                        );
                      }

                      final uniqueProducts = snapshot.data!.length;
                      final totalStock = snapshot.data!.fold(
                        0,
                        (sum, product) => sum + product.stock,
                      );

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Unique products: $uniqueProducts'),
                          const SizedBox(height: 15),
                          Text('Total stock: $totalStock items'),
                        ],
                      );
                    },
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
