import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_mart/models/retailer_product.dart';
import 'package:local_mart/modules/retailer/services/retailer_product_service.dart';
import 'package:local_mart/modules/wholesaler/services/category_service.dart';

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

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _imageController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  String? _selectedCategory;
  List<String> _categories = [];
  final CategoryService _categoryService = CategoryService();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.retailerProduct?.name ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.retailerProduct?.description ?? '',
    );
    _imageController = TextEditingController(
      text: widget.retailerProduct?.image ?? '',
    );
    _priceController = TextEditingController(
      text: widget.retailerProduct?.price.toString() ?? '',
    );
    _stockController = TextEditingController(
      text: widget.retailerProduct?.stock.toString() ?? '',
    );
    _selectedCategory = widget.retailerProduct?.category;
    _loadCategories();
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

  Future<void> _loadCategories() async {
    _categoryService.getCategories().listen((categories) {
      setState(() {
        _categories = categories;
      });
    });
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      final retailerProductService = Provider.of<RetailerProductService>(
        context,
        listen: false,
      );
      final String retailerId = widget.retailerId;
      final String name = _nameController.text;
      final String description = _descriptionController.text;
      final String image = _imageController.text;
      final int price = int.parse(_priceController.text);
      final int stock = int.parse(_stockController.text);

      if (_selectedCategory == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category')),
        );
        return;
      }
      final String category = _selectedCategory!;

      if (widget.retailerProduct == null) {
        // Add new product
        final newProduct = RetailerProduct(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          description: description,
          image: image,
          retailerId: retailerId,
          price: price,
          stock: stock,
          createdAt: Timestamp.fromDate(DateTime.now()),
          updatedAt: Timestamp.fromDate(DateTime.now()),
          category: category,
        );
        await retailerProductService.addRetailerProduct(newProduct);
      } else {
        // Update existing product
        final updatedProduct = widget.retailerProduct!.copyWith(
          name: name,
          description: description,
          image: image,
          price: price,
          stock: stock,
          updatedAt: Timestamp.fromDate(DateTime.now()),
          category: category,
        );
        await retailerProductService.updateRetailerProduct(updatedProduct);
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
                  labelText: 'Image URL (Optional)',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a category';
                  }
                  return null;
                },
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
              const SizedBox(height: 24),
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
