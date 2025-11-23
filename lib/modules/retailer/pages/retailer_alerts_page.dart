import 'package:flutter/material.dart';
import 'package:local_mart/data/dummy_data.dart';
import 'package:local_mart/widgets/alert_card.dart';

class RetailerAlertsPage extends StatelessWidget {
  static const String routeName = '/retailer-alerts';

  const RetailerAlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: dummyAlerts.length,
        itemBuilder: (context, index) {
          final alert = dummyAlerts[index];
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