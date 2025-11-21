import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:local_mart/modules/retailer_wholesaler_order/services/retailer_wholesaler_order_service.dart';
import 'package:local_mart/widgets/order_card.dart';

class WholesalerOrdersPage extends StatelessWidget {
  static const String routeName = '/wholesaler-orders';

  const WholesalerOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final String? wholesalerId = FirebaseAuth.instance.currentUser?.uid;

    if (wholesalerId == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view customer orders.')),
      );
    }

    return Scaffold(
      body: StreamBuilder(
        stream: RetailerWholesalerOrderService().getWholesalerOrders(wholesalerId),
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
              return OrderCard(
                order: order,
                showRetailerInfo: true, // Wholesaler sees which retailer placed the order
              );
            },
          );
        },
      ),
    );
  }
}