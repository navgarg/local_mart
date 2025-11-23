import 'package:flutter/material.dart';
import 'package:local_mart/data/dummy_data.dart';

class RetailerRecommendedForYou extends StatefulWidget {
  final String userId;
  const RetailerRecommendedForYou({super.key, required this.userId});

  @override
  State<RetailerRecommendedForYou> createState() =>
      _RetailerRecommendedForYouState();
}

class _RetailerRecommendedForYouState extends State<RetailerRecommendedForYou> {
  List<Map<String, dynamic>> _products = [];

  final bool _useDummyData = true;

  @override
  void initState() {
    super.initState();
    if (_useDummyData) {
      _products = dummyProducts
          .take(6)
          .map(
            (p) => {
              'id': p.id,
              'name': p.name,
              'image': p.image,
              'price': p.price,
              'category': p.category,
              'stock': 10, // Dummy stock value
            },
          )
          .toList();
      // _isLoading = false;
    } else {
      // _fetchRecommendations();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_products.isEmpty) return SizedBox.shrink();
    if (_products.isEmpty) return SizedBox.shrink();

    // Use GridView or Column as per original design
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recommended for your Shop',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.75,
          ),
          itemCount: _products.length,
          itemBuilder: (context, index) {
            final p = _products[index];
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.grey.shade200, blurRadius: 4),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: p['image'] != null
                          ? Image.network(
                              p['image'],
                              fit: BoxFit.cover,
                              width: double.infinity,
                            )
                          : const Center(child: Icon(Icons.image)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p['name'] ?? 'Product',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                        ),
                        Text(
                          '₹${p['price']}',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        Text(
                          'Stock: ${p['stock'] ?? 0}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
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
      ],
    );
  }
}
