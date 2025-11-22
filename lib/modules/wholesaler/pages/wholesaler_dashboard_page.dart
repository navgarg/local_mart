import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_mart/modules/wholesaler/services/wholesaler_service.dart';

import 'package:local_mart/modules/wholesaler/pages/wholesaler_orders_page.dart';

import 'package:local_mart/widgets/bottom_nav_bar.dart';
import 'package:local_mart/modules/wholesaler/pages/wholesaler_home_page.dart';
import 'package:local_mart/modules/wholesaler/pages/wholesaler_account_page.dart';
import 'package:local_mart/modules/wholesaler/pages/wholesaler_alerts_page.dart';
import 'package:local_mart/modules/wholesaler/pages/wholesaler_inventory_page.dart';

class WholesalerDashboardPage extends StatefulWidget {
  static const String routeName = '/wholesaler-dashboard';
  final String sellerId;
  const WholesalerDashboardPage({super.key, required this.sellerId});

  @override
  State<WholesalerDashboardPage> createState() =>
      _WholesalerDashboardPageState();
}

class _WholesalerDashboardPageState extends State<WholesalerDashboardPage> {
  int _currentIndex = 0;

  final List<String> _titles = const [
    'Wholesaler Home',
    'Orders',
    'Account',
    'Alerts',
    'Inventory',
  ];

  List<Widget> _pages(String sellerId) => [
    WholesalerHomePage(sellerId: sellerId, onNavigate: _onNavTap),
    WholesalerOrdersPage(sellerId: sellerId),
    WholesalerAccountPage(sellerId: sellerId),
    WholesalerAlertsPage(sellerId: sellerId),
    WholesalerInventoryPage(sellerId: sellerId),
  ];

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => WholesalerService(),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: true,
          title: Text(_titles[_currentIndex]),
        ),
        body: _pages(widget.sellerId)[_currentIndex],
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
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory),
              label: 'Inventory',
            ),
          ],
        ),
      ),
    );
  }
}
