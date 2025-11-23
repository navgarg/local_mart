import 'package:flutter/material.dart';
import 'package:local_mart/data/dummy_data.dart'; // Import dummy data

class RetailerFeaturedProducts extends StatefulWidget {
  final String? selectedCategory;
  const RetailerFeaturedProducts({super.key, this.selectedCategory});

  @override
  State<RetailerFeaturedProducts> createState() =>
      _RetailerFeaturedProductsState();
}

class _RetailerFeaturedProductsState extends State<RetailerFeaturedProducts> {
  List<Product> _filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _filterProducts();
  }

  @override
  void didUpdateWidget(covariant RetailerFeaturedProducts oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedCategory != oldWidget.selectedCategory) {
      _filterProducts();
    }
  }

  void _filterProducts() {
    setState(() {
      if (widget.selectedCategory == null || widget.selectedCategory == 'All') {
        _filteredProducts = dummyProducts;
      } else {
        _filteredProducts = dummyProducts
            .where((product) => product.category == widget.selectedCategory)
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_filteredProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Trending in Wholesale',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.selectedCategory ?? 'All',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ), // Show which cat is loading
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 190,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _filteredProducts.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final product = _filteredProducts[index];

              return Container(
                width: 140,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          image:
                              (product.image.isNotEmpty)
                                  ? DecorationImage(
                                      image: NetworkImage(product.image),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                        ),
                        child: (product.image.isEmpty)
                            ? const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey,
                                ),
                              )
                            : null,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '₹${product.price}',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
