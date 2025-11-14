import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';



import 'firebase_options.dart';


// --- Providers ---
import 'package:local_mart/modules/customer_order/providers/cart_provider.dart';
import 'package:local_mart/modules/customer_order/providers/order_provider.dart';

// --- Pages ---
import 'package:local_mart/modules/customer_order/pages/product_page.dart';
import 'package:local_mart/modules/customer_order/pages/cart_page.dart';
import 'package:local_mart/modules/customer_order/pages/checkout_page.dart';
import 'package:local_mart/modules/customer_order/pages/delivery_tracking_page.dart';
import 'package:local_mart/modules/customer_order/pages/pickup_tracking_page.dart';

void main()
async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    final provider = OrderProvider();
    await provider.autoRefreshAllOrders(user.uid);
  }


  // ✅ TEMP AUTO LOGIN (REMOVE LATER)
  try {
    // Try signing in existing test user
    final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: "testuser@gmail.com",
      password: "123456",
    );


    // ✅ Ensure Firestore user document exists
    final userDoc = FirebaseFirestore.instance.collection("users").doc(cred.user!.uid);
    if (!(await userDoc.get()).exists) {
      await userDoc.set({
        "username": "Test User",
        "address": {
          "house": "101/A",
          "area": "Test Colony",
          "city": "Mumbai",
          "state": "MH",
          "pincode": "400001",
          "lat": 19.0760,
          "lng": 72.8777,
        },
      });
    }

  } catch (e) {
    // User doesn't exist → create + add Firestore profile
    final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: "testuser@gmail.com",
      password: "123456",
    );



    await FirebaseFirestore.instance.collection("users").doc(cred.user!.uid).set({
      "username": "Test User",
      "address": {
        "house": "101/A",
        "area": "Test Colony",
        "city": "Mumbai",
        "state": "MH",
        "pincode": "400001",
        "lat": 19.0760,
        "lng": 72.8777,
      },
    });
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()), // ✅ Added
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Local Mart',
        theme: ThemeData(useMaterial3: true),

        // ✅ Default Screen
        home: const ProductsPage(),

        // ✅ Routes
        routes: {
          '/cart': (_) => const CartPage(),
          '/checkout': (_) => const CheckoutPage(),
        },

        // ✅ For pages requiring arguments (tracking pages)
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


