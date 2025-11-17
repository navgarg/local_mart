// lib/modules/products_page/product_details.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/product.dart';
import 'package:provider/provider.dart';
import '../customer_order/models/order_model.dart';
import '../customer_order/providers/cart_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../utils/image_utils.dart' as imgutils;
import '../../utils/distance.dart';
import '../main_screen.dart';
import '../../widgets/star_rating.dart';

class ProductDetailsPage extends StatefulWidget {
  final Product product;
  final int fromIndex;
  const ProductDetailsPage({
    super.key,
    required this.product,
    this.fromIndex = 0,
  });

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage>
    with TickerProviderStateMixin {
  String sellerName = '';
  double? distanceKmVal;
  String deliverByString = '';
  List<Map<String, dynamic>> reviews = [];
  bool _reviewsExpanded = false;
  DocumentReference? _productDocRef;
  bool _savingReview = false;
  String? currentUserId;
  double? _accurateRating; // new field

  @override
  void initState() {
    super.initState();
    _initPage();
  }

  Future<void> _initPage() async {
    final user = FirebaseAuth.instance.currentUser;
    currentUserId = user?.uid;
    await _fetchSellerName();
    await _findProductDoc();
    await _computeDistanceAndDelivery();
    await _loadReviews();

    //  Fetch latest average rating
    final updatedRating = await _fetchAverageRating();
    if (mounted) setState(() => _accurateRating = updatedRating);
  }

  ///  Fetch accurate average rating directly from Firestore
  Future<double> _fetchAverageRating() async {
    try {
      final catDoc = FirebaseFirestore.instance
          .collection('products')
          .doc('Categories');
      final categoriesDoc = await catDoc.get();
      if (!categoriesDoc.exists) return widget.product.avgRating;

      final cats =
          categoriesDoc.data()?['categoriesList'] as List<dynamic>? ?? [];

      for (final c in cats) {
        final ratingCollection = catDoc
            .collection(c.toString())
            .doc(widget.product.id)
            .collection('Rating');

        final snap = await ratingCollection.get();
        if (snap.docs.isNotEmpty) {
          double total = 0;
          for (var r in snap.docs) {
            final v = r.data()['rating'] ?? r.data()['Rating'] ?? 0;
            total += (v is num
                ? v.toDouble()
                : double.tryParse(v.toString()) ?? 0.0);
          }
          return total / snap.docs.length;
        }
      }
      return widget.product.avgRating;
    } catch (e) {
      debugPrint('⚠️ Error fetching avg rating: $e');
      return widget.product.avgRating;
    }
  }

  Future<void> _fetchSellerName() async {
    try {
      final id = widget.product.sellerId;
      if (id.isEmpty) return;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(id)
          .get();
      if (doc.exists) {
        final data = doc.data();
        if (mounted) {
          setState(() {
            sellerName = (data?['username'] ?? '') as String;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _findProductDoc() async {
    try {
      final catDoc = FirebaseFirestore.instance
          .collection('products')
          .doc('Categories');
      final categoriesDoc = await catDoc.get();
      if (!categoriesDoc.exists) return;
      final cats =
          categoriesDoc.data()?['categoriesList'] as List<dynamic>? ?? [];
      for (final c in cats) {
        final col = catDoc.collection(c.toString());
        final pd = await col.doc(widget.product.id).get();
        if (pd.exists) {
          _productDocRef = pd.reference;
          return;
        }
      }
    } catch (_) {}
  }

  Future<void> _computeDistanceAndDelivery() async {
    try {
      final current = FirebaseAuth.instance.currentUser;
      if (current == null) return;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(current.uid)
          .get();
      final userAddr = userDoc.data()?['address'];
      final sellerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.product.sellerId)
          .get();
      final sellerAddr = sellerDoc.data()?['address'];
      if (userAddr != null && sellerAddr != null) {
        final uLat = (userAddr['lat'] ?? 0).toDouble();
        final uLng = (userAddr['lng'] ?? 0).toDouble();
        final sLat = (sellerAddr['lat'] ?? 0).toDouble();
        final sLng = (sellerAddr['lng'] ?? 0).toDouble();
        final km = distanceKm(lat1: uLat, lng1: uLng, lat2: sLat, lng2: sLng);
        if (mounted) {
          setState(() {
            distanceKmVal = km;
            deliverByString = _deliverByStringFromDistance(km);
          });
        }
      }
    } catch (_) {}
  }

  String _deliverByStringFromDistance(double km) {
    final now = DateTime.now();
    int addDays;
    if (km <= 5)
      addDays = 1;
    else if (km <= 200)
      addDays = 2;
    else if (km <= 800)
      addDays = 3;
    else if (km <= 1000)
      addDays = 4;
    else if (km <= 2000)
      addDays = 5;
    else
      addDays = 7;
    final d = now.add(Duration(days: addDays));
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final weekday = names[(d.weekday - 1) % 7];
    return "Expected by: $weekday, ${d.day} ${months[d.month - 1]} ${d.year}";
  }

  Future<void> _loadReviews() async {
    final tmp = <Map<String, dynamic>>[];
    try {
      if (_productDocRef == null) await _findProductDoc();
      if (_productDocRef == null) {
        if (mounted) setState(() => reviews = tmp);
        return;
      }
      final ratingSnap = await _productDocRef!.collection('Rating').get();
      for (final r in ratingSnap.docs) {
        final rd = r.data();
        final customerId = r.id;
        String username = 'User';
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(customerId)
              .get();
          if (userDoc.exists)
            username = (userDoc.data()?['username'] ?? 'User') as String;
        } catch (_) {}
        tmp.add({
          'id': customerId,
          'username': username,
          'rating': (rd['rating'] ?? rd['Rating'] ?? 0),
          'review': rd['review'] ?? rd['Review'] ?? '',
        });
      }
    } catch (_) {}
    if (mounted) setState(() => reviews = tmp);
  }

  Future<void> _deleteReview(String id) async {
    if (_productDocRef == null) return;
    await _productDocRef!.collection('Rating').doc(id).delete();
    await _loadReviews();
    if (mounted)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Review deleted")));
  }

  Future<void> _submitReview(int rating, String reviewText) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login to write a review.")),
      );
      return;
    }
    if (_productDocRef == null) {
      await _findProductDoc();
      if (_productDocRef == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Product document not found.")),
        );
        return;
      }
    }
    if (mounted) setState(() => _savingReview = true);
    try {
      final rRef = _productDocRef!.collection('Rating').doc(user.uid);
      await rRef.set({
        'rating': rating,
        'review': reviewText.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });
      await _loadReviews();

      // refresh average rating after new review
      final updatedRating = await _fetchAverageRating();
      if (mounted) setState(() => _accurateRating = updatedRating);

      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Review submitted!")));
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Failed to save review.")));
    } finally {
      if (mounted) setState(() => _savingReview = false);
    }
  }

  Future<void> _showWriteReviewDialog({
    int? existingRating,
    String? existingText,
  }) async {
    int rating = existingRating ?? 5;
    final ctrl = TextEditingController(text: existingText ?? "");
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Write a review"),
          content: StatefulBuilder(
            builder: (c, setSt) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final idx = i + 1;
                      return IconButton(
                        icon: Icon(
                          idx <= rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                        ),
                        onPressed: () => setSt(() => rating = idx),
                      );
                    }),
                  ),
                  TextField(
                    controller: ctrl,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: "Write your review",
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _submitReview(rating, ctrl.text);
              },
              child: const Text("Submit"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final imgBytes = widget.product.image.isNotEmpty
        ? imgutils.decodeImageDataDynamic(widget.product.image)
        : null;

    return AppScaffold(
      title: widget.product.name,
      currentIndex: widget.fromIndex,
      onNavTap: (idx) => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MainScreen(initialIndex: idx)),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F2FD), Color(0xFFFFFFFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (imgBytes != null && imgBytes.isNotEmpty)
                      Center(
                        child: Image.memory(
                          imgBytes,
                          height: 240,
                          fit: BoxFit.contain,
                        ),
                      )
                    else
                      Container(
                        height: 240,
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(Icons.image_not_supported, size: 60),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      widget.product.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          "₹${widget.product.price}",
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 10),
                        buildStars(
                          _accurateRating ?? widget.product.avgRating,
                          size: 18,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (widget.product.description.isNotEmpty)
                      Text(
                        widget.product.description,
                        style: const TextStyle(fontSize: 17),
                      )
                    else
                      const SizedBox.shrink(),
                    const SizedBox(height: 10),
                    _infoRow(
                      Icons.inventory_2_outlined,
                      "Stock",
                      "${widget.product.stock}",
                    ),
                    const SizedBox(height: 5),
                    _infoRow(
                      Icons.store_outlined,
                      "Sold by",
                      sellerName.isNotEmpty ? sellerName : "Unknown Seller",
                    ),
                    const SizedBox(height: 5),
                    if (distanceKmVal != null)
                      _infoRow(
                        Icons.location_on_outlined,
                        "Distance",
                        "${distanceKmVal!.toStringAsFixed(2)} km",
                      ),
                    const SizedBox(height: 5),
                    if (deliverByString.isNotEmpty)
                      _infoRow(
                        Icons.local_shipping_outlined,
                        "Delivery",
                        deliverByString,
                      ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () =>
                          setState(() => _reviewsExpanded = !_reviewsExpanded),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Reviews & Ratings (${reviews.length})",
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                _reviewsExpanded ? "Hide" : "Show",
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              Icon(
                                _reviewsExpanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                color: Theme.of(context).primaryColor,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: ConstrainedBox(
                        constraints: _reviewsExpanded
                            ? const BoxConstraints()
                            : const BoxConstraints(maxHeight: 0),
                        child: _buildReviewsList(),
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
            _bottomActionBar(context),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade700),
        const SizedBox(width: 6),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black87, fontSize: 16),
              children: [
                TextSpan(
                  text: "$label: ",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsList() {
    if (reviews.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('No reviews yet', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 6),
          _writeReviewButton(),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reviews.length,
          separatorBuilder: (_, __) => const Divider(height: 8),
          itemBuilder: (context, idx) {
            final r = reviews[idx];
            final rRating = (r['rating'] ?? 0);
            final username = r['username'] ?? 'User';
            final reviewText = r['review'] ?? '';
            final isOwn = currentUserId != null && r['id'] == currentUserId;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        username,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      if (isOwn)
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                size: 18,
                                color: Colors.blueGrey,
                              ),
                              onPressed: () => _showWriteReviewDialog(
                                existingRating: rRating,
                                existingText: reviewText,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                size: 18,
                                color: Colors.redAccent,
                              ),
                              onPressed: () => _deleteReview(r['id']),
                            ),
                          ],
                        ),
                    ],
                  ),
                  Row(
                    children: List.generate(5, (i) {
                      final filled =
                          i <
                          (rRating is num
                              ? rRating.toInt()
                              : int.tryParse(rRating.toString()) ?? 0);
                      return Icon(
                        filled ? Icons.star : Icons.star_border,
                        size: 13,
                        color: Colors.amber,
                      );
                    }),
                  ),
                  if (reviewText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        reviewText,
                        style: const TextStyle(fontSize: 13.5),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        _writeReviewButton(),
      ],
    );
  }

  Widget _writeReviewButton() {
    return ElevatedButton.icon(
      onPressed: _showWriteReviewDialog,
      icon: const Icon(Icons.edit, size: 18, color: Colors.black),
      label: const Text(
        'Write a review',
        style: TextStyle(color: Colors.black, fontSize: 15),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey.shade100,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }

  Widget _bottomActionBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  final cart = Provider.of<CartProvider>(
                    context,
                    listen: false,
                  );
                  final productPath =
                      'products/Categories/${widget.product.extraData?['category'] ?? 'unknown'}/${widget.product.id}';
                  await cart.fetchStock(widget.product.id, productPath);

                  cart.addItem(
                    OrderItem(
                      productId: widget.product.id,
                      name: widget.product.name,
                      price: widget.product.price.toDouble(),
                      quantity: 1,
                      sellerId: widget.product.sellerId,
                      image: widget.product.image,
                      productPath: productPath,
                    ),
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${widget.product.name} added to cart'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                child: const Text("Add to Cart"),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                onPressed: () => ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("Buy Now"))),
                child: const Text("Buy Now"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
