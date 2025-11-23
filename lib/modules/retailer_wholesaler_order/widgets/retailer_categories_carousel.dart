import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RetailerCategoryCarousel extends StatefulWidget {
  final Function(String)? onCategorySelected;
  const RetailerCategoryCarousel({super.key, this.onCategorySelected});

  @override
  State<RetailerCategoryCarousel> createState() =>
      _RetailerCategoryCarouselState();
}

class _RetailerCategoryCarouselState extends State<RetailerCategoryCarousel> {
  List<String> categories = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      // 1. Try Wholesaler Specific Categories
      var doc = await FirebaseFirestore.instance
          .collection('wholesalerProducts')
          .doc('Categories')
          .get();

      // 2. Fallback to General Products if Wholesaler empty
      if (!doc.exists || doc.data() == null) {
        debugPrint(
          "Wholesaler categories not found, trying generic products...",
        );
        doc = await FirebaseFirestore.instance
            .collection('products')
            .doc('Categories')
            .get();
      }

      if (doc.exists && doc.data()!['categoriesList'] != null) {
        setState(() {
          categories = List<String>.from(doc.data()!['categoriesList']);
          loading = false;
        });
        return;
      }
    } catch (e) {
      debugPrint("Error loading categories: $e");
    }

    if (mounted) setState(() => loading = false);
  }

  IconData _iconForLabel(String label) {
    final l = label.toLowerCase();
    if (l.contains('grocer')) return Icons.local_grocery_store;
    if (l.contains('elect')) return Icons.electrical_services;
    if (l.contains('fashion') || l.contains('cloth')) return Icons.checkroom;
    return Icons.category;
  }

  @override
  Widget build(BuildContext context) {
    if (loading)
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      );
    if (categories.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Categories', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final label = categories[index];
              return GestureDetector(
                onTap: () => widget.onCategorySelected?.call(label),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.blue.withAlpha(20),
                      child: Icon(
                        _iconForLabel(label),
                        color: Colors.blue,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 70,
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: const TextStyle(fontSize: 12),
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
