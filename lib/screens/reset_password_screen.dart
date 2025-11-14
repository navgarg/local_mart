import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/custom_button.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  bool _obscure1 = true;
  bool _obscure2 = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFF7FECEC), Color(0xFFFFFFFF)],
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 6),
              Text(
                "Reset Your Password",
                style: GoogleFonts.poppins(
                  fontSize: 22, fontWeight: FontWeight.w700, color: Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "You can create a new password, please don't forget this one too.",
                style: GoogleFonts.inter(fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 18),

              _passwordField("New Password", _obscure1, () {
                setState(() => _obscure1 = !_obscure1);
              }),
              const SizedBox(height: 12),
              _passwordField("Confirm New Password", _obscure2, () {
                setState(() => _obscure2 = !_obscure2);
              }),

              const Spacer(),
              CustomButton(
                text: "Continue",
                onPressed: () => Navigator.pushNamed(context, '/password-updated'),
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _passwordField(String hint, bool obscure, VoidCallback onToggle) {
    return TextField(
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.grey[700]),
        filled: true, fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none,
        ),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey[600]),
          onPressed: onToggle,
        ),
      ),
    );
  }
}
