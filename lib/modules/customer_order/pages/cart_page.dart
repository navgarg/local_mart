import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:local_mart/theme.dart';
import 'package:provider/provider.dart';

import '../pages/checkout_page.dart';
import '../providers/cart_provider.dart';
import '../widgets/cart_item_widget.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  bool _isLoadingEstimates = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchEtas());
  }

  // --------------------------------------------------------------------------
  //  Fetch ETA based on user location
  // --------------------------------------------------------------------------
  Future<void> _fetchEtas() async {
    final cart = Provider.of<CartProvider>(context, listen: false);
    if (cart.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!snap.exists) return;

      final address = snap.data()!['address'];
      final customerLat = (address['lat'] ?? 0).toDouble();
      final customerLng = (address['lng'] ?? 0).toDouble();

      // Skip ETA if coordinates are missing
      if (customerLat == null || customerLng == null) return;

      setState(() => _isLoadingEstimates = true);
      await cart.fetchEtas(customerLat: customerLat, customerLng: customerLng);
      setState(() {});
    } catch (e) {
      debugPrint('Error loading address or ETA: $e');
    } finally {
      setState(() => _isLoadingEstimates = false);
    }
  }

  // --------------------------------------------------------------------------
  // Fetch seller name from Firestore (users collection)
  // --------------------------------------------------------------------------
  Future<String> _getSellerName(String sellerId) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(sellerId)
          .get();

      if (snap.exists) {
        final data = snap.data();
        return data?['username'] ?? 'Retailer';
      } else {
        return 'Unknown Retailer';
      }
    } catch (e) {
      debugPrint('Error fetching seller name: $e');
      return 'Unknown Retailer';
    }
  }

  // --------------------------------------------------------------------------
  //  UI
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Cart',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: cart.isEmpty
          ? _buildEmptyCart(theme, context)
          : Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchEtas,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 8),
                        ...cart.groupedByRetailer().entries.map((entry) {
                          final sellerId = entry.key;
                          final items = entry.value;
                          final sellerEta =
                              cart.perRetailerEstimates[sellerId] ??
                              'Calculating ETA...';

                          return Padding(
                            padding: const EdgeInsets.only(
                              left: 12,
                              right: 12,
                              bottom: 16,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 🏪 Seller header
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.storefront,
                                        size: 18,
                                        color: Colors.black54,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: FutureBuilder<String>(
                                          future: _getSellerName(sellerId),
                                          builder: (context, snapshot) {
                                            final name =
                                                snapshot.data ?? 'Loading...';
                                            return Text(
                                              name,
                                              style: theme.textTheme.titleSmall
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                              overflow: TextOverflow.ellipsis,
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.local_shipping,
                                            size: 14,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            sellerEta,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: Colors.grey[600],
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 6),
                                ...items.map((item) {
                                  final cart = Provider.of<CartProvider>(
                                    context,
                                    listen: false,
                                  );
                                  cart.fetchStock(
                                    item.productId,
                                    item.productPath,
                                  );
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: CartItemWidget(item: item),
                                  );
                                }),
                              ],
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),

                // ---------------- Summary section ----------------
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isLoadingEstimates)
                        Text(
                          'Calculating estimated delivery...',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                        )
                      else
                        Text(
                          'Overall delivery estimate: ${cart.overallEstimate}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      const SizedBox(height: 12),

                      _buildBillRow('Subtotal', cart.total),
                      _buildBillRow('GST (5%)', cart.gst),
                      _buildBillRow('Convenience fee', cart.convenienceFee),

                      const Divider(height: 16, thickness: 1),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Final Total',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '₹${cart.finalTotal.toStringAsFixed(2)}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: cart.isEmpty
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const CheckoutPage(),
                                    ),
                                  );
                                },
                          style: Theme.of(context).elevatedButtonTheme.style,
                          // style: ElevatedButton.styleFrom(
                          //   padding: const EdgeInsets.symmetric(horizontal: 18),
                          //   shape: RoundedRectangleBorder(
                          //     borderRadius: BorderRadius.circular(8),
                          //   ),
                          // ),
                          child: const Text('Proceed to Checkout'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildBillRow(String label, double value) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(fontSize: 14)),
      Text('₹${value.toStringAsFixed(2)}'),
    ],
  );

  // --------------------------------------------------------------------------
  // Empty cart fallback
  // --------------------------------------------------------------------------
  Widget _buildEmptyCart(ThemeData theme, BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            'Your cart is empty',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/inventory');
            },
            child: const Text('Browse Products'),
          ),
        ],
      ),
    );
  }
}
