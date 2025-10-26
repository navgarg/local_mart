import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:local_mart/theme.dart';
import '../models/order_model.dart' as models;
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';

/// Extension to format dates nicely (renamed to avoid conflicts)
extension DateDisplay on DateTime {
  String toDisplayString() {
    return "${day.toString().padLeft(2, '0')}-"
        "${month.toString().padLeft(2, '0')}-"
        "$year";
  }
}

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String _receivingMethod = 'delivery'; // 'delivery' | 'pickup'
  String _paymentMethod = 'online'; // 'online' | 'cod'
  DateTime? _pickupDate;
  models.Address? _selectedAddress;
  final _uuid = const Uuid();

  models.Address getDummyAddress() => models.Address(
    id: _uuid.v4(),
    line1: '12 Example Street',
    line2: 'Near Market',
    city: 'Mumbai',
    state: 'MH',
    pincode: '400001',
    lat: 19.0760,
    lng: 72.8777,
  );

  Future<void> _selectPickupDate() async {
    final now = DateTime.now();
    final lastDate = now.add(const Duration(days: 3));
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: lastDate,
    );

    if (picked != null && picked.isBefore(lastDate.add(const Duration(days: 1)))) {
      setState(() => _pickupDate = picked);
    } else if (picked != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pickup date must be within 3 days')),
      );
    }
  }

  Future<void> _placeOrder() async {
    if (_receivingMethod == 'delivery' && _selectedAddress == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please select address')));
      return;
    }
    if (_receivingMethod == 'pickup' && _pickupDate == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please select pickup date')));
      return;
    }

    final cart = Provider.of<CartProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    try {
      final orderId = await orderProvider.placeOrder(
        customerId: 'CURRENT_USER_ID',
        customerName: 'User Name',
        address: _selectedAddress ?? getDummyAddress(),
        items: cart.itemsList,
        paymentMethod: _paymentMethod,
        receivingMethod: _receivingMethod,
        pickupDate: _pickupDate,
      );

      cart.clear();
      Navigator.pushReplacementNamed(context, '/order_tracking', arguments: orderId);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to place order: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final orderProvider = Provider.of<OrderProvider>(context);
    final theme = AppTheme.lightTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
      ),
      body: cart.isEmpty
          ? Center(
        child: Text(
          'Nothing to checkout',
          style: theme.textTheme.bodyMedium,
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Address
            Card(
              color: AppTheme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppTheme.borderColor),
              ),
              child: ListTile(
                leading: const Icon(Icons.location_on, color: AppTheme.primaryColor),
                title: Text(
                  _selectedAddress != null
                      ? '${_selectedAddress!.line1}, ${_selectedAddress!.city}'
                      : 'Select Address',
                  style: theme.textTheme.bodyMedium,
                ),
                subtitle: _selectedAddress != null
                    ? Text(_selectedAddress!.pincode)
                    : null,
                trailing: ElevatedButton(
                  onPressed: () => setState(() => _selectedAddress = getDummyAddress()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                  ),
                  child: const Text('Choose'),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Receiving Method
            Text('Receiving Method', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            RadioListTile(
              title: const Text('Delivery'),
              value: 'delivery',
              groupValue: _receivingMethod,
              onChanged: (v) => setState(() => _receivingMethod = v as String),
            ),
            RadioListTile(
              title: const Text('Pickup'),
              value: 'pickup',
              groupValue: _receivingMethod,
              onChanged: (v) => setState(() => _receivingMethod = v as String),
            ),

            // Pickup Date
            if (_receivingMethod == 'pickup') ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _pickupDate != null
                          ? 'Pickup: ${_pickupDate!.toDisplayString()}'
                          : 'Choose pickup date',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _selectPickupDate,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor),
                    child: const Text('Pick Date'),
                  ),
                ],
              ),
            ],

            const Divider(height: 32),

            // Payment
            Text('Payment', style: theme.textTheme.titleMedium),
            if (_receivingMethod == 'delivery') ...[
              RadioListTile(
                title: const Text('Pay Online'),
                value: 'online',
                groupValue: _paymentMethod,
                onChanged: (v) => setState(() => _paymentMethod = v as String),
              ),
              RadioListTile(
                title: const Text('Cash on Delivery'),
                value: 'cod',
                groupValue: _paymentMethod,
                onChanged: (v) => setState(() => _paymentMethod = v as String),
              ),
            ] else ...[
              RadioListTile(
                title: const Text('Pay Online'),
                value: 'online',
                groupValue: _paymentMethod,
                onChanged: (v) => setState(() => _paymentMethod = v as String),
              ),
            ],

            const SizedBox(height: 12),

            // Bill Summary
            Card(
              color: AppTheme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppTheme.borderColor),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bill Summary', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ...cart.itemsList.map(
                          (it) => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${it.name} x ${it.quantity}',
                              style: theme.textTheme.bodyMedium),
                          Text('₹${(it.price * it.quantity).toStringAsFixed(2)}',
                              style: theme.textTheme.bodyMedium),
                        ],
                      ),
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total:', style: theme.textTheme.bodyMedium),
                        Text('₹${cart.total.toStringAsFixed(2)}',
                            style: theme.textTheme.titleMedium),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Place Order
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: orderProvider.isPlacing ? null : _placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  orderProvider.isPlacing ? 'Placing...' : 'Place Order',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
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




