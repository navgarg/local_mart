import 'package:flutter/material.dart';
import 'package:local_mart/services/alert_service.dart';
import 'package:local_mart/widgets/alert_card.dart';

class WholesalerAlertsPage extends StatelessWidget {
  static const String routeName = '/wholesaler-alerts';
  final String sellerId;

  const WholesalerAlertsPage({super.key, required this.sellerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: AlertService().getAlertsForUser(sellerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No alerts found.'));
          }

          final alerts = snapshot.data!;

          return ListView.builder(
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final alert = alerts[index];
              return AlertCard(
                alert: alert,
                onMarkAsRead: () {
                  AlertService().markAlertAsRead(alert.id);
                },
                onDelete: () {
                  AlertService().deleteAlert(alert.id);
                },
              );
            },
          );
        },
      ),
    );
  }
}