import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_mart/modules/main_screen.dart';
import 'package:local_mart/modules/wholesaler/pages/wholesaler_dashboard_page.dart';
import 'package:local_mart/modules/retailer/pages/retailer_dashboard_page.dart';
import 'package:local_mart/modules/login/screens/login_screen.dart';

class SplashScreen extends StatefulWidget {
  static const String routeName = '/';

  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkUserAndNavigate();
  }

  Future<void> _checkUserAndNavigate() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // No user logged in, navigate to login screen
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
      }
      return;
    }

    // User is logged in, fetch their role
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

    if (!userDoc.exists || userDoc.data() == null) {
      // User document not found or data is null, navigate to login
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
      }
      return;
    }

    final role = userDoc.data()!['role'];

    if (!mounted) return;

    switch (role) {
      case 'Customer':
        Navigator.of(context).pushReplacementNamed(MainScreen.routeName);
        break;
      case 'Wholesaler':
        Navigator.of(context).pushReplacementNamed(WholesalerDashboardPage.routeName);
        break;
      case 'Retailer':
        Navigator.of(context).pushReplacementNamed(RetailerDashboardPage.routeName);
        break;
      default:
        // Unknown role, navigate to login
        Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}