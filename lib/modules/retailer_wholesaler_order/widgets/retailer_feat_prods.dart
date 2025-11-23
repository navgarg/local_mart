import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RetailerFeaturedProducts extends StatefulWidget {
  final String? selectedCategory;
  const RetailerFeaturedProducts({super.key, this.selectedCategory});

  @override
  State<RetailerFeaturedProducts> createState() =>
      _RetailerFeaturedProductsState();
}

class _RetailerFeaturedProductsState extends State<RetailerFeaturedProducts> {
  String? _firstCategory;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _findFirstCategory();
  }

  // 🔹 Find the first available category in 'wholesalerProducts'
  Future<void> _findFirstCategory() async {
    if (widget.selectedCategory != null) {
      setState(() {
        _firstCategory = widget.selectedCategory;
        _loading = false;
      });
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('wholesalerProducts')
          .doc('Categories')
          .get();
      if (doc.exists && doc.data() != null) {
        final list = List<String>.from(doc.data()!['categoriesList'] ?? []);
        if (list.isNotEmpty) {
          setState(() {
            _firstCategory = list.first; // e.g., "Groceries"
            _loading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint("Error finding category: $e");
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // If we couldn't find any category, hide the widget
    if (_firstCategory == null) {
      return Container(
        padding: const EdgeInsets.all(10),
        color: Colors.amber.withAlpha(50),
        child: const Text(
          "Debug: No categories found in 'wholesalerProducts/Categories'",
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      // 🔹 Dynamically query the category we found
      stream: FirebaseFirestore.instance
          .collection('wholesalerProducts')
          .doc('Categories')
          .collection(widget.selectedCategory ?? _firstCategory!)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink(); // Hide if no products in that category
        }

        final docs = snapshot.data!.docs;

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
                  _firstCategory!,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ), // Show which cat is loading
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 190,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: docs.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  // Handle image: check if it exists, otherwise show icon
                  final image = data['image'];

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
                                  (image != null && image.toString().isNotEmpty)
                                  ? DecorationImage(
                                      image: NetworkImage(image),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: (image == null || image.toString().isEmpty)
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
                                data['name'] ?? 'Unknown',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '₹${data['price'] ?? 0}',
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
      },
    );
  }
}
