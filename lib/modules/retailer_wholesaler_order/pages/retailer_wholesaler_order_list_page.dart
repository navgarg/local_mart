import 'package:flutter/material.dart';
import 'package:local_mart/data/dummy_data.dart';
import 'package:local_mart/widgets/order_card.dart';


class RetailerWholesalerOrderListPage extends StatelessWidget {
  const RetailerWholesalerOrderListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = dummyRetailerWholesalerOrders;
    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return OrderCard(
          order: order,
          showRetailerInfo: false,
        );
      },
    );
  }
}