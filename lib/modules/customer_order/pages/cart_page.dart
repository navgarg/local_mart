import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/cart_item_widget.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final grouped = cart.groupedByRetailer();

    return Scaffold(
      appBar: AppBar(title: const Text('My Cart')),
      body: cart.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Your cart is empty', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                // redirect to product search / home page
                Navigator.pushNamed(context, '/inventory'); // adjust route
              },
              child: const Text('Browse Products'),
            ),
          ],
        ),
      )
          : Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                // iterate retailers, show a header for each
                for (var retailerId in grouped.keys)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Text('Retailer: $retailerId', style: Theme.of(context).textTheme.bodyLarge),
                      ),
                      // TODO: compute delivery time per retailer and display (we mock text here)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('Estimated delivery: processing + transit + buffer',
                            style: Theme.of(context).textTheme.bodyMedium),
                      ),
                      ...grouped[retailerId]!.map((item) => CartItemWidget(item: item)).toList(),
                    ],
                  ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('Missed something? Add more', style: Theme.of(context).textTheme.bodyMedium),
                ),
              ],
            ),
          ),
          // bill summary + checkout button
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Text('Total: ₹${cart.total.toStringAsFixed(2)}', style: Theme.of(context).textTheme.bodyLarge),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/checkout');
                  },
                  child: const Text('Proceed to Checkout'),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
