import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/cart_item_widget.dart';
import 'package:local_mart/theme.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final grouped = cart.groupedByRetailer();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
      ),
      body: cart.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Your cart is empty',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/inventory');
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
                for (var retailerId in grouped.keys)
                  Card(
                    color: theme.cardColor,
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppTheme.borderColor),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Retailer: $retailerId',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Estimated delivery: processing + transit + buffer',
                            style: theme.textTheme.bodySmall,
                          ),
                          const Divider(height: 16),
                          ...grouped[retailerId]!
                              .map((item) => CartItemWidget(item: item))
                              .toList(),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Missed something? Add more',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Total: ₹${cart.total.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/checkout');
                  },
                  child: const Text('Proceed to Checkout'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

