import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_mart/models/wholesaler_product.dart';
import 'package:local_mart/modules/wholesaler/services/wholesaler_product_service.dart';

class WholesalerProductFormPage extends StatefulWidget {
  final WholesalerProduct? wholesalerProduct;

  const WholesalerProductFormPage({super.key, this.wholesalerProduct});

  @override
  State<WholesalerProductFormPage> createState() =>
      _WholesalerProductFormPageState();
}

class _WholesalerProductFormPageState extends State<WholesalerProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _imageController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.wholesalerProduct?.name ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.wholesalerProduct?.description ?? '',
    );
    _imageController = TextEditingController(
      text: widget.wholesalerProduct?.image ?? '',
    );
    _priceController = TextEditingController(
      text: widget.wholesalerProduct?.price.toString() ?? '',
    );
    _stockController = TextEditingController(
      text: widget.wholesalerProduct?.stock.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _imageController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      final wholesalerProductService = Provider.of<WholesalerProductService>(
        context,
        listen: false,
      );
      final String wholesalerId = FirebaseAuth.instance.currentUser!.uid;

      if (widget.wholesalerProduct == null) {
        // Add new product
        final newProduct = WholesalerProduct(
          id: DateTime.now().millisecondsSinceEpoch.toString(), // Temporary ID
          name: _nameController.text,
          description: _descriptionController.text,
          image: _imageController.text,
          price: int.parse(_priceController.text),
          stock: int.parse(_stockController.text),
          wholesalerId: wholesalerId,
          avgRating: 0.0, // Default for new products
        );
        await wholesalerProductService.addWholesalerProduct(newProduct);
      } else {
        // Update existing product
        final updatedProduct = widget.wholesalerProduct!.copyWith(
          name: _nameController.text,
          description: _descriptionController.text,
          image: _imageController.text,
          price: int.parse(_priceController.text),
          stock: int.parse(_stockController.text),
        );
        await wholesalerProductService.updateWholesalerProduct(updatedProduct);
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
        title: Text(
          widget.wholesalerProduct == null ? 'Add Product' : 'Edit Product',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Product Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a product name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _imageController,
                decoration: const InputDecoration(
                  labelText: 'Image URL (optional)',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(labelText: 'Stock'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter stock quantity';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveProduct,
                child: Text(
                  widget.wholesalerProduct == null
                      ? 'Add Product'
                      : 'Update Product',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
