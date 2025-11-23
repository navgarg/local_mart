import 'package:flutter/material.dart';
import 'package:local_mart/data/dummy_data.dart';

class WholesalerInventoryPage extends StatelessWidget {
  const WholesalerInventoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          // No action for dummy data
        },
      ),
      body: ListView.builder(
        itemCount: dummyProducts.length,
        itemBuilder: (context, index) {
          final product = dummyProducts[index];
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              title: Text(product.name), // Display product name
              subtitle: Text(
                'Price: ₹${product.price} | Category: ${product.category}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      // No action for dummy data
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
                      // No action for dummy data
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
