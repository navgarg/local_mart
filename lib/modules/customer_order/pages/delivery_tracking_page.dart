import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:local_mart/theme.dart';
import 'package:provider/provider.dart';

import '../models/order_model.dart';
import '../providers/order_provider.dart';

class DeliveryTrackingPage extends StatefulWidget {
  final String orderId;
  const DeliveryTrackingPage({super.key, required this.orderId});

  @override
  State<DeliveryTrackingPage> createState() => _DeliveryTrackingPageState();
}

class _DeliveryTrackingPageState extends State<DeliveryTrackingPage> {
  bool _isCancelling = false;
  String? _userId;
  String shortOrderCode(String id) {
    if (id.isEmpty) return "";
    final end = id.length < 6 ? id.length : 6;
    return id.substring(0, end).toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _userId = user?.uid;
    if (_userId != null) {
      Future.microtask(() {
        Provider.of<OrderProvider>(
          context,
          listen: false,
        ).listenToOrder(_userId!, widget.orderId); // ✅ Correct order
        Provider.of<OrderProvider>(
          context,
          listen: false,
        ).maybeAutoAdvanceOrderStatus(_userId!, widget.orderId);
      });
    }
  }

  @override
  void dispose() {
    Provider.of<OrderProvider>(context, listen: false).stopListeningToOrder();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.lightTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Delivery Tracking',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
      ),
      body: Consumer<OrderProvider>(
        builder: (context, provider, _) {
          final order = provider.activeOrder;
          if (order == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final label =
              {
                'order_placed': 'Order Placed',
                'shipped': 'Shipped',
                'out_for_delivery': 'Out for Delivery',
                'delivered': 'Delivered',
                'cancelled': 'Cancelled',
              }[order.status] ??
              order.status;

          final bool canCancel = order.status == "order_placed";

          return RefreshIndicator(
            onRefresh: () async {
              if (_userId != null) {
                await provider.refreshOrder(_userId!, widget.orderId);
              }
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Order Info Card ---
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
                          Text(
                            "Order #${shortOrderCode(order.id)}",
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.local_shipping_outlined,
                                color: AppTheme.primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                label,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: order.status == 'delivered'
                                      ? AppTheme.successColor
                                      : order.status == 'cancelled'
                                      ? AppTheme.errorColor
                                      : Colors.orange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          if (order.expectedDelivery != null)
                            Text(
                              "Delivery by: ${order.expectedDelivery!.day.toString().padLeft(2, '0')}/"
                              "${order.expectedDelivery!.month.toString().padLeft(2, '0')}/"
                              "${order.expectedDelivery!.year}",
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // --- Address ---
                  _AddressCard(order.deliveryAddress),

                  const SizedBox(height: 16),

                  Text("Order Progress", style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),

                  _StatusTimeline(status: order.status),

                  const SizedBox(height: 16),
                  // --- Items ---
                  _ItemsCard(order, theme),

                  // --- Cancel Button ---
                  if (canCancel)
                    _CancelButton(
                      isCancelling: _isCancelling,
                      onCancel: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Cancel Order?'),
                            content: const Text(
                              'Are you sure you want to cancel this order?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('No'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Yes'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true && _userId != null) {
                          setState(() => _isCancelling = true);
                          try {
                            await provider.cancelOrder(_userId!, order.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Order cancelled')),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          } finally {
                            setState(() => _isCancelling = false);
                          }
                        }
                      },
                    )
                  else
                    _CancellationInfo(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final dynamic address;
  const _AddressCard(this.address);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.borderColor),
      ),
      child: ListTile(
        leading: const Icon(Icons.location_on, color: AppTheme.primaryColor),
        title: Text("${address.house}, ${address.area}, ${address.city}"),
        subtitle: Text("Pincode: ${address.pincode.toString()}"), // ✅ safe
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  final Order order;
  final ThemeData theme;
  const _ItemsCard(this.order, this.theme);

  @override
  Widget build(BuildContext context) {
    return Card(
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
            Text("Items", style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),

            /// ✅ FIXED ITEM DISPLAY (no overflow)
            ...order.items.map(
              (it) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        "${it.name} x ${it.quantity}",
                        style: theme.textTheme.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      "₹${(it.price * it.quantity).toStringAsFixed(2)}",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total:",
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "₹${order.totalAmount.toStringAsFixed(2)}",
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
          ],
        ),
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
      {"key": "order_placed", "label": "Order Placed"},
      {"key": "shipped", "label": "Shipped"},
      {"key": "out_for_delivery", "label": "Out For Delivery"},
      {"key": "delivered", "label": "Delivered"},
    ];

    final currentIndex = steps.indexWhere((s) => s["key"] == status);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(steps.length, (i) {
          final step = steps[i];
          final isCompleted = i <= currentIndex;

          return Padding(
            padding: const EdgeInsets.only(bottom: 24), // ✅ More spacing
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- DOT + LINE ---
                Column(
                  children: [
                    CircleAvatar(
                      radius: 14, // ✅ Bigger dot
                      backgroundColor: isCompleted
                          ? AppTheme.successColor
                          : Colors.grey.shade300,
                      child: Icon(
                        isCompleted ? Icons.check : Icons.circle,
                        size: 14,
                        color: isCompleted ? Colors.white : Colors.grey,
                      ),
                    ),
                    if (i != steps.length - 1)
                      Container(
                        width: 3, // ✅ Thicker line
                        height: 55, // ✅ Taller spacing between dots
                        color: isCompleted
                            ? AppTheme.successColor
                            : Colors.grey.shade300,
                      ),
                  ],
                ),

                const SizedBox(width: 14),

                // --- LABEL ---
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    step["label"]!,
                    style: TextStyle(
                      fontSize: 16, // ✅ Larger text
                      fontWeight: isCompleted
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isCompleted
                          ? AppTheme.successColor
                          : Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _CancelButton extends StatelessWidget {
  final bool isCancelling;
  final VoidCallback onCancel;
  const _CancelButton({required this.isCancelling, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isCancelling ? null : onCancel,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.errorColor,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: isCancelling
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text('Cancel Order', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

class _CancellationInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
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
            'Orders cannot be cancelled after shipment.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
