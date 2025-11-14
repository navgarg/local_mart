import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'widgets/custom_dropdown.dart';
import 'widgets/custom_button.dart';

class AddressDetailsScreen extends StatefulWidget {
  const AddressDetailsScreen({super.key});

  @override
  State<AddressDetailsScreen> createState() => _AddressDetailsScreenState();
}

class _AddressDetailsScreenState extends State<AddressDetailsScreen> {
  final _formKey = GlobalKey<FormState>();

  final _flatCtrl = TextEditingController();
  final _buildingCtrl = TextEditingController();
  final _localityCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();

  String? _selectedState;
  String? _role, _gender, _age;
  double? _lat, _lng;

  final _states = const [
    'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
    'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka',
    'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya',
    'Mizoram', 'Nagaland', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim',
    'Tamil Nadu', 'Telangana', 'Tripura', 'Uttar Pradesh', 'Uttarakhand',
    'West Bengal'
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ?? {};

    _pincodeCtrl.text = args['pincode'] ?? '';
    _areaCtrl.text = args['area'] ?? '';
    _cityCtrl.text = args['city'] ?? '';
    _selectedState = args['state'] ?? '';

    _lat = args['lat'];
    _lng = args['lng'];
    _role = args['role'];
    _gender = args['gender'];
    _age = args['age'];
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final address = {
      'flatNo': _flatCtrl.text.trim(),
      'building': _buildingCtrl.text.trim(),
      'locality': _localityCtrl.text.trim(),
      'pincode': _pincodeCtrl.text.trim(),
      'area': _areaCtrl.text.trim(),
      'city': _cityCtrl.text.trim(),
      'state': _selectedState ?? '',
      'lat': _lat,
      'lng': _lng,
      'timestamp': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'address': address,
      'gender': _gender,
      'age': _age,
      'role': _role,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Address saved successfully'),
        backgroundColor: Colors.black87,
      ),
    );

    // Redirect based on role
    if (_role == 'Customer') {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(
        context,
        '/business-details',
        arguments: {
          'role': _role,
          'gender': _gender,
          'age': _age,
          'address': address,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  const SizedBox(height: 10),
                  Text(
                    "Add Delivery Address",
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildField("Flat / House No.", _flatCtrl),
                  _buildField("Building / Apartment Name", _buildingCtrl),
                  _buildField("Locality / Area (manual)", _localityCtrl),

                  const SizedBox(height: 20),
                  Text(
                    "Auto-detected (editable if incorrect)",
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),

                  _buildField("Pincode", _pincodeCtrl),
                  _buildField("Area", _areaCtrl),
                  _buildField("City", _cityCtrl),

                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: CustomDropdown(
                      label: "State",
                      items: _states,
                      selectedValue: _selectedState,
                      onChanged: (val) => setState(() => _selectedState = val),
                    ),
                  ),

                  const SizedBox(height: 40),
                  CustomButton(
                    text: "Save & Continue",
                    onPressed: _saveAddress,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(String hint, TextEditingController controller, {bool required = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        validator: required
            ? (val) => val == null || val.trim().isEmpty ? 'Required field' : null
            : null,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.grey[700]),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
