// lib/modules/search_page/search_page.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/product.dart';
import '../products_page/product_details.dart';
import '../../utils/distance.dart';
import '../../utils/image_utils.dart' as imgutils;

import '../../widgets/app_scaffold.dart';
import '../main_screen.dart';
import '../../widgets/star_rating.dart';



class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  List<Map<String, dynamic>> searchResults = [];
  bool isLoading = false;

  // filter state
  bool onlyInStock = false;
  double? priceMin;
  double? priceMax;
  double? distanceMaxKm;

  // sort state: 'relevance' | 'price' | 'distance' | 'rating'
  String sortBy = 'relevance';

  bool get filtersActive =>
      onlyInStock ||
          priceMin != null ||
          priceMax != null ||
          distanceMaxKm != null ||
          sortBy != 'relevance';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      final q = _searchController.text.trim();
      if (q.isEmpty) {
        setState(() => searchResults.clear());
      } else {
        searchProducts(q);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<List<String>> _getAllCategories() async {
    final firestore = FirebaseFirestore.instance;
    final docSnapshot = await firestore
        .collection('products')
        .doc('Categories')
        .get();
    if (docSnapshot.exists) {
      final data = docSnapshot.data();
      if (data != null && data['categoriesList'] != null) {
        return List<String>.from(data['categoriesList']);
      }
    }
    return [];
  }

  Future<Map<String, dynamic>?> _getCurrentUserAddress() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final doc = await FirebaseFirestore.instance.collection('users').doc(
        user.uid).get();
    if (!doc.exists) return null;
    return doc.data()?['address'] as Map<String, dynamic>?;
  }

  Future<void> searchProducts(String query) async {
    final lowercaseQuery = query.trim().toLowerCase();
    if (lowercaseQuery.isEmpty) {
      setState(() => searchResults.clear());
      return;
    }

    setState(() {
      isLoading = true;
      searchResults.clear();
    });

    final firestore = FirebaseFirestore.instance;
    final categories = await _getAllCategories();
    final userAddr = await _getCurrentUserAddress();
    double? userLat, userLng;
    if (userAddr != null) {
      userLat = (userAddr['lat'] as num?)?.toDouble();
      userLng = (userAddr['lng'] as num?)?.toDouble();
    }

    for (String category in categories) {
      final snapshot = await firestore
          .collection('products')
          .doc('Categories')
          .collection(category)
          .get();
      for (var doc in snapshot.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        final productName = (data['name'] ?? '').toString().toLowerCase();
        final words = productName.split(' ');
        if (!(productName.contains(lowercaseQuery) ||
            words.any((word) =>
            word.contains(lowercaseQuery) || lowercaseQuery.contains(word)))) {
          continue;
        }

        // stock filter
        final stockRaw = data['stock'] ?? 0;
        final stock = (stockRaw is num) ? stockRaw.toInt() : int.tryParse(
            stockRaw.toString()) ?? 0;
        if (onlyInStock && stock <= 0) continue;

        // price filter
        final priceRaw = data['price'] ?? 0;
        final priceVal = (priceRaw is num) ? priceRaw.toDouble() : double
            .tryParse(priceRaw.toString()) ?? 0.0;
        if (priceMin != null && priceVal < priceMin!) continue;
        if (priceMax != null && priceVal > priceMax!) continue;

        // compute distance if possible
        double? distKm;
        final sellerId = (data['sellerId'] ?? '').toString();
        if (userLat != null && userLng != null && sellerId.isNotEmpty) {
          try {
            final sellerDoc = await firestore
                .collection('users')
                .doc(sellerId)
                .get();
            final sellerAddr = sellerDoc.data()?['address'];
            if (sellerAddr != null && sellerAddr['lat'] != null &&
                sellerAddr['lng'] != null) {
              final sLat = (sellerAddr['lat'] as num).toDouble();
              final sLng = (sellerAddr['lng'] as num).toDouble();
              distKm = distanceKm(
                  lat1: userLat, lng1: userLng, lat2: sLat, lng2: sLng);
            }
          } catch (_) {
            // ignore distance failure
          }
        }

        if (distanceMaxKm != null && distKm != null && distKm > distanceMaxKm!)
          continue;

        // compute avgRating from subcollection only if not present already
        // if product doc already had avgRating, use it; otherwise compute
        if (data['avgRating'] == null) {
          try {
            final rSnap = await doc.reference.collection('Rating').get();
            if (rSnap.docs.isNotEmpty) {
              double total = 0;
              for (var r in rSnap.docs) {
                final val = r.data()['rating'] ?? r.data()['Rating'] ?? 0;
                total += (val is num) ? val.toDouble() : double.tryParse(
                    val.toString()) ?? 0.0;
              }
              data['avgRating'] = total / rSnap.docs.length;
            } else {
              data['avgRating'] = 0.0;
            }
          } catch (_) {
            data['avgRating'] = 0.0;
          }
        }

        data['__category'] = category;
        data['__docId'] = doc.id;
        if (distKm != null) data['__distanceKm'] = distKm;
        searchResults.add(data);
      }
    }

    // Apply sorting
    if (sortBy == 'price') {
      searchResults.sort((a, b) {
        final pa = ((a['price'] ?? 0) as num).toDouble();
        final pb = ((b['price'] ?? 0) as num).toDouble();
        return pa.compareTo(pb);
      });
    } else if (sortBy == 'distance') {
      // ensure distance computed for all items (if possible)
      // items without distance will be sorted to the end (large number)
      searchResults.sort((a, b) {
        final da = (a['__distanceKm'] ?? double.infinity) as double;
        final db = (b['__distanceKm'] ?? double.infinity) as double;
        return da.compareTo(db);
      });
    } else if (sortBy == 'rating') {
      searchResults.sort((b, a) {
        final ra = ((a['avgRating'] ?? 0) as num).toDouble();
        final rb = ((b['avgRating'] ?? 0) as num).toDouble();
        return ra.compareTo(rb);
      });
    } else {
      // if distanceMaxKm specified and user wants default sort, we still sort by distance ascending
      if (distanceMaxKm != null) {
        searchResults.sort((a, b) {
          final da = (a['__distanceKm'] ?? double.infinity) as double;
          final db = (b['__distanceKm'] ?? double.infinity) as double;
          return da.compareTo(db);
        });
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  void _openFilterDialog() async {
    // local temporary vars
    bool tmpOnlyStock = onlyInStock;
    double? tmpMin = priceMin;
    double? tmpMax = priceMax;
    double? tmpDist = distanceMaxKm;
    String tmpSort = sortBy;

    final minCtrl = TextEditingController(
        text: tmpMin?.toStringAsFixed(0) ?? '');
    final maxCtrl = TextEditingController(
        text: tmpMax?.toStringAsFixed(0) ?? '');
    final distCtrl = TextEditingController(
        text: tmpDist?.toStringAsFixed(0) ?? '');

    await showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18)),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                colors: [Color(0xFF7FECEC), Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header row with Clear
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filters',
                        style: Theme
                            .of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // Clear all filters
                          Navigator.pop(ctx);
                          setState(() {
                            onlyInStock = false;
                            priceMin = null;
                            priceMax = null;
                            distanceMaxKm = null;
                            sortBy = 'relevance';
                          });
                          final q = _searchController.text.trim();
                          if (q.isNotEmpty) searchProducts(q);
                        },
                        child: Text(
                          'Clear',
                          style: TextStyle(
                            color: Theme
                                .of(context)
                                .primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: tmpOnlyStock,
                    onChanged: (v) => setState(() => tmpOnlyStock = v),
                    title: const Text('Only show in-stock items'),
                    activeThumbColor: Theme
                        .of(context)
                        .primaryColor,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: minCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Min price (₹)'),
                    onChanged: (v) =>
                    tmpMin = v
                        .trim()
                        .isEmpty ? null : double.tryParse(v),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: maxCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Max price (₹)'),
                    onChanged: (v) =>
                    tmpMax = v
                        .trim()
                        .isEmpty ? null : double.tryParse(v),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: distCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Max distance (km)'),
                    onChanged: (v) =>
                    tmpDist = v
                        .trim()
                        .isEmpty ? null : double.tryParse(v),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: tmpSort,
                    decoration: const InputDecoration(labelText: 'Sort by'),
                    items: const [
                      DropdownMenuItem(
                          value: 'relevance', child: Text('Relevance')),
                      DropdownMenuItem(
                          value: 'price', child: Text('Price (Low → High)')),
                      DropdownMenuItem(value: 'distance',
                          child: Text('Distance (Nearest First)')),
                      DropdownMenuItem(value: 'rating',
                          child: Text('Rating (Highest First)')),
                    ],
                    onChanged: (val) => tmpSort = val ?? 'relevance',
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Cancel')),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            onlyInStock = tmpOnlyStock;
                            priceMin = tmpMin;
                            priceMax = tmpMax;
                            distanceMaxKm = tmpDist;
                            sortBy = tmpSort;
                          });
                          Navigator.of(ctx).pop();
                          final q = _searchController.text.trim();
                          if (q.isNotEmpty) searchProducts(q);
                        },
                        child: const Text('Apply'),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResultTile(Map<String, dynamic> p) {
    final imgStr = (p['image'] ?? p['Image'] ?? '') as String;
    final imgBytes = imgStr.isNotEmpty
        ? imgutils.decodeImageDataDynamic(imgStr)
        : null;
    final price = p['price'] ?? p['Price'] ?? 0;
    final name = p['name'] ?? 'Unnamed Product';
    final desc = p['Description'] ?? p['description'] ?? '';
    final distanceKmVal = p['__distanceKm'] as double?;
    final rating = ((p['avgRating'] ?? 0) as num).toDouble();

    final productModel = Product(
      id: p['__docId'] ?? '',
      name: name,
      description: desc,
      image: imgStr,
      price: (price is num) ? price.toInt() : int.tryParse(price.toString()) ??
          0,
      stock: (p['stock'] ?? 0) is int
          ? (p['stock'] ?? 0)
          : int.tryParse((p['stock'] ?? 0).toString()) ?? 0,
      sellerId: p['sellerId'] ?? '',
      avgRating: rating,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1.2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 10),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: imgBytes != null && imgBytes.isNotEmpty
              ? Image.memory(imgBytes, width: 64, height: 64, fit: BoxFit.cover)
              : Container(
            width: 64,
            height: 64,
            color: Colors.grey.shade200,
            child: const Icon(Icons.image_not_supported, size: 28),
          ),
        ),
        title: Text(name, maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Row(
              children: [
                Text("₹${productModel.price}", style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(width: 10),
                if (rating > 0)
                  Row(children: [
                    buildStars(rating, size: 14),
                    const SizedBox(width: 6),
                    Text(rating.toStringAsFixed(1), style: const TextStyle(
                        fontSize: 12, color: Colors.black54)),
                  ]),
              ],
            ),
            if (distanceKmVal != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14,
                        color: Color(0xFF00A693)),
                    const SizedBox(width: 4),
                    Text("${distanceKmVal.toStringAsFixed(1)} km away",
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54)),
                  ],
                ),
              ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ProductDetailsPage(product: productModel)),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Search',
      currentIndex: 0, // highlight "Home"
      onNavTap: (idx) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => MainScreen(initialIndex: idx)),
        );
      },
      body: Column(
        children: [
          // AppBar replica — since AppScaffold provides its own structure
          Material(
            elevation: 1,
            color: Colors.white,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(left: 8, right: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: "Search for products...",
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 2.0),
                      child: IconButton(
                        icon: Icon(
                          Icons.filter_list,
                          color: filtersActive
                              ? Theme
                              .of(context)
                              .primaryColor
                              : Colors.black54,
                          shadows: filtersActive
                              ? [
                            Shadow(
                              color: Theme
                                  .of(context)
                                  .primaryColor
                                  .withValues(alpha: 0.8),
                              blurRadius: 8,
                            ),
                          ]
                              : null,
                        ),
                        onPressed: _openFilterDialog,
                        tooltip: 'Filters',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Active filters chip
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: filtersActive
                ? Padding(
              key: const ValueKey('filters_chip'),
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: _openFilterDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00A693), Color(0xFF7FECEC)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Theme
                              .of(context)
                              .primaryColor
                              .withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.filter_alt,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 6),
                        const Text(
                          'Filters active',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_drop_down,
                            color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
            )
                : const SizedBox.shrink(key: ValueKey('no_filters')),
          ),

          // content
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : searchResults.isEmpty
                ? const Center(child: Text("No results found"))
                : ListView.builder(
              padding: const EdgeInsets.only(bottom: 12, top: 6),
              itemCount: searchResults.length,
              itemBuilder: (context, index) =>
                  _buildResultTile(searchResults[index]),
            ),
          ),
        ],
      ),
    );
  }
}