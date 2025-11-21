import 'package:flutter/material.dart';
import 'package:local_mart/models/alert.dart';
import 'package:intl/intl.dart';

class AlertCard extends StatelessWidget {
  final Alert alert;
  final VoidCallback? onMarkAsRead;
  final VoidCallback? onDelete;

  const AlertCard({
    super.key,
    required this.alert,
    this.onMarkAsRead,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedDate = DateFormat('MMM d, yyyy - hh:mm a').format(alert.timestamp.toDate());

    IconData icon;
    Color iconColor;
    switch (alert.type) {
      case 'order_update':
        icon = Icons.shopping_cart_outlined;
        iconColor = Colors.blue;
        break;
      case 'promotion':
        icon = Icons.local_offer_outlined;
        iconColor = Colors.green;
        break;
      case 'system':
        icon = Icons.info_outline;
        iconColor = Colors.orange;
        break;
      default:
        icon = Icons.notifications_none;
        iconColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: alert.isRead ? Colors.grey[200] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    alert.message,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: alert.isRead ? FontWeight.normal : FontWeight.bold,
                      color: alert.isRead ? Colors.grey[700] : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              formattedDate,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
            if (!alert.isRead || onDelete != null) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!alert.isRead)
                    TextButton(
                      onPressed: onMarkAsRead,
                      child: const Text('Mark as Read'),
                    ),
                  if (onDelete != null)
                    TextButton(
                      onPressed: onDelete,
                      child: const Text('Delete'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}