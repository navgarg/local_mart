import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_mart/models/retailer_product.dart';
import 'package:local_mart/modules/retailer/services/retailer_product_service.dart';
import 'package:local_mart/modules/wholesaler/services/wholesaler_product_service.dart';
import 'package:local_mart/models/wholesaler_product.dart';

class RetailerProductFormPage extends StatefulWidget {
  final RetailerProduct? retailerProduct;
  final String retailerId;

  const RetailerProductFormPage({
    super.key,
    this.retailerProduct,
    required this.retailerId,
  });

  @override
  State<RetailerProductFormPage> createState() =>
      _RetailerProductFormPageState();
}

class _RetailerProductFormPageState extends State<RetailerProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _wholesalerProductIdController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;

  @override
  void initState() {
    super.initState();
    _wholesalerProductIdController = TextEditingController(
      text: widget.retailerProduct?.wholesalerProductId ?? '',
    );
    _priceController = TextEditingController(
      text: widget.retailerProduct?.price.toString() ?? '',
    );
    _stockController = TextEditingController(
      text: widget.retailerProduct?.stock.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _wholesalerProductIdController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      final retailerProductService = Provider.of<RetailerProductService>(
        context,
        listen: false,
      );
      final wholesalerProductService = Provider.of<WholesalerProductService>(
        context,
        listen: false,
      );
      final String retailerId = widget.retailerId;
      final wholesalerProductId = _wholesalerProductIdController.text;
      final wholesalerProductStream = wholesalerProductService
          .getWholesalerProductById(wholesalerProductId);
      final WholesalerProduct? wholesalerProduct =
          await wholesalerProductStream.first;

      if (wholesalerProduct == null) {
        if (!mounted) return;
        // Handle case where wholesaler product is not found
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wholesaler Product not found.')),
        );
        return;
      }

      final String category = wholesalerProduct.category!;

      if (widget.retailerProduct == null) {
        // Add new product
        final newProduct = RetailerProduct(
          id: DateTime.now().millisecondsSinceEpoch.toString(), // Temporary ID
          wholesalerProductId: _wholesalerProductIdController.text,
          retailerId: retailerId,
          price: int.parse(_priceController.text),
          stock: int.parse(_stockController.text),
          createdAt: Timestamp.fromDate(DateTime.now()),
          updatedAt: Timestamp.fromDate(DateTime.now()),
          category: category,
        );
        await retailerProductService.addRetailerProduct(newProduct);
      } else {
        // Update existing product
        final updatedProduct = widget.retailerProduct!.copyWith(
          wholesalerProductId: _wholesalerProductIdController.text,
          price: int.parse(_priceController.text),
          stock: int.parse(_stockController.text),
          updatedAt: Timestamp.fromDate(DateTime.now()),
          category: category,
        );
        await retailerProductService.updateRetailerProduct(
          updatedProduct,
          category,
        );
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
          widget.retailerProduct == null ? 'Add Product' : 'Edit Product',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _wholesalerProductIdController,
                decoration: const InputDecoration(
                  labelText: 'Wholesaler Product ID',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a product ID';
                  }
                  return null;
                },
              ),
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
                  widget.retailerProduct == null
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
