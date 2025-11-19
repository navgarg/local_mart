// lib/modules/main_screen.dart
import 'package:flutter/material.dart';
import 'home_screen/home_screen.dart';

import 'account_page.dart';
import 'customer_order/pages/cart_page.dart';
import 'customer_order/pages/alerts_page.dart';
import '../widgets/app_scaffold.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;

  static final List<Widget> _pages = <Widget>[
    const HomeScreen(),
    const AccountPage(),
    const CartPage(),
    const AlertsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex; // sets the starting tab
  }

  void _onNavTap(int idx) {
    setState(() {
      _currentIndex = idx;
    });
  }

  @override
  Widget build(BuildContext context) {
    String title;
    switch (_currentIndex) {
      case 0:
        title = 'LocalMart';
        break;
      case 1:
        title = 'Account';
        break;
      case 2:
        title = 'My Cart';
        break;
      case 3:
        title = 'Alerts';
        break;
      default:
        title = 'LocalMart';
    }

    return AppScaffold(
      title: title,
      body: _pages[_currentIndex],
      currentIndex: _currentIndex,
      onNavTap: _onNavTap,
    );
  }
}
