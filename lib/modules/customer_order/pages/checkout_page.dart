import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import 'package:uuid/uuid.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String _fulfillment = 'delivery'; // or 'pickup'
  String _paymentMethod = 'online'; // or 'cod'
  DateTime? _pickupDate;
  Address? _selectedAddress;

  // For demo: create a dummy address (in real app integrate google maps)
  Address getDummyAddress() {
    return Address(
      id: const Uuid().v4(),
      line1: '12 Example Street',
      line2: 'Near Market',
      city: 'Mumbai',
      state: 'MH',
      pincode: '400001',
      lat: 19.0760,
      lng: 72.8777,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final orderProvider = Provider.of<OrderProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: cart.isEmpty
          ? const Center(child: Text('Nothing to checkout'))
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Address
              ListTile(
                leading: const Icon(Icons.location_on),
                title: Text(_selectedAddress != null ? '${_selectedAddress!.line1}, ${_selectedAddress!.city}' : 'Select Address'),
                subtitle: _selectedAddress != null ? Text(_selectedAddress!.pincode) : null,
                trailing: ElevatedButton(
                  onPressed: () {
                    // integrate Google Maps / place picker here. For now, set dummy
                    setState(() {
                      _selectedAddress = getDummyAddress();
                    });
                  },
                  child: const Text('Choose'),
                ),
              ),
              const Divider(),

              // Fulfillment options
              Text('Fulfillment', style: Theme.of(context).textTheme.bodyLarge),
              RadioListTile(
                title: const Text('Delivery'),
                value: 'delivery',
                groupValue: _fulfillment,
                onChanged: (v) => setState(() => _fulfillment = v as String),
              ),
              RadioListTile(
                title: const Text('Pick-up'),
                value: 'pickup',
                groupValue: _fulfillment,
                onChanged: (v) => setState(() => _fulfillment = v as String),
              ),

              // Pick-up calendar only when pickup
              if (_fulfillment == 'pickup') ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(_pickupDate == null ? 'Choose pickup date' : 'Pickup: ${_pickupDate!.toLocal().toShortString()}'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 3)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 30)),
                        );
                        if (picked != null) {
                          setState(() {
                            _pickupDate = picked;
                          });
                        }
                      },
                      child: const Text('Pick Date'),
                    ),
                  ],
                )
              ],

              const Divider(),

              // Payment options (if delivery -> online or cod)
              Text('Payment', style: Theme.of(context).textTheme.bodyLarge),
              if (_fulfillment == 'delivery') ...[
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
                // For pickup, we might not allow COD (business decision)
                RadioListTile(
                  title: const Text('Pay Online'),
                  value: 'online',
                  groupValue: _paymentMethod,
                  onChanged: (v) => setState(() => _paymentMethod = v as String),
                ),
              ],

              const SizedBox(height: 12),
              // Bill summary
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bill Summary', style: Theme.of(context).textTheme.bodyLarge),
                      const SizedBox(height: 8),
                      ...cart.itemsList.map((it) => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${it.name} x ${it.quantity}'),
                          Text('₹${(it.price * it.quantity).toStringAsFixed(2)}'),
                        ],
                      )),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total:'),
                          Text('₹${cart.total.toStringAsFixed(2)}'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),
              // Place order button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: orderProvider.isPlacing
                      ? null
                      : () async {
                    if (_selectedAddress == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select address')));
                      return;
                    }

                    if (_fulfillment == 'pickup' && _pickupDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please choose pickup date')));
                      return;
                    }

                    // TODO: Integrate actual online payment flow before finalizing for 'online'

                    try {
                      final orderId = await orderProvider.placeOrder(
                        customerId: 'CURRENT_USER_ID', // replace with auth user id
                        customerName: 'User Name',
                        address: _selectedAddress!,
                        items: cart.itemsList,
                        paymentMethod: _paymentMethod == 'online' ? 'online' : (_fulfillment=='pickup' ? 'pickup' : 'cod'),
                        pickupDate: _pickupDate,
                      );

                      // clear local cart once placed
                      Provider.of<CartProvider>(context, listen: false).clear();

                      // Navigate to order tracking
                      Navigator.pushReplacementNamed(context, '/order_tracking', arguments: orderId);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to place order: $e')));
                    }
                  },
                  child: Text(orderProvider.isPlacing ? 'Placing...' : 'Place Order'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// helper extension for date formatting
extension DateFormatting on DateTime {
  String toShortString() {
    return "${this.day}/${this.month}/${this.year}";
  }
}
