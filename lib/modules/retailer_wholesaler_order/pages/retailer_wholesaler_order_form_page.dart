import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:local_mart/modules/search_page/search_page.dart';
import 'package:local_mart/widgets/search_bar.dart';
import 'package:local_mart/modules/retailer_wholesaler_order/models/retailer_wholesaler_order_model.dart';
import 'package:local_mart/modules/retailer_wholesaler_order/widgets/ret_order_again.dart';
import 'package:local_mart/modules/retailer_wholesaler_order/widgets/ret_recommended.dart';
import 'package:local_mart/modules/retailer_wholesaler_order/widgets/retailer_categories_carousel.dart';
import 'package:local_mart/modules/retailer_wholesaler_order/widgets/retailer_feat_prods.dart';

class RetailerWholesalerOrderFormPage extends StatefulWidget {
  // 2. ADD THIS VARIABLE
  final RetailerWholesalerOrder? order;

  // 3. UPDATE CONSTRUCTOR to accept 'this.order'
  const RetailerWholesalerOrderFormPage({super.key, this.order});

  @override
  State<RetailerWholesalerOrderFormPage> createState() =>
      _RetailerWholesalerOrderFormPageState();
}

class _RetailerWholesalerOrderFormPageState
    extends State<RetailerWholesalerOrderFormPage> {
  double _scrollOffset = 0.0;
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        body: NotificationListener<ScrollNotification>(
          onNotification: (scroll) {
            setState(() => _scrollOffset = scroll.metrics.pixels);
            return false;
          },
          child: Column(
            children: [
              // 🔹 FIXED SEARCH BAR
              ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: _scrollOffset > 15 ? 56 : 68,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const SafeArea(child: SearchBarWidget()),
                  ),
                ),
              ),

              // 🔹 MAIN SCROLLABLE SECTION
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      // 1. Categories
                      RetailerCategoryCarousel(
                        onCategorySelected: (category) {
                          setState(() {
                            _selectedCategory = category;
                          });
                          debugPrint("Selected $category");
                        },
                      ),
                      const SizedBox(height: 15),

                      // 2. Featured Products (Now Dynamic)
                      RetailerFeaturedProducts(selectedCategory: _selectedCategory,),

                      const SizedBox(height: 20),

                      // 3. Order Again (Will be hidden if no orders exist)
                      const RetailerOrderAgainCarousel(),

                      const SizedBox(height: 30),

                      // 4. Recommended
                      if (userId.isNotEmpty)
                        RetailerRecommendedForYou(userId: userId),

                      const SizedBox(height: 30),
                      Center(
                        child: Text(
                          "🎉 You've reached the end!",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
