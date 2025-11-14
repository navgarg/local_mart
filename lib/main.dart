// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme.dart';
import 'modules/main_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'modules/address/address_details_screen.dart';
import 'modules/address/map_location_picker_screen.dart';

import 'modules/home_screen/home_screen.dart'; // optional
import 'modules/search_page/search_page.dart'; // optional

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize a temporary test user for dev / testing
  await initTestUser();

  runApp(const MyApp());
}

/// Temporary auto-login (keep only for dev; remove for production)
Future<void> initTestUser() async {
  final auth = FirebaseAuth.instance;
  const testEmail = 'testuser@gmail.com';
  const testPassword = '123456';

  try {
    // Try sign in
    await auth.signInWithEmailAndPassword(email: testEmail, password: testPassword);
  } catch (e) {
    // If sign-in fails, create the user
    try {
      final cred = await auth.createUserWithEmailAndPassword(email: testEmail, password: testPassword);
      final userDoc = FirebaseFirestore.instance.collection('users').doc(cred.user!.uid);
      await userDoc.set({
        "username": "Test User",
        "mobile": "9999999999",
        "address": {
          "flatNo": "101/A",
          "building": "Test Building",
          "area": "Test Colony",
          "city": "Mumbai",
          "state": "MH",
          "pincode": "400001",
          "lat": 19.0760,
          "lng": 72.8777,
        },
        "role": "Customer",
        "timestamp": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e2) {
      // ignore for now; log if you want
      // print('Temp user creation failed: $e2');
    }
  }

  // Ensure Firestore document exists in case sign-in succeeded but doc missing
  final current = auth.currentUser;
  if (current != null) {
    final docRef = FirebaseFirestore.instance.collection('users').doc(current.uid);
    final doc = await docRef.get();
    if (!doc.exists) {
      await docRef.set({
        "username": "Test User",
        "mobile": "9999999999",
        "address": {
          "flatNo": "101/A",
          "building": "Test Building",
          "area": "Test Colony",
          "city": "Mumbai",
          "state": "MH",
          "pincode": "400001",
          "lat": 19.0760,
          "lng": 72.8777,
        },
        "role": "Customer",
        "timestamp": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LocalMart',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const MainScreen(),
      // Add named routes used by address & map pickers
      routes: {
        '/home': (ctx) => const MainScreen(),
        '/address-details': (ctx) => const AddressDetailsScreen(), // wrapper route — see note
        '/map-picker': (ctx) => const MapLocationPickerScreen(),
      },
    );
  }
}

