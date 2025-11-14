import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/order_model.dart' as models;
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import 'package:local_mart/theme.dart';

extension DateDisplay on DateTime {
  String toDisplayString() =>
      "${day.toString().padLeft(2, '0')}-${month.toString().padLeft(2, '0')}-$year";
}

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  late Razorpay _razorpay;
  String _receivingMethod = 'delivery';
  String _paymentMethod = 'online';
  DateTime? _pickupDate;
  String? _userPhone;


  bool _isFetchingEta = false;
  bool _isPlacingOrder = false;
  bool _isLoadingAddress = true;

  models.Address? _userAddress;

  @override
  void initState() {
    super.initState();
    _initRazorpay();
    _loadUserAddress().then((_) => _fetchEtaIfNeeded());
  }

  void _initRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _loadUserAddress() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists || doc.data()?['address'] == null) {
        setState(() => _isLoadingAddress = false);
        return;
      }
      final data = doc.data()!;
      _userAddress = models.Address.fromJson(
        Map<String, dynamic>.from(doc.data()!['address']),
      );
      _userPhone = data['mobile']?.toString();
    } catch(_) {}
      setState(() => _isLoadingAddress = false);
  }

  Future<List<Map<String, dynamic>>> _loadPickupShops() async {
    final cart = Provider.of<CartProvider>(context, listen: false);

    final sellerIds = cart.items.map((e) => e.sellerId).toSet();

    List<Map<String, dynamic>> shops = [];

    for (String id in sellerIds) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(id)
          .get();
      if (!doc.exists || doc.data() == null) continue;

      final data = doc.data()!;
      shops.add({
        "name": data['username'] ?? "Retailer",
        "address": data['address'],
      });
    }

    return shops;
  }

  Future<void> _fetchEtaIfNeeded() async {
    if (_receivingMethod == 'pickup' || _userAddress == null) return;

    setState(() => _isFetchingEta = true);
    try {
      final cart = Provider.of<CartProvider>(context, listen: false);
      await cart.fetchEtas(
        customerLat: _userAddress!.lat,
        customerLng: _userAddress!.lng,
      );
    } finally {
      setState(() => _isFetchingEta = false);
    }
  }

  Future<void> _selectPickupDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 3)),
    );
    if (picked != null) setState(() => _pickupDate = picked);
  }

  Future<String> _createRazorpayOrder(int amount) async {
    final key = dotenv.env['RAZORPAY_KEY_ID'];
    final secret = dotenv.env['RAZORPAY_KEY_SECRET'];
    final auth = base64Encode(utf8.encode("$key:$secret"));

    final res = await http.post(
      Uri.parse("https://api.razorpay.com/v1/orders"),
      headers: {
        "Authorization": "Basic $auth",
        "Content-Type": "application/json"
      },
      body: jsonEncode({"amount": amount, "currency": "INR"}),
    );

    if (res.statusCode != 200) throw "Failed: ${res.body}";
    return jsonDecode(res.body)['id'];
  }

  void _handlePaymentSuccess(PaymentSuccessResponse r) =>
      _finalizeOrder(paymentId: r.paymentId);

  void _handlePaymentError(PaymentFailureResponse r) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: ${r.message ?? ""}')),
      );

  void _handleExternalWallet(ExternalWalletResponse r) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('External Wallet: ${r.walletName}')),
      );

  Future<void> _finalizeOrder({String? paymentId}) async {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || _userAddress == null) return;

    try {
      final orderId = await orderProvider.placeOrder(
        userId: user.uid,
        customerName: user.displayName ?? 'User',
        address: _userAddress!,
        items: cart.items,
        paymentMethod: _paymentMethod,
        receivingMethod: _receivingMethod,
        pickupDate: _pickupDate,
        cartProvider: cart,
        razorpayPaymentId: paymentId,
      );

      Navigator.pushReplacementNamed(
        context,
        _receivingMethod == 'delivery'
            ? '/delivery_tracking'
            : '/pickup_tracking',
        arguments: orderId,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order failed: $e')));
    }
  }

  Future<void> _placeOrder() async {
    if (_isPlacingOrder) return;
    setState(() => _isPlacingOrder = true);

    final cart = Provider.of<CartProvider>(context, listen: false);

    try {
      if (_receivingMethod == 'pickup') {
        _paymentMethod = 'online';
        if (_pickupDate == null) throw "Select pickup date";
      }

      if (_paymentMethod == 'online') {
        final amount = (cart.finalTotal * 100).toInt();
        final orderId = await _createRazorpayOrder(amount);
        final user = FirebaseAuth.instance.currentUser;

        _razorpay.open({
          'key': dotenv.env['RAZORPAY_KEY_ID'],
          'order_id': orderId,
          'amount': amount,
          'currency': 'INR',
          'name': 'LocalMart',
          'prefill': {
            'contact': _userPhone?? '',
            'email': user?.email ?? '',
          },
            'theme': {
              'color': '#3F51B5'
            }
        });
      } else {
        await _finalizeOrder();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order failed $e')));
    }

    setState(() => _isPlacingOrder = false);
  }

  Widget _row(String label, double value, {bool bold = false}) {
    final style = TextStyle(
        fontWeight: bold ? FontWeight.w700 : FontWeight.w400);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text('₹${value.toStringAsFixed(2)}', style: style),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final theme = Theme.of(context);

      if (cart.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("Cart is empty")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,),),
        backgroundColor: AppTheme.primaryColor,
      ),

      body: SafeArea(
        child: Stack(
          children: [
            // ---------------- SCROLLABLE CONTENT ----------------
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 160),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    /// ADDRESS / PICKUP UI
                    (_receivingMethod == 'delivery')
                        ? Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: AppTheme.borderColor),
                      ),
                      child: ListTile(
                        leading: const Icon(
                            Icons.location_on, color: AppTheme.primaryColor),
                        title: _isLoadingAddress
                            ? const Text("Loading address...")
                            : (_userAddress != null
                            ? Text("${_userAddress!.house}, ${_userAddress!
                            .area}, ${_userAddress!.city}",
                            style: const TextStyle(fontWeight: FontWeight.w600))
                            : const Text("No address saved")),
                        subtitle: _userAddress != null
                            ? Text("Pincode: ${_userAddress!.pincode}")
                            : null,
                      ),
                    )
                        :

                    ///PICKUP MODE
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: _loadPickupShops(),
                      builder: (context, snap) {
                        if (!snap.hasData) {
                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(color: AppTheme.borderColor),
                            ),
                            child: const ListTile(
                                leading: CircularProgressIndicator(),
                                title: Text("Loading pickup locations...")),
                          );
                        }

                        final shops = snap.data!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Pickup Locations",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            ...shops.map((shop) {
                              final addr = shop["address"];
                              return Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(color: AppTheme.borderColor),
                                ),
                                child: ListTile(
                                  leading: const Icon(Icons.store,
                                      color: AppTheme.primaryColor),
                                  title: Text(shop["name"],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700)),
                                  subtitle: (addr != null)
                                      ? Text(
                                      "${addr['area']}, ${addr['city']} (${addr['pincode']})")
                                      : const Text("Address not available"),
                                ),
                              );
                            }),
                          ],
                        );
                      },
                    ),

                    /// RECEIVING METHOD BUTTONS
                    Text("Receiving Method", style: Theme
                        .of(context)
                        .textTheme
                        .titleMedium),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              setState(() {
                                _receivingMethod = 'delivery';
                                _pickupDate = null;
                              });
                              await _fetchEtaIfNeeded();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _receivingMethod == 'delivery' ? AppTheme
                                    .primaryColor : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: AppTheme.primaryColor),
                              ),
                              child: Center(
                                child: Text(
                                  "Delivery",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: _receivingMethod == 'delivery'
                                        ? Colors.white
                                        : AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _receivingMethod = 'pickup'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _receivingMethod == 'pickup' ? AppTheme
                                    .primaryColor : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: AppTheme.primaryColor),
                              ),
                              child: Center(
                                child: Text(
                                  "Pickup",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: _receivingMethod == 'pickup' ? Colors
                                        .white : AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (_receivingMethod == 'delivery') ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _isFetchingEta ? "Calculating ETA..." : "Delivery in: ${cart
                              .overallEstimate}",
                          style: const TextStyle(color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],

                    if (_receivingMethod == 'pickup') ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _pickupDate == null
                                  ? "Choose pickup date"
                                  : "Pickup: ${_pickupDate!.toDisplayString()}",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _pickupDate == null ? Colors.red : Colors
                                    .green,
                              ),
                            ),
                          ),
                          OutlinedButton(
                              onPressed: _selectPickupDate, child: const Text(
                              "Select")),
                        ],
                      ),
                    ],

                    const SizedBox(height: 20),

                    /// PAYMENT METHOD
                    Text("Payment Method", style: Theme
                        .of(context)
                        .textTheme
                        .titleMedium),
                    const SizedBox(height: 6),
                    RadioListTile(
                      value: 'online',
                      groupValue: _paymentMethod,
                      onChanged: (v) => setState(() => _paymentMethod = v!),
                      title: const Text("Pay Online"),
                    ),
                    if (_receivingMethod == 'delivery')
                      RadioListTile(
                        value: 'cod',
                        groupValue: _paymentMethod,
                        onChanged: (v) => setState(() => _paymentMethod = v!),
                        title: const Text("Cash on Delivery"),
                      ),

                    /// ITEM SUMMARY
                    Text("Items Summary", style: Theme
                        .of(context)
                        .textTheme
                        .titleMedium),
                    const SizedBox(height: 8),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: AppTheme.borderColor),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: [
                            ...cart.items.map((it) =>
                                Row(
                                  children: [
                                    Expanded(child: Text(
                                        "${it.name} × ${it.quantity}")),
                                    Text("₹${(it.price * it.quantity)
                                        .toStringAsFixed(2)}"),
                                  ],
                                )),
                            const Divider(),
                            _row("Subtotal", cart.total),
                            _row("GST (5%)", cart.gst),
                            _row("Convenience Fee", cart.convenienceFee),
                            const Divider(height: 16, thickness: 1),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Final Total',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '₹${cart.finalTotal.toStringAsFixed(2)}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ---------------- FIXED FOOTER ----------------
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 14),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, -3))
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Total Payable", style: TextStyle(
                              color: Colors.grey)),
                          Text("₹${cart.finalTotal.toStringAsFixed(2)}",
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w700)),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: _isPlacingOrder ? null : _placeOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(horizontal: 28,
                              vertical: 14),
                        ),
                        child: Text(
                            _isPlacingOrder ? "Processing..." : "Place Order",
                             style: const TextStyle(
                                 color: Colors.white,
                                 fontWeight: FontWeight.w600,),),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


