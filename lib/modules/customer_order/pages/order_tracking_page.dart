import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../models/order_model.dart';

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
    if (args is String) {
      orderId = args;
    } else {
      orderId = '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    if (orderId.isEmpty) {
      return Scaffold(body: Center(child: Text('No order selected')));
    }

    return StreamBuilder<Order>(
      stream: orderProvider.watchOrder(orderId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!snap.hasData) {
          return Scaffold(body: Center(child: Text('Order not found')));
        }
        final order = snap.data!;

        final stages = [
          'placed',
          'packed',
          'shipped',
          'out_for_delivery',
          'delivered'
        ];

        final currentIndex = stages.indexOf(order.status);

        return Scaffold(
          appBar: AppBar(title: const Text('Order Tracking')),
          body: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Text('Order ID: ${order.id}', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: stages.length,
                    itemBuilder: (context, idx) {
                      final completed = idx <= currentIndex;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: completed ? Colors.green : Colors.grey[300],
                          child: Icon(completed ? Icons.check : Icons.circle, color: Colors.white),
                        ),
                        title: Text(stages[idx]),
                        subtitle: Text(
                          idx == currentIndex ? 'Current' : (completed ? 'Completed' : 'Pending'),
                        ),
                      );
                    },
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('Delivery Details'),
                    subtitle: Text(order.perRetailerDelivery.entries.map((e) => '${e.key}: ${e.value}').join('\n')),
                  ),
                ),
                const SizedBox(height: 12),
                if (order.status == 'placed')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        // Cancellation allowed only before shipped
                        // Update status to cancelled
                        try {
                          await orderProvider
                              ._service // not ideal to access private; you can expose a method
                              .updateOrderStatus(order.id, 'cancelled');
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order cancelled')));
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cancel failed: $e')));
                        }
                      },
                      child: const Text('Cancel Order'),
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
