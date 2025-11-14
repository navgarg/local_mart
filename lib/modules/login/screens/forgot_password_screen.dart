import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _isSending = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF00D1C1), Color(0xFFE0FFFF)],
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 8),
              Text(
                "Forgot Password",
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Enter your registered email address and we’ll send you a password reset link.",
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),

              // Email Field
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: "Email address",
                  hintStyle:
                  GoogleFonts.inter(fontSize: 14, color: Colors.grey[700]),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const Spacer(),

              // Send Reset Button
              _isSending
                  ? const CircularProgressIndicator(color: Colors.black)
                  : CustomButton(
                text: "Send Reset Link",
                onPressed: () async {
                  final email = _emailCtrl.text.trim();
                  if (email.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please enter your email."),
                      ),
                    );
                    return;
                  }

                  setState(() => _isSending = true);
                  try {
                    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Reset link sent! Check your email inbox."),
                        backgroundColor: Colors.black87,
                      ),
                    );
                    Navigator.pushNamed(context, '/password-updated');
                  } on FirebaseAuthException catch (e) {
                    String msg = "An error occurred.";
                    if (e.code == 'user-not-found') {
                      msg = "No user found with this email.";
                    } else if (e.code == 'invalid-email') {
                      msg = "Please enter a valid email address.";
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(msg)),
                    );
                  } finally {
                    setState(() => _isSending = false);
                  }
                },
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
