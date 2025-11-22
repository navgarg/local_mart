import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product.dart';
import '../modules/products_page/product_details.dart';

class OrderAgainCarousel extends StatefulWidget {
  const OrderAgainCarousel({super.key});

  @override
  State<OrderAgainCarousel> createState() => _OrderAgainCarouselState();
}

class _OrderAgainCarouselState extends State<OrderAgainCarousel> {
  bool loading = true;
  List<Product> uniqueOrderedProducts = [];

  @override
  void initState() {
    print("init state called for order again carousel");
    super.initState();
    _fetchOrderedProducts();
  }

  Future<void> _fetchOrderedProducts() async {
    print("fetch ordered products called");
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final firestore = FirebaseFirestore.instance;
      final ordersSnap = await firestore
          .collection('users')
          .doc(user.uid)
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .get();

      final Map<String, Product> map = {};
      final catRoot = firestore.collection('products').doc('Categories');
      final catsDoc = await catRoot.get();
      final cats =
          (catsDoc.data()?['categoriesList'] ?? []) as List<dynamic>? ?? [];

      for (final orderDoc in ordersSnap.docs) {
        final items = orderDoc.data()['items'] as List<dynamic>? ?? [];

        for (final item in items) {
          final pid = item['productId'] ?? '';
          if (pid.isEmpty || map.containsKey(pid)) continue;

          // Try fetching the actual product document to get updated fields
          Product? liveProduct;
          for (final c in cats) {
            final pDoc = await catRoot.collection(c.toString()).doc(pid).get();
            if (pDoc.exists) {
              liveProduct = Product.fromFirestore(pDoc.data()!, pDoc.id);
              break;
            }
          }

          // If live data not found, fallback to order item data
          map[pid] =
              liveProduct ??
              Product.fromFirestore(
                {
                  'id': pid,
                  'name': item['name'] ?? '',
                  'description': '',
                  'image': item['image'] ?? '',
                  'price': (item['price'] ?? 0).toInt(),
                  'stock': 0,
                  'sellerId': item['sellerId'] ?? '',
                  'avgRating': 0,
                  'sellerType': 'unknown', // Default sellerType for fallback
                  'extraData': {'productPath': item['productPath'] ?? ''},
                },
                pid,
              );
        }
      }

      if (mounted) {
        setState(() {
          print("setting state for order again carousel");
          uniqueOrderedProducts = map.values.toList();
          loading = false;
        });
      }
    } catch (e) {
      print("Error in _fetchOrderedProducts: $e");
      debugPrint("⚠️ Error fetching Buy Again: $e");
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    print("build called for order again carousel");
    if (loading) {
      print("loading is true for order again carousel");
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    print("uniqueOrderedProducts length: ${uniqueOrderedProducts.length}");
    if (uniqueOrderedProducts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Buy Again',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Orders page coming soon...")),
                  );
                },
                child: Text(
                  'See All',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Carousel
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: uniqueOrderedProducts.length,
            itemBuilder: (context, index) {
              final product = uniqueOrderedProducts[index];

              Widget imgWidget;
              try {
                if (product.image.startsWith('/9j')) {
                  imgWidget = Image.memory(
                    base64Decode(product.image),
                    fit: BoxFit.cover,
                    width: 100,
                    height: 100,
                  );
                } else {
                  imgWidget = Image.network(
                    product.image,
                    fit: BoxFit.cover,
                    width: 100,
                    height: 100,
                  );
                }
              } catch (_) {
                imgWidget = const Icon(Icons.image_not_supported, size: 60);
              }
              print("building item for product id: ${product.id}");
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ProductDetailsPage(product: product, fromIndex: 0),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey.shade50,
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: imgWidget,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 100,
                        child: Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            overflow: TextOverflow.ellipsis,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
