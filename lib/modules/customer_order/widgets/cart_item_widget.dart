import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:local_mart/theme.dart';
import 'package:provider/provider.dart';

import '../models/order_model.dart';
import '../providers/cart_provider.dart';

class CartItemWidget extends StatelessWidget {
  final OrderItem item;
  const CartItemWidget({super.key, required this.item});

  //MEMORY CACHE – fixes flicker & repeated fetches.
  static final Map<String, Uint8List> _imageCache = {};
  static final Map<String, String> _sellerNameCache = {};

  Future<String> _fetchSellerName(String sellerId) async {
    if (sellerId.trim().isEmpty) return "Unknown Retailer";

    //Return cached name if already fetched
    if (_sellerNameCache.containsKey(sellerId)) {
      return _sellerNameCache[sellerId]!;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(sellerId)
          .get();

      if (!doc.exists || doc.data() == null) {
        _sellerNameCache[sellerId] = "Unknown Retailer";
        return "Unknown Retailer";
      }

      final data = doc.data()!;

      final name = data['username']?.toString().trim().isNotEmpty == true
          ? data['username']
          : "Retailer";

      _sellerNameCache[sellerId] = name;
      return name;
    } catch (_) {
      return "Retailer";
    }
  }

  Widget _buildImage() {
    final img = item.image ?? '';
    if (img.isEmpty) return _placeholder();

    // Check memory cache
    if (_imageCache.containsKey(item.productId)) {
      return Image.memory(
        _imageCache[item.productId]!,
        width: 70,
        height: 70,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
    }

    // Network Image (gapless = no flicker)
    if (img.startsWith('http')) {
      return Image.network(
        img,
        width: 70,
        height: 70,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }

    // Base64 decode ONCE
    try {
      final base64Str = img.contains(',') ? img.split(',').last : img;
      final bytes = base64Decode(base64Str);
      _imageCache[item.productId] = bytes;
      return Image.memory(
        bytes,
        width: 70,
        height: 70,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
    } catch (_) {
      return _placeholder();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        final canAddMore = cart.canIncrease(item.productId);

        return Card(
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppTheme.borderColor),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildImage(),
                ),
                const SizedBox(width: 12),

                /// TEXT SECTION
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product name
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),

                      // Price × Qty
                      Text(
                        '₹${item.price.toStringAsFixed(2)} × ${item.quantity}',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),

                      FutureBuilder<String>(
                        future: _fetchSellerName(item.sellerId),
                        initialData: _sellerNameCache[item.sellerId],
                        builder: (context, snap) {
                          return Row(
                            children: [
                              const Icon(
                                Icons.store,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  snap.data ?? "Loading...",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      if (!canAddMore)
                        Text(
                          "Max stock reached",
                          style: TextStyle(
                            color: Colors.red.shade600,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),

                /// + / –
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      color: canAddMore
                          ? AppTheme.primaryColor
                          : Colors.grey[400],
                      onPressed: canAddMore
                          ? () => cart.increaseQuantity(item.productId)
                          : null,
                    ),
                    Text(
                      '${item.quantity}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () => cart.decreaseQuantity(item.productId),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _placeholder() => Container(
    width: 70,
    height: 70,
    decoration: BoxDecoration(
      color: Colors.grey[200],
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Icon(Icons.image_not_supported, color: Colors.grey),
  );
}
