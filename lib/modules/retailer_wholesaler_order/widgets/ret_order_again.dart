import 'package:flutter/material.dart';
import 'package:local_mart/data/dummy_data.dart';

class RetailerOrderAgainCarousel extends StatefulWidget {
  const RetailerOrderAgainCarousel({super.key});

  @override
  State<RetailerOrderAgainCarousel> createState() =>
      _RetailerOrderAgainCarouselState();
}

class _RetailerOrderAgainCarouselState
    extends State<RetailerOrderAgainCarousel> {
  List<Map<String, dynamic>> orderedItems = [];


  @override
  void initState() {
    super.initState();
    orderedItems = dummyOrders.first.items.map((item) => {
      'id': item.productId,
      'name': item.productName,
      'image': dummyProducts.firstWhere((p) => p.id == item.productId).image,
      'price': item.price,
      'quantity': item.quantity,
    }).toList();
  }



  @override
  Widget build(BuildContext context) {
    if (orderedItems.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Restock Inventory',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'See All',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: orderedItems.length,
            itemBuilder: (context, index) {
              final product = orderedItems[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade100,
                        image:
                            product['image'] != null &&
                                product['image'].toString().isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(product['image']),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child:
                          product['image'] == null ||
                              product['image'].toString().isEmpty
                          ? const Icon(
                              Icons.inventory_2_outlined,
                              size: 40,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 100,
                      child: Text(
                        product['name'] ?? 'Item',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
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
