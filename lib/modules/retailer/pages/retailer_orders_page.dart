import 'package:flutter/material.dart';

import 'package:local_mart/data/dummy_data.dart';
import 'package:local_mart/widgets/order_card.dart';

class RetailerOrdersPage extends StatelessWidget {
  static const String routeName = '/retailer-orders';

  const RetailerOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {


    return Scaffold(
      body: ListView.builder(
        itemCount: dummyRetailerWholesalerOrders.length,
        itemBuilder: (context, index) {
          final order = dummyRetailerWholesalerOrders[index];
          return OrderCard(
            order: order,
            showWholesalerInfo: true, // Retailer sees which wholesaler they ordered from
          );
        },
      ),
    );
  }
}