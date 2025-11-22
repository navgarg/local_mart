import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_mart/models/retailer_product.dart';
import 'package:local_mart/modules/retailer/services/retailer_product_service.dart';
import 'package:local_mart/modules/retailer/pages/retailer_product_form_page.dart';
import 'package:local_mart/modules/wholesaler/services/wholesaler_product_service.dart';
import 'package:local_mart/models/wholesaler_product.dart';

class RetailerInventoryPage extends StatelessWidget {
  final String retailerId;
  const RetailerInventoryPage({super.key, required this.retailerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  RetailerProductFormPage(retailerId: retailerId),
            ),
          );
        },
      ),
      body: StreamBuilder<List<RetailerProduct>>(
        stream: Provider.of<RetailerProductService>(
          context,
        ).getRetailerProducts(retailerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No products found.'));
          }

          final products = snapshot.data!;
          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return StreamBuilder<WholesalerProduct?>(
                stream: Provider.of<WholesalerProductService>(context).getWholesalerProductById(product.wholesalerProductId),
                builder: (context, wholesalerProductSnapshot) {
                  if (wholesalerProductSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const ListTile(title: Text('Loading product...'));
                  }
                  if (wholesalerProductSnapshot.hasError) {
                    return ListTile(
                      title: Text('Error: ${wholesalerProductSnapshot.error}'),
                    );
                  }
                  final wholesalerProduct = wholesalerProductSnapshot.data;
                  if (wholesalerProduct == null) {
                    return const ListTile(title: Text('Wholesaler Product not found'));
                  }
                  return Card(
                    margin: const EdgeInsets.all(8.0),
                    child: ListTile(
                      title: Text(wholesalerProduct.name),
                      subtitle: Text(
                        'Price: ₹${product.price.toStringAsFixed(2)} | Wholesaler Price: ₹${wholesalerProduct.price.toStringAsFixed(2)}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RetailerProductFormPage(
                                retailerId: retailerId,
                                retailerProduct: product,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
