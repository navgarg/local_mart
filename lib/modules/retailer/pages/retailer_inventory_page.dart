import 'package:flutter/material.dart';
import 'package:local_mart/data/dummy_data.dart';



import 'package:local_mart/modules/retailer/pages/retailer_product_form_page.dart';


class RetailerInventoryPage extends StatelessWidget {
  const RetailerInventoryPage({super.key});

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
                  RetailerProductFormPage(),
            ),
          );
        },
      ),
      body: ListView.builder(
        itemCount: dummyRetailerProducts.length,
        itemBuilder: (context, index) {
          final product = dummyRetailerProducts[index];
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              title: Text(product.name),
              subtitle: Text(
                'Price: ₹${product.price.toStringAsFixed(2)} | Stock: ${product.stock}',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RetailerProductFormPage(
                        retailerProduct: product,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
