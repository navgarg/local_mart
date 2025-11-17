import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/product.dart';
import '../modules/products_page/widgets/product_card.dart';
import 'package:shimmer/shimmer.dart';
import '../modules/products_page/product_details.dart';

class RecommendedForYou extends StatefulWidget {
  final String userId;

  const RecommendedForYou({super.key, required this.userId});

  @override
  State<RecommendedForYou> createState() => _RecommendedForYouState();
}

class _RecommendedForYouState extends State<RecommendedForYou> {
  List<Product> _products = [];
  List<String> _topCategories = [];
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDoc;

  static const int _batchSize = 6;

  // 🔹 Cache for average ratings to avoid refetching
  final Map<String, double> _ratingCache = {};

  @override
  void initState() {
    super.initState();
    _initializeRecommendations();
  }

  Future<void> _initializeRecommendations() async {
    final categories = await _getTopCategories();
    if (mounted) {
      setState(() => _topCategories = categories);
    }
    await _fetchProducts();
  }

  /// 🔹 Fetch top 2 categories from user's categoryStats
  Future<List<String>> _getTopCategories() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();

    final data = userDoc.data();
    if (data == null || data['categoryStats'] == null) return [];

    final stats = Map<String, dynamic>.from(data['categoryStats']);
    final sorted = stats.entries.toList()
      ..sort((a, b) => (b.value as int).compareTo(a.value as int));

    return sorted.take(2).map((e) => e.key).toList();
  }

  /// 🔹 Fetch average rating from subcollection (cached)
  Future<double> _getAverageRating(String category, String productId) async {
    // Check in cache first
    if (_ratingCache.containsKey(productId)) {
      return _ratingCache[productId]!;
    }

    try {
      final ratingsSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .doc('Categories')
          .collection(category)
          .doc(productId)
          .collection('Rating')
          .get();

      if (ratingsSnapshot.docs.isEmpty) {
        _ratingCache[productId] = 0.0;
        return 0.0;
      }

      double total = 0;
      for (final doc in ratingsSnapshot.docs) {
        total += ((doc['rating'] ?? doc['Rating']) ?? 0).toDouble();
      }
      final avg = total / ratingsSnapshot.docs.length;

      // Store in cache
      _ratingCache[productId] = avg;
      return avg;
    } catch (e) {
      debugPrint('⚠️ Error fetching ratings for $productId: $e');
      return 0.0;
    }
  }

  /// 🔹 Fetch products from Firestore
  Future<void> _fetchProducts() async {
    if (_isLoading || !_hasMore || _topCategories.isEmpty) return;
    setState(() => _isLoading = true);

    try {
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection('products')
          .doc('Categories')
          .collection(_topCategories.first)
          .orderBy('name')
          .limit(_batchSize);

      if (_lastDoc != null) query = query.startAfterDocument(_lastDoc!);

      final snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        _lastDoc = snapshot.docs.last;

        final List<Product> newProducts = [];

        for (final doc in snapshot.docs) {
          final data = doc.data();
          final product = Product.fromFirestore(data, doc.id);

          // Fetch accurate average rating dynamically
          final avgRating = await _getAverageRating(
            _topCategories.first,
            doc.id,
          );

          newProducts.add(product.copyWith(avgRating: avgRating));
        }

        setState(() {
          _products.addAll(newProducts);
          if (newProducts.length < _batchSize) _hasMore = false;
        });
      } else {
        setState(() => _hasMore = false);
      }
    } catch (e) {
      debugPrint("⚠️ Error loading products: $e");
    }

    setState(() => _isLoading = false);
  }

  /// 🔹 Detect scroll and load more
  void _onScroll(ScrollNotification scrollInfo) {
    if (!_isLoading &&
        _hasMore &&
        scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
      _fetchProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const crossAxisCount = 2;
    const spacing = 10.0;
    const horizontalPadding = 12.0;

    final usableWidth =
        screenWidth -
        (horizontalPadding * 2) -
        (spacing * (crossAxisCount - 1));
    final itemWidth = usableWidth / crossAxisCount;
    final itemHeight = itemWidth * 1.55;
    final aspectRatio = itemWidth / itemHeight;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 10, bottom: 8),
            child: Text(
              'Recommended for You',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),

          // ✅ Grid Section
          NotificationListener<ScrollNotification>(
            onNotification: (scrollInfo) {
              _onScroll(scrollInfo);
              return false;
            },
            child: _products.isEmpty && _isLoading
                ? _buildShimmerGrid(aspectRatio)
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: spacing,
                      mainAxisSpacing: spacing,
                      childAspectRatio: aspectRatio,
                    ),
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final product = _products[index];
                      return ProductCard(
                        product: product,
                        showFullDetails: false,
                        onOpenDetails: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProductDetailsPage(product: product),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// ✅ Shimmer loading placeholder
  Widget _buildShimmerGrid(double aspectRatio) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: aspectRatio,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
    );
  }
}
