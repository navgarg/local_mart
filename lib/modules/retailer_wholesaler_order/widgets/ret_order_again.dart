import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RetailerOrderAgainCarousel extends StatefulWidget {
  const RetailerOrderAgainCarousel({super.key});

  @override
  State<RetailerOrderAgainCarousel> createState() =>
      _RetailerOrderAgainCarouselState();
}

class _RetailerOrderAgainCarouselState
    extends State<RetailerOrderAgainCarousel> {
  List<Map<String, dynamic>> orderedItems = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrderedProducts();
  }

  Future<void> _fetchOrderedProducts() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 🔹 CHANGE: Fetch from retailer orders collection
      final ordersSnap = await FirebaseFirestore.instance
          .collection(
            'retailer_wholesaler_orders',
          ) // Assuming this name based on your code
          .where('retailerId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      final Map<String, Map<String, dynamic>> uniqueItems = {};

      for (final doc in ordersSnap.docs) {
        final items = doc.data()['items'] as List<dynamic>? ?? [];
        for (final item in items) {
          final pid = item['productId'] ?? '';
          if (pid.isNotEmpty && !uniqueItems.containsKey(pid)) {
            // We use the item data stored in the order to avoid extra reads,
            // but you could fetch live data from wholesalerProducts/{cat}/{id} if needed
            uniqueItems[pid] = {
              'id': pid,
              'name': item['name'],
              'price': item['price'],
              'image':
                  item['image'] ?? '', // Ensure image is saved in order items
            };
          }
        }
      }

      if (mounted) {
        setState(() {
          orderedItems = uniqueItems.values.toList();
          loading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching retailer orders: $e");
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading || orderedItems.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Restock Inventory',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'See All',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: orderedItems.length,
            itemBuilder: (context, index) {
              final product = orderedItems[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade100,
                        image:
                            product['image'] != null &&
                                product['image'].toString().isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(product['image']),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child:
                          product['image'] == null ||
                              product['image'].toString().isEmpty
                          ? const Icon(
                              Icons.inventory_2_outlined,
                              size: 40,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 100,
                      child: Text(
                        product['name'] ?? 'Item',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
