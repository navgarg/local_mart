import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:local_mart/models/wholesaler_product.dart'; // Assuming a new model for wholesaler products
import 'package:local_mart/modules/wholesaler/services/wholesaler_product_service.dart'; // Assuming a new service
import 'package:local_mart/modules/wholesaler/pages/wholesaler_product_form_page.dart'; // Assuming a new form page

class WholesalerInventoryPage extends StatefulWidget {
  const WholesalerInventoryPage({super.key});

  @override
  State<WholesalerInventoryPage> createState() => _WholesalerInventoryPageState();
}

class _WholesalerInventoryPageState extends State<WholesalerInventoryPage> {
  String? _wholesalerId;

  @override
  void initState() {
    super.initState();
    _wholesalerId = FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  Widget build(BuildContext context) {
    if (_wholesalerId == null) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: true,
          title: const Text('Wholesaler Inventory')),
        body: const Center(child: Text('Please log in as a wholesaler.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text('Wholesaler Inventory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const WholesalerProductFormPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<WholesalerProduct>>(
        stream: Provider.of<WholesalerProductService>(context)
            .getWholesalerProducts(_wholesalerId!),
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
                  title: Text(product.name), // Display product name
                  subtitle: Text('Price: ₹${product.price} | Stock: ${product.stock}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => WholesalerProductFormPage(
                                wholesalerProduct: product,
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          await Provider.of<WholesalerProductService>(context, listen: false)
                              .deleteWholesalerProduct(product.id);
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