import 'package:flutter/material.dart';
import 'package:local_mart/data/dummy_data.dart';
import 'package:local_mart/widgets/order_card.dart';

class WholesalerOrdersPage extends StatelessWidget {
  static const String routeName = '/wholesaler-orders';


  const WholesalerOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: dummyRetailerWholesalerOrders.length,
        itemBuilder: (context, index) {
          final order = dummyRetailerWholesalerOrders[index];
          return OrderCard(
            order: order,
            showRetailerInfo: true, // Wholesaler sees which retailer placed the order
          );
        },
      ),
    );
  }
}