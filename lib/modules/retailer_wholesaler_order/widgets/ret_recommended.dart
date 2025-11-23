import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';

class RetailerRecommendedForYou extends StatefulWidget {
  final String userId;
  const RetailerRecommendedForYou({super.key, required this.userId});

  @override
  State<RetailerRecommendedForYou> createState() =>
      _RetailerRecommendedForYouState();
}

class _RetailerRecommendedForYouState extends State<RetailerRecommendedForYou> {
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRecommendations();
  }

  Future<void> _fetchRecommendations() async {
    try {
      // 1. Get Retailer Preferences (assuming stored in users collection)
      // If specific retailer stats aren't available, default to a category
      String targetCategory = 'Electronics'; // Default fallback

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      if (userDoc.exists &&
          userDoc.data()!.containsKey('retailerCategoryStats')) {
        // Logic to pick top category
      }

      // 2. Query Wholesaler Products
      // 🔹 CHANGE: Collection is wholesalerProducts
      final query = await FirebaseFirestore.instance
          .collection('wholesalerProducts')
          .doc('Categories')
          .collection(targetCategory)
          .limit(6)
          .get();

      final List<Map<String, dynamic>> loaded = [];
      for (var doc in query.docs) {
        var data = doc.data();
        data['id'] = doc.id;
        data['category'] = targetCategory;
        loaded.add(data);
      }

      if (mounted) {
        setState(() {
          _products = loaded;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching retailer recommendations: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildShimmer();
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

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.75,
        ),
        itemCount: 4,
        itemBuilder: (_, __) => Container(color: Colors.white),
      ),
    );
  }
}
