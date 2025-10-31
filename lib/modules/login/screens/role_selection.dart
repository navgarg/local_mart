import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  Future<void> _selectRole(BuildContext context, String role) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'role': role,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("✅ Role set as $role")),
    );

    Navigator.pushReplacementNamed(
      context,
      '/gender-question',
      arguments: role,
    );


  }

  @override
  Widget build(BuildContext context) {
    final roles = [
      {'name': 'Customer', 'icon': Icons.person, 'color': Colors.teal},
      {'name': 'Retailer', 'icon': Icons.storefront, 'color': Colors.amber},
      {'name': 'Wholesaler', 'icon': Icons.inventory, 'color': Colors.pinkAccent},
    ];

    return Scaffold(
      // ❌ Remove white background color
      body: Container(
        width: double.infinity, // ✅ Ensures full width
        height: double.infinity, // ✅ Ensures full height
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF7FECEC),
              Color(0xFFE0FFFF), // soft light blue tint
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
            child: Column(
              children: [
                Text(
                  "Local Mart",
                  style: GoogleFonts.poppins(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Select your role to continue",
                  style: GoogleFonts.inter(fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 40),
                for (var role in roles)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: GestureDetector(
                      onTap: () => _selectRole(context, role['name'] as String),
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              role['icon'] as IconData,
                              size: 40,
                              color: role['color'] as Color,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              role['name'] as String,
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
