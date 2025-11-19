import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_mart/modules/customer_order/models/order_model.dart';
import 'package:local_mart/modules/customer_order/providers/cart_provider.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import 'widgets/product_card.dart';
import 'product_details.dart';
import '../../widgets/app_scaffold.dart';
import '../main_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/distance.dart';

class ProductsPage extends StatefulWidget {
  final String category;
  const ProductsPage({super.key, required this.category});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  late Future<List<Product>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = _fetchProductsForCategory(widget.category);
  }

  Future<List<Product>> _fetchProductsForCategory(String category) async {
    final firestore = FirebaseFirestore.instance;
    final col = firestore
        .collection('products')
        .doc('Categories')
        .collection(category);
    final snapshot = await col.get();
    final products = <Product>[];

    // Get user's address first
    double? userLat, userLng;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await firestore.collection('users').doc(user.uid).get();
      final userAddr = userDoc.data()?['address'];
      if (userAddr != null) {
        userLat = (userAddr['lat'] ?? 0).toDouble();
        userLng = (userAddr['lng'] ?? 0).toDouble();
      }
    }

    // Compute ratings + distance for each product
    final futures = snapshot.docs.map((doc) async {
      final data = doc.data();
      double avgRating = 0;

      // Compute average rating
      final ratingSnapshot = await doc.reference.collection('Rating').get();
      if (ratingSnapshot.docs.isNotEmpty) {
        double total = 0;
        for (var r in ratingSnapshot.docs) {
          final val = r.data()['rating'] ?? r.data()['Rating'] ?? 0;
          total += (val is num)
              ? val.toDouble()
              : double.tryParse(val.toString()) ?? 0.0;
        }
        avgRating = total / ratingSnapshot.docs.length;
      }
      data['avgRating'] = avgRating;

      // Compute distance if seller address available
      if (userLat != null && userLng != null && data['sellerId'] != null) {
        try {
          final sellerDoc = await firestore
              .collection('users')
              .doc(data['sellerId'])
              .get();
          final sellerAddr = sellerDoc.data()?['address'];
          if (sellerAddr != null) {
            final sLat = (sellerAddr['lat'] ?? 0).toDouble();
            final sLng = (sellerAddr['lng'] ?? 0).toDouble();
            final km = distanceKm(
              lat1: userLat,
              lng1: userLng,
              lat2: sLat,
              lng2: sLng,
            );
            data['__distanceKm'] = km;
          }
        } catch (_) {}
      }

      data['category'] = category;
      return Product.fromFirestore(data, doc.id);
    }).toList();

    final resolved = await Future.wait(futures);
    products.addAll(resolved);
    return products;
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: widget.category,
      currentIndex: 0, // highlights Home tab
      onNavTap: (idx) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => MainScreen(initialIndex: idx)),
        );
      },
      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          } else if (snap.data == null || snap.data!.isEmpty) {
            return const Center(child: Text('No products found'));
          }

          final products = snap.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final p = products[index];
              return ProductCard(
                product: p,
                onAddToCart: () async {
                  Logger().i("Adding to cart: ${p.name}");
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  final cart = Provider.of<CartProvider>(
                    context,
                    listen: false,
                  );
                  final productPath =
                      'products/Categories/${p.extraData?['category']}/${p.id}';
                  await cart.fetchStock(p.id, productPath);
                  Logger().i(
                    "Current stock for ${p.name}: ${cart.getStock(p.id)}",
                  );

                  cart.addItem(
                    OrderItem(
                      productId: p.id,
                      name: p.name,
                      price: p.price.toDouble(),
                      quantity: 1,
                      sellerId: p.sellerId,
                      image: p.image,
                      productPath: productPath,
                      stock: cart.getStock(p.id),
                    ),
                  );
                  Logger().i("Added to cart: ${p.name}");
                  if (!mounted) return;
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('${p.name} added to cart'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                onBuyNow: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Buy Now pressed")),
                  );
                },
                onOpenDetails: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ProductDetailsPage(product: p, fromIndex: 0),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
