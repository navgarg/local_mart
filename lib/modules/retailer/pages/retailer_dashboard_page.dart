import 'package:flutter/material.dart';
import 'package:local_mart/widgets/bottom_nav_bar.dart';
import 'package:local_mart/modules/retailer/pages/retailer_inventory_page.dart';
import 'package:local_mart/modules/retailer/pages/retailer_home_page.dart';
import 'package:local_mart/modules/retailer/pages/retailer_orders_page.dart';
import 'package:local_mart/modules/retailer/pages/retailer_account_page.dart';

class RetailerDashboardPage extends StatefulWidget {
  const RetailerDashboardPage({super.key});

  @override
  State<RetailerDashboardPage> createState() => _RetailerDashboardPageState();
}

class _RetailerDashboardPageState extends State<RetailerDashboardPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const RetailerHomePage(),
    const RetailerInventoryPage(),
    const RetailerOrdersPage(),
    const RetailerAccountPage(),
  ];

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Retailer Dashboard'),
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: 'Products'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Account'),
        ],
      ),
    );
  }
}