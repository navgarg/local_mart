import 'package:flutter/material.dart';
import 'package:local_mart/data/dummy_data.dart';
import 'package:local_mart/widgets/order_card.dart';

class WholesalerOrderHistoryPage extends StatelessWidget {
  const WholesalerOrderHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: dummyRetailerWholesalerOrders.length,
      itemBuilder: (context, index) {
        final order = dummyRetailerWholesalerOrders[index];
        return OrderCard(
          order: order,
          showRetailerInfo: true,
        );
      },
    );
  }
}