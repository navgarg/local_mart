import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/input_field.dart';
import '../widgets/social_button.dart';
import '../widgets/auth_snackbar.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _authService = AuthService();

  final username = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();

  bool _obscure = true;
  bool _isLoading = false;

  // ---------- EMAIL SIGNUP ----------
  Future<void> _signUp() async {
    final name = username.text.trim();
    final mail = email.text.trim();
    final pass = password.text.trim();

    if (name.isEmpty || mail.isEmpty || pass.isEmpty) {
      showAuthSnack(context, "Please fill all fields");
      return;
    }

    try {
      setState(() => _isLoading = true);
      final credential = await _auth.createUserWithEmailAndPassword(
        email: mail,
        password: pass,
      );

      await _firestore.collection('users').doc(credential.user!.uid).set({
        'username': name,
        'email': mail,
        'provider': 'email',
        'createdAt': FieldValue.serverTimestamp(),
      });

      showAuthSnack(context, "Account created successfully!", success: true);
      Navigator.pushReplacementNamed(context, '/mobile-details');
    } on FirebaseAuthException catch (e) {
      showAuthSnack(context, e.message ?? "Signup failed");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ---------- GOOGLE SIGNUP ----------
  Future<void> _googleSignUp() async {
    try {
      final user = await _authService.signInWithGoogleAndUpsert();
      if (user != null) {
        showAuthSnack(context, "Signed up with Google!", success: true);
        Navigator.pushReplacementNamed(context, '/mobile-details');
      }
    } catch (_) {
      showAuthSnack(context, "Google sign-up failed");
    }
  }

  // ---------- FACEBOOK SIGNUP ----------
  Future<void> _facebookSignUp() async {
    try {
      final user = await _authService.signInWithFacebookAndUpsert();
      if (user != null) {
        showAuthSnack(context, "Signed up with Facebook!", success: true);
        Navigator.pushReplacementNamed(context, '/mobile-details');
      }
    } catch (_) {
      showAuthSnack(context, "Facebook sign-up failed");
    }
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF7FECEC), Color(0xFFFFFFFF)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Icon(Icons.shopping_bag_rounded,
                    size: 60, color: Colors.black.withOpacity(0.85)),
                Text(
                  "LocalMart",
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  "Create Your Account",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),

                // ---------- INPUT FIELDS ----------
                InputField(hint: "Username", controller: username),
                const SizedBox(height: 12),
                InputField(hint: "Email", controller: email),
                const SizedBox(height: 12),
                InputField(
                  hint: "Password",
                  obscure: _obscure,
                  controller: password,
                  showToggle: true,
                  onToggle: () => setState(() => _obscure = !_obscure),
                ),
                const SizedBox(height: 20),

                _isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : CustomButton(text: "Sign Up", onPressed: _signUp),

                const SizedBox(height: 28), // 🔥 reduced gap

                // ---------- OR CONTINUE WITH ----------
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: Colors.black.withOpacity(0.3),
                        endIndent: 8,
                      ),
                    ),
                    Text(
                      "Or continue with",
                      style: GoogleFonts.inter(fontSize: 14),
                    ),
                    Expanded(
                      child: Divider(
                        color: Colors.black.withOpacity(0.3),
                        indent: 8,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ---------- FACEBOOK ----------
                SocialButton(
                  text: "Continue with Facebook",
                  bgColor: const Color(0xFF1877F2),
                  iconPath:
                  "https://cdn-icons-png.flaticon.com/512/733/733547.png",
                  textColor: Colors.white,
                  onTap: _facebookSignUp,
                ),
                const SizedBox(height: 12),

                // ---------- GOOGLE ----------
                SocialButton(
                  text: "Continue with Google",
                  bgColor: Colors.white,
                  iconPath:
                  "https://cdn-icons-png.flaticon.com/512/2991/2991148.png",
                  textColor: Colors.black87,
                  border: true,
                  onTap: _googleSignUp,
                ),
                const SizedBox(height: 18),

                // ---------- SIGN IN LINK ----------
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account? ",
                      style: GoogleFonts.inter(fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/login'),
                      child: Text(
                        "Sign In",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
