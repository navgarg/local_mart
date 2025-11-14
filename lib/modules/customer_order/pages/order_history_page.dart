import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import 'delivery_tracking_page.dart';
import 'pickup_tracking_page.dart';
import 'package:local_mart/theme.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  String? _userId;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid;

    if (_userId != null) {
      // Refresh once when page opens
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<OrderProvider>(context, listen: false)
            .autoRefreshAllOrders(_userId!);
      });

      //Auto refresh every 1 minute
      _autoRefreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
        Provider.of<OrderProvider>(context, listen: false)
            .autoRefreshAllOrders(_userId!);
      });
    }
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  String shortOrderCode(String id) {
    if (id.isEmpty) return "";
    final end = id.length < 6 ? id.length : 6;
    return id.substring(0, end).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Not logged in")));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "My Orders",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('orders')
            .orderBy('placedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final orders = snapshot.data!.docs;
          if (orders.isEmpty) {
            return const Center(child: Text("You haven't placed any orders yet."));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final data = orders[index].data() as Map<String, dynamic>;
              final orderId = orders[index].id;
              final shortId = shortOrderCode(orderId);

              final status = (data['status'] ?? 'unknown').toString();
              final receivingMethod = data['receivingMethod'] ?? "delivery";
              final total = data['totalAmount'] ?? 0;
              final timestamp = (data['placedAt'] as Timestamp?)?.toDate();

              Color statusColor;
              switch (status) {
                case "delivered":
                  statusColor = Colors.green;
                  break;
                case "cancelled":
                case "pickup_cancelled":
                  statusColor = Colors.red;
                  break;
                default:
                  statusColor = Colors.orange;
                  break;
              }

              return InkWell(
                onTap: () {
                  if (receivingMethod == "pickup") {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => PickupTrackingPage(orderId: orderId),
                    ));
                  } else {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => DeliveryTrackingPage(orderId: orderId),
                    ));
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Order #$shortId",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Row(
                        children: [
                          Text(
                            status.replaceAll("_", " ").toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            "₹${total.toStringAsFixed(2)}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),

                      if (timestamp != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            "${timestamp.day}/${timestamp.month}/${timestamp.year} | ${receivingMethod.toUpperCase()}",
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

