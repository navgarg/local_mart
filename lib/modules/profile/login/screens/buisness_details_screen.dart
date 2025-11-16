import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/theme.dart';

class BusinessDetailsScreen extends StatefulWidget {
  const BusinessDetailsScreen({super.key});

  @override
  State<BusinessDetailsScreen> createState() => _BusinessDetailsScreenState();
}

class _BusinessDetailsScreenState extends State<BusinessDetailsScreen> {
  final _gstController = TextEditingController();
  bool _isValidGST = true;
  List<String> _selectedTypes = [];

  late String? _role;
  late String? _gender;
  late String? _age;
  late Map<String, dynamic>? _address;

  final _productTypes = const [
    'Groceries',
    'Electronics',
    'Clothing',
    'Home & Kitchen',
    'Stationery',
    'Personal Care',
    'Toys',
    'Sports',
    'Other',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
        {};
    _role = args['role'];
    _gender = args['gender'];
    _age = args['age'];
    _address = args['address'];
  }

  bool _validateGST(String gst) {
    final pattern = RegExp(
      r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$',
    );
    return pattern.hasMatch(gst);
  }

  Future<void> _saveBusinessDetails() async {
    final gst = _gstController.text.trim();

    if (gst.isEmpty || !_validateGST(gst)) {
      setState(() => _isValidGST = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a valid 15-digit GST number."),
          backgroundColor: Colors.black87,
        ),
      );
      return;
    }

    if (_selectedTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select at least one product type."),
          backgroundColor: Colors.black87,
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'role': _role,
      'gender': _gender,
      'age': _age,
      'address': _address,
      'gstNumber': gst,
      'productTypes': _selectedTypes,
      'profileCompleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Business details saved successfully!'),
        backgroundColor: Colors.black87,
      ),
    );

    Navigator.pushReplacementNamed(context, '/products');
  }

  void _toggleType(String type) {
    setState(() {
      if (_selectedTypes.contains(type)) {
        _selectedTypes.remove(type);
      } else {
        _selectedTypes.add(type);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF7FECEC), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ------------------ Header ------------------
                Text(
                  "Business Details",
                  style: t.titleLarge?.copyWith(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Enter your GST number and select your product categories.",
                  style: t.bodyMedium?.copyWith(
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 40),

                // ------------------ GST Field ------------------
                TextFormField(
                  controller: _gstController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: "Enter 15-digit GSTIN",
                    hintStyle: t.bodyMedium?.copyWith(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                    errorText: _isValidGST ? null : "Invalid GST number",
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // ------------------ Categories Label ------------------
                Text(
                  "Select Product Categories:",
                  style: t.bodyMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),

                // ------------------ Multi Select Chips ------------------
                Expanded(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _productTypes.map((type) {
                        final isSelected = _selectedTypes.contains(type);
                        return GestureDetector(
                          onTap: () => _toggleType(type),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.black : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Text(
                              type,
                              style: t.bodyMedium?.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ------------------ Save Button ------------------
                CustomButton(
                  text: "Save & Continue",
                  onPressed: _saveBusinessDetails,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
