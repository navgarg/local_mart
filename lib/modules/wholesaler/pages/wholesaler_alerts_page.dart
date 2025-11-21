import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:local_mart/services/alert_service.dart';
import 'package:local_mart/widgets/alert_card.dart';

class WholesalerAlertsPage extends StatelessWidget {
  static const String routeName = '/wholesaler-alerts';

  const WholesalerAlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view your alerts.')),
      );
    }

    return Scaffold(
      body: StreamBuilder(
        stream: AlertService().getAlertsForUser(userId),
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