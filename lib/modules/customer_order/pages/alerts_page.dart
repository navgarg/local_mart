import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:local_mart/theme.dart';

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("You are not logged in.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Alerts"),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final notifications = snapshot.data!.docs;

          if (notifications.isEmpty) {
            return Center(
              child: Text(
                "No notifications yet.",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final doc = notifications[index];
              final data = doc.data() as Map<String, dynamic>;

              final title = data['title'] ?? "No title";
              final message = data['message'] ?? "No message";
              final orderId = data['orderId'] ?? "N/A"; // ✅ NEW
              final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
              final read = data['read'] ?? false;

              // ✅ Mark as read on tap
              void markAsRead() {
                if (!read) {
                  doc.reference.update({'read': true});
                }
              }

              return InkWell(
                onTap: markAsRead,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: read ? Colors.white : Colors.blue.withOpacity(0.09),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.notifications,
                        color: read ? Colors.grey : AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title,
                                style: TextStyle(
                                  fontWeight: read ? FontWeight.w500 : FontWeight.bold,
                                  fontSize: 16,
                                )),

                            const SizedBox(height: 4),
                            Text(message, style: const TextStyle(fontSize: 14)),

                            // ✅ DISPLAY ORDER ID HERE
                            Text(
                              "Order ID: $orderId",
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                            ),

                            if (timestamp != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  "${timestamp.day}/${timestamp.month}/${timestamp.year}  ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}",
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey.shade600),
                                ),
                              ),
                          ],
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

