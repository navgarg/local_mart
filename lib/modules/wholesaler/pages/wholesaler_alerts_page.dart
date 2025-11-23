import 'package:flutter/material.dart';
import 'package:local_mart/data/dummy_data.dart';
import 'package:local_mart/widgets/alert_card.dart';

class WholesalerAlertsPage extends StatelessWidget {
  static const String routeName = '/wholesaler-alerts';

  const WholesalerAlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: dummyWholesalerAlerts.length,
        itemBuilder: (context, index) {
          final alert = dummyWholesalerAlerts[index];
          return AlertCard(
            alert: alert,
            onMarkAsRead: () {
              // No action for dummy data
            },
            onDelete: () {
              // No action for dummy data
            },
          );
        },
      ),
    );
  }
}
