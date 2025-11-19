// lib/modules/products_page/widgets/product_card.dart
import 'package:flutter/material.dart';
import '../../../models/product.dart';

import '../../../utils/image_utils.dart';
import '../../../widgets/star_rating.dart';


class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onAddToCart;
  final VoidCallback? onBuyNow;
  final VoidCallback? onOpenDetails;

  /// Controls whether to show description, buttons, etc.
  final bool showFullDetails;

  const ProductCard({
    super.key,
    required this.product,
    this.onAddToCart,
    this.onBuyNow,
    this.onOpenDetails,
    this.showFullDetails = true,
  });

  @override
  Widget build(BuildContext context) {
    final imageBytes =
    product.image.isNotEmpty ? decodeImageDataDynamic(product.image) : null;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: InkWell(
        onTap: onOpenDetails,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🖼 Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageBytes != null && imageBytes.isNotEmpty
                    ? Image.memory(
                  imageBytes,
                  height: showFullDetails ? 180 : 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                )
                    : Container(
                  height: showFullDetails ? 180 : 140,
                  width: double.infinity,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image_not_supported, size: 56),
                ),
              ),

              const SizedBox(height: 8),

              // 🏷 Product Name
              Text(
                product.name,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 6),

              // 💰 Price + ⭐ Rating (always visible)
              Row(
                children: [
                  Text(
                    "₹${product.price}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  buildStars(product.avgRating),
                ],
              ),

              // 📍 Distance (only if showFullDetails)
              if (showFullDetails &&
                  product.extraData != null &&
                  product.extraData!['__distanceKm'] != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 16, color: Color(0xFF00A693)),
                    const SizedBox(width: 4),
                    Text(
                      '${(product.extraData!['__distanceKm'] as double).toStringAsFixed(1)} km away',
                      style: const TextStyle(
                          fontSize: 13, color: Colors.black54),
                    ),
                  ],
                ),
              ],

              // 📝 Description (only if showFullDetails)
              if (showFullDetails) ...[
                const SizedBox(height: 6),
                Text(
                  product.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ],

              // 🛒 Buttons (only if showFullDetails)
              if (showFullDetails) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onAddToCart,
                        child: const Text("Add to Cart"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onBuyNow,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                        child: const Text("Buy Now"),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

