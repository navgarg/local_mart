import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_mart/modules/customer_order/providers/cart_provider.dart';
import 'package:local_mart/modules/customer_order/models/order_model.dart';
import 'package:local_mart/modules/customer_order/pages/alerts_page.dart';
import 'package:local_mart/modules/customer_order/pages/order_history_page.dart';

class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);

    final productsRef = FirebaseFirestore.instance
        .collection('products')
        .doc('Categories')
        .collection('electronics');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OrderHistoryPage()),
            ),
          ),

          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AlertsPage()),
            ),
          ),

          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () {
              Navigator.pushNamed(context, '/cart');
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: productsRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No products found.'));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data()! as Map<String, dynamic>;
              final id = docs[i].id;

              // Product path for stock fetch
              final productPath = 'products/Categories/electronics/$id';

              // Image handling
              Widget imageWidget;
              final imageData = data['image'];
              if (imageData != null && imageData.toString().startsWith('/9j/')) {
                try {
                  imageWidget = Image.memory(
                    base64Decode(imageData),
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  );
                } catch (_) {
                  imageWidget = const Icon(Icons.broken_image);
                }
              } else if (imageData != null && imageData.toString().startsWith('http')) {
                imageWidget = Image.network(
                  imageData,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                );
              } else {
                imageWidget = const Icon(Icons.image_not_supported);
              }

              final price = (data['price'] is num) ? (data['price'] as num).toDouble() : 0.0;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: imageWidget,
                  ),
                  title: Text(
                    data['name'] ?? 'Unnamed Product',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('₹${price.toStringAsFixed(2)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_shopping_cart),
                    color: Colors.green,
                    onPressed: () async {
                      // Fetch latest stock before adding
                      await cart.fetchStock(id, productPath);

                      cart.addItem(
                        OrderItem(
                          productId: id,
                          name: data['name'] ?? '',
                          price: price,
                          quantity: 1,
                          sellerId: data['sellerId'] ?? '',
                          image: imageData ?? '',
                          productPath: productPath,
                        ),
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${data['name']} added to cart'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
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
