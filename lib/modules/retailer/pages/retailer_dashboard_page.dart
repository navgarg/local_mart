import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:local_mart/modules/retailer/pages/retailer_home_page.dart';
import 'package:local_mart/modules/retailer/pages/retailer_order_history_page.dart';
import 'package:local_mart/modules/retailer/pages/retailer_account_page.dart';
import 'package:local_mart/modules/retailer/pages/retailer_alerts_page.dart';
import 'package:local_mart/widgets/bottom_nav_bar.dart';

class RetailerDashboardPage extends StatefulWidget {
  static const String routeName = '/retailer-dashboard';
  const RetailerDashboardPage({super.key});

  @override
  State<RetailerDashboardPage> createState() => _RetailerDashboardPageState();
}

class _RetailerDashboardPageState extends State<RetailerDashboardPage> {
  int _currentIndex = 0;

  final List<String> _titles = const [
    'Retailer Home',
    'Orders',
    'Account',
    'Alerts',
  ];

  final List<Widget> _pages = [
    RetailerHomePage(userId: FirebaseAuth.instance.currentUser!.uid),
    const RetailerOrderHistoryPage(),
    RetailerAccountPage(userId: FirebaseAuth.instance.currentUser!.uid, onLogout: () {}),
    const RetailerAlertsPage(),
  ];

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_currentIndex])),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Orders'),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Account',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none),
            label: 'Alerts',
          ),
        ],
      ),
    );
  }
}
