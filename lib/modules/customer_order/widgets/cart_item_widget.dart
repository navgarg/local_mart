import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../providers/cart_provider.dart';
import 'package:provider/provider.dart';

class CartItemWidget extends StatelessWidget {
  final OrderItem item;
  const CartItemWidget({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            // Placeholder image
            Container(
              width: 64,
              height: 64,
              color: Colors.grey[200],
              child: const Icon(Icons.image, size: 36),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 6),
                  Text('₹${item.price.toStringAsFixed(2)} x ${item.quantity}', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 6),
                  // delivery time text comes from top-level grouping (handled in page)
                  // Show retailer id as small text
                  Text('From retailer: ${item.retailerId}', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => cart.changeQuantity(item.productId, 1),
                ),
                Text(item.quantity.toString()),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () => cart.changeQuantity(item.productId, -1),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
