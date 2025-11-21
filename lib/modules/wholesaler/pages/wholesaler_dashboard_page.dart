import 'package:flutter/material.dart';
import 'package:local_mart/modules/wholesaler/pages/wholesaler_order_history_page.dart';

import 'package:local_mart/widgets/bottom_nav_bar.dart';
import 'package:local_mart/modules/wholesaler/pages/wholesaler_home_page.dart';
import 'package:local_mart/modules/wholesaler/pages/wholesaler_account_page.dart';
import 'package:local_mart/modules/wholesaler/pages/wholesaler_alerts_page.dart';

class WholesalerDashboardPage extends StatefulWidget {
  static const String routeName = '/wholesaler-dashboard';
  const WholesalerDashboardPage({super.key});

  @override
  State<WholesalerDashboardPage> createState() => _WholesalerDashboardPageState();
}

class _WholesalerDashboardPageState extends State<WholesalerDashboardPage> {
  int _currentIndex = 0;

  final List<String> _titles = const [
    'Wholesaler Home',
    'Orders',
    'Account',
    'Alerts',
  ];

  final List<Widget> _pages = [
    const WholesalerHomePage(),
    const WholesalerOrderHistoryPage(),
    const WholesalerAccountPage(),
    const WholesalerAlertsPage(),
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
        title: Text(_titles[_currentIndex]),
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Account'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_none), label: 'Alerts'),
        ],
      ),
    );
  }
}