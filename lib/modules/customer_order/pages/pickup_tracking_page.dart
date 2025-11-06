import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/order_provider.dart';
import '../models/order_model.dart' as models;
import 'package:local_mart/theme.dart';

class PickupTrackingPage extends StatefulWidget {
  final String orderId;
  const PickupTrackingPage({super.key, required this.orderId});

  @override
  State<PickupTrackingPage> createState() => _PickupTrackingPageState();
}

class _PickupTrackingPageState extends State<PickupTrackingPage> {
  String? _userId;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid;
    if (_userId != null) {
      Provider.of<OrderProvider>(context, listen: false)
          .listenToOrder(_userId!, widget.orderId);
    }
  }

  @override
  void dispose() {
    Provider.of<OrderProvider>(context, listen: false).stopListeningToOrder();
    super.dispose();
  }

  Future<Map<String, dynamic>?> _getPickupStoreAddress(String sellerId) async {
    final doc = await FirebaseFirestore.instance.collection("users").doc(sellerId).get();
    return doc.data()?["address"];
  }

  String _formatPickupDate(DateTime? dt) {
    if (dt == null) return "Not Selected";
    return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<OrderProvider>(context);
    final order = provider.activeOrder;
    if (order == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = AppTheme.lightTheme;
    final sellerId = order.items.first.sellerId;

    // ✅ Cancel allowed only if still preparing
    final bool canCancel = order.status == "preparing";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pickup Tracking"),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
      ),

      body: RefreshIndicator(
        onRefresh: () async {
          if (_userId != null) await provider.refreshOrder(widget.orderId, _userId!);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Order Info Card (same style as delivery tracking) ---
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
                        "Order #${order.id.substring(0, 6).toUpperCase()}",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.store, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            order.status.replaceAll("_", " ").toUpperCase(),
                            style: TextStyle(
                              color: order.status == 'picked'
                                  ? AppTheme.successColor
                                  : order.status == 'pickup_cancelled'
                                  ? AppTheme.errorColor
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

              /// ✅ PICKUP DATE CARD
              Card(
                color: AppTheme.cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppTheme.borderColor),
                ),
                child: ListTile(
                  leading: const Icon(Icons.event, color: AppTheme.primaryColor),
                  title: const Text("Pickup Date"),
                  subtitle: Text(_formatPickupDate(order.pickupDate)),
                ),
              ),

              const SizedBox(height: 16),

              /// ✅ SHOP ADDRESS
              FutureBuilder(
                future: _getPickupStoreAddress(sellerId),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final addr = snap.data!;
                  return Card(
                    color: AppTheme.cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppTheme.borderColor),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.store, color: AppTheme.primaryColor),
                      title: const Text("Pickup Store"),
                      subtitle: Text("${addr['area']}, ${addr['city']} - ${addr['pincode']}"),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              Text("Pickup Progress", style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),

              _PickupStatusTimeline(status: order.status),

              const SizedBox(height: 24),

              /// ✅ ITEMS SUMMARY (same style as delivery)
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
                      Text("Items", style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ...order.items.map((it) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text("${it.name} x ${it.quantity}")),
                            Text("₹${(it.price * it.quantity).toStringAsFixed(2)}"),
                          ],
                        ),
                      )),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Total:", style: TextStyle(fontWeight: FontWeight.bold)),
                          Text("₹${order.totalAmount.toStringAsFixed(2)}",
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              /// ✅ CANCEL BUTTON (only when allowed)
              if (canCancel)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isCancelling ? null : () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("Cancel Pickup?"),
                          content: const Text("Are you sure you want to cancel this pickup order?"),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("No")),
                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Yes")),
                          ],
                        ),
                      );
                      if (confirm != true) return;
                      setState(() => _isCancelling = true);
                      await provider.cancelPickupOrder(order.id, _userId!);
                      setState(() => _isCancelling = false);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pickup Cancelled")));
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
                    child: _isCancelling
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("Cancel Pickup", style: TextStyle(color: Colors.white)),
                  ),
                )
              else
                const _CancellationInfo(),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickupStatusTimeline extends StatelessWidget {
  final String status;
  const _PickupStatusTimeline({required this.status});

  @override
  Widget build(BuildContext context) {
    final steps = [
      {"key": "preparing", "label": "Preparing"},
      {"key": "ready", "label": "Ready for Pickup"},
      {"key": "picked", "label": "Picked Up"},
    ];

    final currentIndex = steps.indexWhere((s) => s["key"] == status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(steps.length, (i) {
        final step = steps[i];
        final active = i <= currentIndex;

        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            children: [
              Column(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: active ? AppTheme.successColor : Colors.grey.shade300,
                    child: Icon(active ? Icons.check : Icons.circle,
                        size: 14, color: active ? Colors.white : Colors.grey),
                  ),
                  if (i != steps.length - 1)
                    Container(width: 3, height: 50, color: active ? AppTheme.successColor : Colors.grey.shade300),
                ],
              ),
              const SizedBox(width: 12),
              Text(step["label"]!,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: active ? FontWeight.bold : FontWeight.normal,
                    color: active ? AppTheme.successColor : Colors.grey.shade600,
                  )),
            ],
          ),
        );
      }),
    );
  }
}

class _CancellationInfo extends StatelessWidget {
  const _CancellationInfo();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.info_outline, color: Colors.grey),
          SizedBox(width: 8),
          Text("Pickup cannot be cancelled after preparation.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
