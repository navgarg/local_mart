import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:local_mart/modules/retailer_wholesaler_order/models/retailer_wholesaler_order_model.dart';
import 'package:local_mart/modules/retailer_wholesaler_order/services/retailer_wholesaler_order_service.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class RetailerWholesalerOrderFormPage extends StatefulWidget {
  final RetailerWholesalerOrder? order;

  const RetailerWholesalerOrderFormPage({super.key, this.order});

  @override
  State<RetailerWholesalerOrderFormPage> createState() =>
      _RetailerWholesalerOrderFormPageState();
}

class _RetailerWholesalerOrderFormPageState
    extends State<RetailerWholesalerOrderFormPage> {
  final _formKey = GlobalKey<FormState>();
  String? _retailerId;
  String? _wholesalerId;
  List<RetailerWholesalerOrderItem> _items = [];
  String _status = 'pending';
  DateTime? _expectedDeliveryDate;

  @override
  void initState() {
    super.initState();
    if (widget.order != null) {
      _wholesalerId = widget.order!.wholesalerId;
      _items = List.from(widget.order!.items);
      _status = widget.order!.status;
      _expectedDeliveryDate = widget.order!.expectedDeliveryDate;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_retailerId == null) { // Only set if not already set by widget.order
      final String? retailerId = ModalRoute.of(context)?.settings.arguments as String?;
      if (retailerId != null) {
        _retailerId = retailerId;
      } else {
        _retailerId = FirebaseAuth.instance.currentUser!.uid;
      }
    }
  }

  void _saveOrder() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_wholesalerId == null || _items.isEmpty || _retailerId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a wholesaler, add items, and ensure retailer ID is available.'),
          ),
        );
        return;
      }

      final totalAmount = _items.fold(0.0, (currentSum, item) => currentSum + (item.price * item.quantity));

      final newOrder = RetailerWholesalerOrder(
        id: widget.order?.id ?? const Uuid().v4(),
        retailerId: _retailerId!,
        wholesalerId: _wholesalerId!,
        items: _items,
        totalAmount: totalAmount,
        status: _status,
        createdAt: widget.order?.createdAt ?? Timestamp.now(),
        placedAt: widget.order?.placedAt ?? DateTime.now(),
        expectedDeliveryDate: _expectedDeliveryDate,
      );

      final service = Provider.of<RetailerWholesalerOrderService>(context, listen: false);

      if (widget.order == null) {
        await service.placeRetailerWholesalerOrder(newOrder);
      } else {
        await service.updateRetailerWholesalerOrder(newOrder);
      }

      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text(widget.order == null ? 'New Wholesaler Order' : 'Edit Wholesaler Order'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Wholesaler selection (for new orders)
              if (widget.order == null)
                DropdownButtonFormField<String>(
                  value: _wholesalerId,
                  decoration: const InputDecoration(labelText: 'Select Wholesaler'),
                  items: const [
                    // TODO: Fetch actual wholesalers from a service
                    DropdownMenuItem(value: 'wholesaler1', child: Text('Wholesaler A')),
                    DropdownMenuItem(value: 'wholesaler2', child: Text('Wholesaler B')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _wholesalerId = value;
                    });
                  },
                  validator: (value) => value == null ? 'Please select a wholesaler' : null,
                ),
              const SizedBox(height: 20),
              Text('Order Items', style: Theme.of(context).textTheme.titleLarge),
              ..._items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Product: ${item.name}'),
                        Text('Price: ₹${item.price.toStringAsFixed(2)}'),
                        TextFormField(
                          initialValue: item.quantity.toString(),
                          decoration: InputDecoration(labelText: 'Quantity'),
                          keyboardType: TextInputType.number,
                          onSaved: (value) {
                            setState(() {
                              _items[index] = item.copyWith(quantity: int.tryParse(value ?? '0'));
                            });
                          },
                          validator: (value) {
                            if (value == null || int.tryParse(value) == null || int.parse(value) <= 0) {
                              return 'Please enter a valid quantity';
                            }
                            return null;
                          },
                        ),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: IconButton(
                            icon: const Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _items.removeAt(index);
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              ElevatedButton(
                onPressed: () {
                  // TODO: Navigate to a product selection page to add items
                  setState(() {
                    _items.add(RetailerWholesalerOrderItem(
                      productId: 'prod1',
                      name: 'Sample Product',
                      price: 100.0,
                      quantity: 1,
                      wholesalerId: _wholesalerId!,
                      retailerId: _retailerId!,
                      productPath: 'products/prod1',
                    ));
                  });
                },
                child: const Text('Add Item'),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Order Status'),
                items: const [
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'confirmed', child: Text('Confirmed')),
                  DropdownMenuItem(value: 'shipped', child: Text('Shipped')),
                  DropdownMenuItem(value: 'delivered', child: Text('Delivered')),
                ],
                onChanged: (value) {
                  setState(() {
                    _status = value!;
                  });
                },
              ),
              const SizedBox(height: 20),
              ListTile(
                title: Text('Expected Delivery Date: '
                    '${_expectedDeliveryDate != null ? _expectedDeliveryDate!.toLocal().toString().split(' ')[0] : 'Not Set'}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final selectedDate = await showDatePicker(
                    context: context,
                    initialDate: _expectedDeliveryDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (selectedDate != null) {
                    setState(() {
                      _expectedDeliveryDate = selectedDate;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveOrder,
                child: const Text('Save Order'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}