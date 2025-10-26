import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_mart/theme.dart';
import '../models/order_model.dart';
import '../providers/order_provider.dart';

class OrderTrackingPage extends StatefulWidget {
  final String orderId;
  const OrderTrackingPage({super.key, required this.orderId});

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  bool _isCancelling = false; // 👈 New flag

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final provider = Provider.of<OrderProvider>(context, listen: false);
      provider.listenToOrder(widget.orderId);
    });
  }

  @override
  void dispose() {
    Provider.of<OrderProvider>(context, listen: false)
        .stopListeningToOrder(widget.orderId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.lightTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Tracking'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
      ),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, _) {
          final order = orderProvider.getOrderById(widget.orderId);

          if (order == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final bool canCancel = order.status == 'Not Yet Shipped';
          final bool cannotCancel = order.status != 'Not Yet Shipped';

          return RefreshIndicator(
            onRefresh: () async => orderProvider.refreshOrder(widget.orderId),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Info
                  Card(
                    color: AppTheme.cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppTheme.borderColor),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Order ID: ${order.id}',
                              style: theme.textTheme.titleMedium),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.local_shipping_outlined,
                                  color: AppTheme.primaryColor),
                              const SizedBox(width: 8),
                              Text(
                                order.status,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: order.status == 'Delivered'
                                      ? Colors.green
                                      : order.status == 'Cancelled'
                                      ? Colors.red
                                      : Colors.orange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Address or Pickup Info
                  if (order.receivingMethod == 'delivery')
                    Card(
                      color: AppTheme.cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppTheme.borderColor),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.location_on,
                            color: AppTheme.primaryColor),
                        title: Text(
                          '${order.deliveryAddress.line1}, ${order.deliveryAddress.city}',
                          style: theme.textTheme.bodyMedium,
                        ),
                        subtitle: Text(
                          '${order.deliveryAddress.state} - ${order.deliveryAddress.pincode}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    )
                  else
                    Card(
                      color: AppTheme.cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppTheme.borderColor),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.store,
                            color: AppTheme.primaryColor),
                        title: Text('Pickup Order',
                            style: theme.textTheme.bodyMedium),
                        subtitle: Text(
                          order.pickupDate != null
                              ? 'Pickup by: ${order.pickupDate!.toLocal().toString().split(' ')[0]}'
                              : 'Within 3 days from order date',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Items List
                  Card(
                    color: AppTheme.cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppTheme.borderColor),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Items', style: theme.textTheme.titleMedium),
                          const SizedBox(height: 8),
                          ...order.items.map(
                                (it) => Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${it.name} x ${it.quantity}',
                                    style: theme.textTheme.bodyMedium),
                                Text(
                                  '₹${(it.price * it.quantity).toStringAsFixed(2)}',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total:',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold)),
                              Text('₹${order.totalAmount.toStringAsFixed(2)}',
                                  style: theme.textTheme.titleMedium),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Progress Timeline
                  Text('Order Progress', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _StatusTimeline(status: order.status),

                  const SizedBox(height: 24),

                  // Cancel Button Section (💥 Improved)
                  if (cannotCancel)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.info_outline, color: Colors.grey),
                          SizedBox(width: 8),
                          Text(
                            'Order cannot be cancelled after shipment.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isCancelling
                            ? null
                            : () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Cancel Order?'),
                              content: const Text(
                                  'Are you sure you want to cancel this order?'),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(ctx, false),
                                    child: const Text('No')),
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(ctx, true),
                                    child: const Text('Yes')),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            setState(() => _isCancelling = true);
                            try {
                              await orderProvider.cancelOrder(order.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Order cancelled successfully')),
                              );
                              await orderProvider.refreshOrder(order.id);
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(e
                                        .toString()
                                        .replaceAll('Exception: ', ''))),
                              );
                            } finally {
                              setState(() => _isCancelling = false);
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _isCancelling
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : const Text('Cancel Order',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  final String status;
  const _StatusTimeline({required this.status});

  @override
  Widget build(BuildContext context) {
    final steps = [
      'Not Yet Shipped',
      'Shipped',
      'Out for Delivery',
      'Delivered'
    ];
    final currentIndex = steps.indexOf(status);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: steps.map((s) {
          final index = steps.indexOf(s);
          final isCompleted = index <= currentIndex;
          final isLast = index == steps.length - 1;

          return Row(
            children: [
              Column(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor:
                    isCompleted ? Colors.green : Colors.grey[300],
                    child: Icon(
                      isCompleted ? Icons.check : Icons.circle,
                      size: 12,
                      color: isCompleted ? Colors.white : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s,
                    style: TextStyle(
                      fontSize: 12,
                      color: isCompleted ? Colors.green : Colors.grey[600],
                      fontWeight:
                      isCompleted ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
              if (!isLast)
                Container(
                  width: 40,
                  height: 2,
                  color:
                  index < currentIndex ? Colors.green : Colors.grey[300],
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}



