import 'dart:async';
import 'package:flutter/material.dart';

class FeaturedProducts extends StatefulWidget {
  const FeaturedProducts({super.key});

  @override
  State<FeaturedProducts> createState() => _FeaturedProductsState();
}

class _FeaturedProductsState extends State<FeaturedProducts> {
  final PageController _controller = PageController(viewportFraction: 0.85);
  int _currentPage = 0;
  Timer? _timer;
  bool _userInteracting = false;

  final featured = [
    {'image': 'assets/images/fruits.png'},
    {'image': 'assets/images/kitchen.png'},
    {'image': 'assets/images/decor.png'},
  ];

  @override
  void initState() {
    super.initState();
    _startAutoSlide();

    _controller.addListener(() {
      int next = _controller.page!.round();
      if (_currentPage != next) {
        setState(() {
          _currentPage = next;
        });
      }
    });
  }

  void _startAutoSlide() {
    _timer?.cancel(); // clear old timer
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_userInteracting && _controller.hasClients) {
        int nextPage = (_currentPage + 1) % featured.length;
        _controller.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _pauseAutoSlide() {
    setState(() => _userInteracting = true);
    _timer?.cancel();
  }

  void _resumeAutoSlide() {
    setState(() => _userInteracting = false);
    _startAutoSlide();
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanDown: (_) => _pauseAutoSlide(),
      onPanCancel: _resumeAutoSlide,
      onPanEnd: (_) => _resumeAutoSlide(),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PageView.builder(
              controller: _controller,
              itemCount: featured.length,
              itemBuilder: (context, index) {
                final item = featured[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      item['image']!,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(featured.length, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 16 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? Colors.black87
                      : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
