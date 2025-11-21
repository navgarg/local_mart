import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:local_mart/widgets/category_carousel.dart';
import 'package:local_mart/widgets/featured_products.dart';
import 'package:local_mart/widgets/order_again_carousel.dart';
import 'package:local_mart/widgets/recommended_for_you.dart';
import 'package:local_mart/widgets/search_bar.dart';

class RetailerHomePage extends StatefulWidget {
  const RetailerHomePage({super.key});

  @override
  State<RetailerHomePage> createState() => _RetailerHomePageState();
}

class _RetailerHomePageState extends State<RetailerHomePage> {
  double _scrollOffset = 0.0;

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
              // 🔹 Floating / Shrinking Search Bar with Blur
              ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: _scrollOffset > 15 ? 56 : 68,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha:0.85),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha:0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const SafeArea(child: SearchBarWidget()),
                  ),
                ),
              ),

              // 🔹 Scrollable main section
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      const CategoryCarousel(),
                      const SizedBox(height: 15),
                      FeaturedProducts(),
                      const SizedBox(height: 20),
                      OrderAgainCarousel(),
                      const SizedBox(height: 30),
                      if (userId.isNotEmpty)
                        RecommendedForYou(userId: userId),
                      const SizedBox(height: 30),
                      Center(
                        child: Text(
                          "🎉 You've reached the end!",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
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