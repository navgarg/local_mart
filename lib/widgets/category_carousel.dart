import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class CategoryCarousel extends StatefulWidget {
  final Function(String)? onCategorySelected;

  const CategoryCarousel({super.key, this.onCategorySelected});

  @override
  State<CategoryCarousel> createState() => _CategoryCarouselState();
}

class _CategoryCarouselState extends State<CategoryCarousel> {
  List<String> categories = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('products').doc('Categories').get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['categoriesList'] != null) {
          setState(() {
            categories = List<String>.from(data['categoriesList']);
            loading = false;
          });
          return;
        }
      }
    } catch (e) {
      // ignore for now, show empty later
    }
    setState(() {
      categories = [];
      loading = false;
    });
  }

  IconData _iconForLabel(String label) {
    final l = label.toLowerCase();
    if (l.contains('grocer') || l.contains('grocery')) return Icons.shopping_bag_outlined;
    if (l.contains('fashion') || l.contains('cloth') || l.contains('clothes')) return Icons.style;
    if (l.contains('furn')) return Icons.chair_outlined;
    if (l.contains('elect')) return Icons.computer;
    if (l.contains('appl') || l.contains('kitchen')) return Icons.kitchen;
    if (l.contains('station') || l.contains('pen')) return Icons.edit_note;
    if (l.contains('personal') || l.contains('care') || l.contains('beauty')) return Icons.spa;
    if (l.contains('home') || l.contains('kitchen') || l.contains('appl')) return Icons.kitchen;
    if (l.contains('toy')) return Icons.toys;
    if (l.contains('sport')) return Icons.sports_soccer;
    return Icons.category;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Categories', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          SizedBox(height: 90, child: Center(child: CircularProgressIndicator())),
        ],
      );
    }

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
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final label = categories[index];
              String formattedLabel = label.trim();
              if (formattedLabel.isNotEmpty) {
                formattedLabel = formattedLabel[0].toUpperCase() + formattedLabel.substring(1).toLowerCase();
              }

              return InkWell(
                onTap: () {
                  Navigator.pop(context);
                  widget.onCategorySelected?.call(label);
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Theme.of(context).primaryColor.withAlpha((255 * 0.08).round()),
                      child: Icon(
                        _iconForLabel(label),
                        color: Theme.of(context).primaryColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 78,
                      height: 38,
                      child: Text(
                        formattedLabel,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}