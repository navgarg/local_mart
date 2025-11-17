// lib/main.dart
import 'package:cloud_firestore/cloud_firestore.dart';
// Firebase Auth & Firestore (if you need them later)
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:local_mart/modules/customer_order/pages/cart_page.dart';
import 'package:local_mart/modules/customer_order/pages/checkout_page.dart';
import 'package:local_mart/modules/customer_order/pages/delivery_tracking_page.dart';
import 'package:local_mart/modules/customer_order/pages/pickup_tracking_page.dart';
// ---------- CUSTOMER ORDER MODULE (Friend's Code) ----------
import 'package:local_mart/modules/customer_order/providers/cart_provider.dart';
import 'package:local_mart/modules/customer_order/providers/order_provider.dart';
import 'package:local_mart/modules/login/screens/address_details_screen.dart';
import 'package:local_mart/modules/login/screens/age_question_screen.dart';
import 'package:local_mart/modules/login/screens/buisness_details_screen.dart';
import 'package:local_mart/modules/login/screens/forgot_password_screen.dart';
import 'package:local_mart/modules/login/screens/gender_question_screen.dart';
// ---------- LOGIN / SIGNUP MODULE (Your Code) ----------
import 'package:local_mart/modules/login/screens/login_screen.dart';
import 'package:local_mart/modules/login/screens/map_location_picker_screen.dart';
import 'package:local_mart/modules/login/screens/mobile_details_screen.dart';
import 'package:local_mart/modules/login/screens/otp_verification_screen.dart';
import 'package:local_mart/modules/login/screens/password_updated_screen.dart';
import 'package:local_mart/modules/login/screens/reset_password_screen.dart';
import 'package:local_mart/modules/login/screens/role_selection.dart';
import 'package:local_mart/modules/login/screens/signup_screen.dart';
import 'package:local_mart/modules/login/screens/verify_reset_otp_screen.dart';
import 'package:local_mart/theme.dart';
import 'package:provider/provider.dart';

// Firebase options
import 'firebase_options.dart';
import 'modules/main_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env before initializing Firebase
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 🚫 All temp login code removed (clean production setup)

  runApp(const MyApp());
}

/// Temporary auto-login (keep only for dev; remove for production)
Future<void> initTestUser() async {
  final auth = FirebaseAuth.instance;
  const testEmail = 'testuser@gmail.com';
  const testPassword = '123456';

  try {
    // Try sign in
    await auth.signInWithEmailAndPassword(
      email: testEmail,
      password: testPassword,
    );
  } catch (e) {
    // If sign-in fails, create the user
    try {
      final cred = await auth.createUserWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      );
      final userDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid);
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
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(current.uid);
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
    final themeData = AppTheme.lightTheme;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'LocalMart',

        // Apply your global theme
        theme: themeData,

        // App starts at your login screen
        initialRoute: '/login',

        routes: {
          // ---------- LOGIN SYSTEM ROUTES ----------
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignUpScreen(),
          '/verify': (context) => const OtpVerificationScreen(),
          '/forgot': (context) => const ForgotPasswordScreen(),
          '/forgot-verify': (context) => const VerifyResetOtpScreen(),
          '/reset-password': (context) => const ResetPasswordScreen(),
          '/password-updated': (context) => const PasswordUpdatedScreen(),
          '/role-selection': (context) => const RoleSelectionScreen(),
          '/mobile-details': (context) => const MobileDetailsScreen(),
          '/gender-question': (context) => const GenderQuestionScreen(),
          '/age-question': (context) => const AgeQuestionScreen(),
          '/map-location': (context) => const MapLocationPickerScreen(),
          '/address-details': (context) => const AddressDetailsScreen(),
          '/business-details': (context) => const BusinessDetailsScreen(),

          // ---------- CUSTOMER ORDER ROUTES ----------
          // '/products': (_) => const ProductsPage(),
          '/cart': (_) => const CartPage(),
          '/checkout': (_) => const CheckoutPage(),

          '/home': (ctx) => const MainScreen(),
          '/map-picker': (ctx) => const MapLocationPickerScreen(),
        },

        // Pages that require arguments
        onGenerateRoute: (settings) {
          if (settings.name == '/delivery_tracking') {
            final orderId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (_) => DeliveryTrackingPage(orderId: orderId),
            );
          }

          if (settings.name == '/pickup_tracking') {
            final orderId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (_) => PickupTrackingPage(orderId: orderId),
            );
          }

          return null;
        },
      ),
    );
  }
}
