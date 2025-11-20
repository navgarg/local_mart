import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_mart/models/app_user.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  String username = "";
  String email = "";
  String mobile = "";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final appUser = AppUser.fromFirestore(doc);
        setState(() {
          username = appUser.username ?? '';
          email = appUser.email ?? '';
          mobile = appUser.mobile ?? '';
        });
      } else {
        setState(() {
          email = user.email ?? '';
        });
      }
    } catch (e) {
      debugPrint("Error loading user data: $e");
    }
  }

  void _logout() async {
    await _auth.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF5FE0E5), Color(0xFFFFFFFF)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_rounded,
                      size: 80, color: Colors.black.withOpacity(0.85)),
                  const SizedBox(height: 16),
                  Text(
                    "Welcome to LocalMart 👋",
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (username.isNotEmpty)
                    Text("Hey $username!", style: GoogleFonts.inter(fontSize: 18)),
                  if (mobile.isNotEmpty)
                    Text("📱 +91 $mobile", style: GoogleFonts.inter(fontSize: 16)),
                  if (email.isNotEmpty)
                    Text("✉️ $email", style: GoogleFonts.inter(fontSize: 16)),

                  const SizedBox(height: 40),

                  ElevatedButton(
                    onPressed: _logout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Log Out",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
