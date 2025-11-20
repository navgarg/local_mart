import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:local_mart/models/retailer_product.dart';
import 'package:local_mart/modules/retailer/services/retailer_product_service.dart';

class RetailerInventoryPage extends StatefulWidget {
  const RetailerInventoryPage({super.key});

  @override
  State<RetailerInventoryPage> createState() => _RetailerInventoryPageState();
}

class _RetailerInventoryPageState extends State<RetailerInventoryPage> {
  String? _retailerId;

  @override
  void initState() {
    super.initState();
    _retailerId = FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  Widget build(BuildContext context) {
    if (_retailerId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Retailer Inventory')),
        body: const Center(child: Text('Please log in as a retailer.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Retailer Inventory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Navigate to add product page
            },
          ),
        ],
      ),
      body: StreamBuilder<List<RetailerProduct>>(
        stream: Provider.of<RetailerProductService>(context)
            .getRetailerProducts(_retailerId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No products in your inventory.'));
          }

          final products = snapshot.data!;
          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(product.productId), // Placeholder for product name
                  subtitle: Text('Price: ₹${product.price} | Stock: ${product.stock}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          // Navigate to edit product page
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          // Delete product
                        },
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