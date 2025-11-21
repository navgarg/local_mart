import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';

class AppScaffold extends StatelessWidget {
  final Widget body;
  final int currentIndex;
  final ValueChanged<int> onNavTap;
  final String? title;
  final Widget? floatingActionButton;

  final List<BottomNavigationBarItem> items;

  const AppScaffold({
    super.key,
    required this.body,
    required this.currentIndex,
    required this.onNavTap,
    this.title,
    this.floatingActionButton,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          title ?? 'LocalMart',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF00A693),
          ),
        ),
        centerTitle: false,
      ),
      body: body,
      bottomNavigationBar: BottomNavBar(
        currentIndex: currentIndex,
        onTap: onNavTap,
        items: items,
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}
