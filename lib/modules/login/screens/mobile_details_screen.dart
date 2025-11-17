import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/theme.dart';
import '../widgets/input_field.dart';
import '../widgets/auth_snackbar.dart';

class MobileDetailsScreen extends StatefulWidget {
  const MobileDetailsScreen({super.key});

  @override
  State<MobileDetailsScreen> createState() => _MobileDetailsScreenState();
}

class _MobileDetailsScreenState extends State<MobileDetailsScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _mobileController = TextEditingController();
  bool _isLoading = false;

  Future<void> _saveMobile() async {
    final phone = _mobileController.text.trim();

    if (phone.isEmpty || phone.length < 10) {
      showAuthSnack(context, "Please enter a valid mobile number");
      return;
    }

    try {
      setState(() => _isLoading = true);

      final user = _auth.currentUser;
      if (user == null) {
        showAuthSnack(context, "User not found. Please sign in again.");
        return;
      }

      await _firestore.collection('users').doc(user.uid).update({
        'mobile': phone,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      showAuthSnack(
        context,
        "Mobile number saved successfully!",
        success: true,
      );

      Navigator.pushReplacementNamed(context, '/role-selection');
    } catch (e) {
      showAuthSnack(context, "Failed to save mobile number: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF7FECEC), Color(0xFFFFFFFF)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
            child: Column(
              children: [
                const SizedBox(height: 10),

                // App Icon
                Icon(
                  Icons.phone_android_rounded,
                  size: 60,
                  color: Colors.black.withOpacity(0.85),
                ),

                // Title
                Text(
                  "LocalMart",
                  style: t.titleLarge?.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),

                // Subtitle
                Text(
                  "Add Your Mobile Number",
                  style: t.bodyMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 40),

                // Input field
                InputField(
                  hint: "Enter Mobile Number",
                  controller: _mobileController,
                ),

                const SizedBox(height: 30),

                // Continue Button
                _isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : CustomButton(
                  text: "Continue",
                  onPressed: _saveMobile,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
