import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:local_mart/modules/retailer_wholesaler_order/services/retailer_wholesaler_order_service.dart';
import 'package:local_mart/widgets/order_card.dart';

class RetailerOrdersPage extends StatelessWidget {
  static const String routeName = '/retailer-orders';

  const RetailerOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final String? retailerId = FirebaseAuth.instance.currentUser?.uid;

    if (retailerId == null) {
      return const Scaffold(
        backgroundColor: Colors.white, // Added for debugging
        body: Center(child: Text('Please log in to view your orders.')),
      );
    }

    return Scaffold(
      body: StreamBuilder(
        stream: RetailerWholesalerOrderService().getRetailerOrders(retailerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            debugPrint('RetailerOrdersPage: ConnectionState.waiting');
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            debugPrint('RetailerOrdersPage: Error: ${snapshot.error}');
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            debugPrint('RetailerOrdersPage: No data or empty data. hasData: ${snapshot.hasData}, isEmpty: ${snapshot.data?.isEmpty}');
            return const Center(child: Text('No orders found.'));
          }

          final orders = snapshot.data!;
          debugPrint('RetailerOrdersPage: Orders received: ${orders.length}');
          if (orders.isNotEmpty) {
            debugPrint('RetailerOrdersPage: First order ID: ${orders.first.id}');
            debugPrint('RetailerOrdersPage: First order status: ${orders.first.status}');
          }

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return OrderCard(
                order: order,
                showWholesalerInfo: true, // Retailer sees which wholesaler they ordered from
              );
            },
          );
        },
      ),
    );
  }
}