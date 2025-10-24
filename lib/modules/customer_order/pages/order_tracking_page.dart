import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../models/order_model.dart' as models;

class OrderTrackingPage extends StatefulWidget {
  const OrderTrackingPage({super.key});

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  late String orderId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments;
    orderId = args is String ? args : '';
  }

  /// 🔹 Handles order cancellation safely with context checks
  Future<void> _handleCancelOrder(BuildContext context, String orderId) async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    try {
      await orderProvider.cancelOrder(orderId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order cancelled successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel order: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final theme = Theme.of(context);

    if (orderId.isEmpty) {
      return Scaffold(
        body: Center(
          child: Text('No order selected', style: theme.textTheme.bodyMedium),
        ),
      );
    }

    return StreamBuilder<models.Order>(
      stream: orderProvider.watchOrder(orderId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snap.hasData) {
          return Scaffold(
            body: Center(
              child: Text('Order not found', style: theme.textTheme.bodyMedium),
            ),
          );
        }

        final order = snap.data!;
        final stages = [
          'placed',
          'packed',
          'shipped',
          'out_for_delivery',
          'delivered',
        ];

        final currentIndex = stages.indexOf(order.status);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Order Tracking'),
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Text('Order ID: ${order.id}', style: theme.textTheme.bodyMedium),
                const SizedBox(height: 12),

                // Progress tracker
                Expanded(
                  child: ListView.builder(
                    itemCount: stages.length,
                    itemBuilder: (context, idx) {
                      final completed = idx <= currentIndex;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                          completed ? theme.colorScheme.primary : Colors.grey[300],
                          child: Icon(
                            completed ? Icons.check : Icons.circle,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          stages[idx].replaceAll('_', ' ').toUpperCase(),
                          style: theme.textTheme.bodyLarge,
                        ),
                        subtitle: Text(
                          idx == currentIndex
                              ? 'Current stage'
                              : (completed ? 'Completed' : 'Pending'),
                          style: theme.textTheme.bodySmall,
                        ),
                      );
                    },
                  ),
                ),

                // Delivery details card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    title: const Text('Delivery Details'),
                    subtitle: Text(
                      order.perRetailerDelivery.entries
                          .map((e) => '${e.key}: ${e.value}')
                          .join('\n'),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Cancel button
                if (order.status == 'placed' ||
                    order.status == 'packed' ||
                    order.status == 'shipped')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Cancel Order'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                        foregroundColor: theme.colorScheme.onError,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => _handleCancelOrder(context, order.id),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
