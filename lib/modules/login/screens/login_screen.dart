import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/input_field.dart';
import '../widgets/social_button.dart';
import '../widgets/auth_snackbar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = FirebaseAuth.instance;
  final _authService = AuthService();

  bool isPhoneSelected = true;
  bool obscurePassword = true;
  bool isCounting = false;
  bool _isSendingOTP = false;
  int seconds = 59;

  final phone = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();

  // ---------- EMAIL LOGIN ----------
  Future<void> _loginWithEmail() async {
    final mail = email.text.trim();
    final pass = password.text.trim();

    if (mail.isEmpty || pass.isEmpty) {
      showAuthSnack(context, "Please fill in both email and password");
      return;
    }

    try {
      await _auth.signInWithEmailAndPassword(email: mail, password: pass);
      showAuthSnack(context, "Login successful!", success: true);
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      showAuthSnack(context, e.message ?? "Login failed");
    }
  }

  // ---------- PHONE OTP ----------
  Future<void> _sendOTP() async {
    final num = phone.text.trim();
    if (num.isEmpty || num.length != 10) {
      showAuthSnack(context, "Please enter a valid 10-digit number");
      return;
    }

    setState(() => _isSendingOTP = true);
    await _authService.verifyPhoneNumber(
      phoneNumber: "+91$num",
      verificationCompleted: (_) {
        setState(() => _isSendingOTP = false);
        showAuthSnack(context, "Auto verification completed ✅", success: true);
      },
      verificationFailed: (e) {
        setState(() => _isSendingOTP = false);
        showAuthSnack(context, "Verification failed: ${e.message}");
      },
      codeSent: (verificationId) {
        setState(() => _isSendingOTP = false);
        showAuthSnack(context, "OTP sent successfully 📩", success: true);
        Navigator.pushNamed(context, '/verify',
            arguments: {'verificationId': verificationId, 'phone': num});
      },
    );
  }

  // ---------- TIMER ----------
  void _startTimer() {
    if (isCounting) return;
    setState(() => isCounting = true);
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (seconds == 0) {
        setState(() {
          isCounting = false;
          seconds = 59;
        });
        return false;
      }
      setState(() => seconds--);
      return true;
    });
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
              colors: [Color(0xFF5FE0E5), Color(0xFFFFFFFF)]),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            physics: const BouncingScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Icon(Icons.shopping_bag_rounded,
                    size: 64, color: Colors.black.withOpacity(0.85)),
                Text("LocalMart",
                    style: GoogleFonts.poppins(
                        fontSize: 28, fontWeight: FontWeight.w700)),
                Text("Welcome Back",
                    style: GoogleFonts.inter(
                        fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 24),

                // ---------- Toggle Buttons ----------
                _loginToggle(),

                const SizedBox(height: 20),

                // ---------- Inputs ----------
                if (isPhoneSelected)
                  InputField(hint: "Mobile Phone", controller: phone)
                else
                  Column(
                    children: [
                      InputField(hint: "Email", controller: email),
                      const SizedBox(height: 12),
                      InputField(
                        hint: "Password",
                        obscure: obscurePassword,
                        controller: password,
                        showToggle: true,
                        onToggle: () =>
                            setState(() => obscurePassword = !obscurePassword),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/forgot'),
                          child: Text("Forgot Password?",
                              style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500)),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 20),

                // ---------- OTP / Log In ----------
                _isSendingOTP
                    ? const CircularProgressIndicator(color: Colors.black)
                    : CustomButton(
                  text: isPhoneSelected ? "Get OTP" : "Log In",
                  color: isPhoneSelected
                      ? const Color(0xFFF4A825)
                      : Colors.black,
                  onPressed: () {
                    if (isPhoneSelected) {
                      _sendOTP();
                      _startTimer();
                    } else {
                      _loginWithEmail();
                    }
                  },
                ),

                if (isPhoneSelected && isCounting)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text("Resend code in $seconds s",
                        style: GoogleFonts.inter(fontSize: 14)),
                  ),

                const SizedBox(height: 24),
                _divider("Or sign in with"),
                const SizedBox(height: 20),

                // ---------- Facebook Login ----------
                SocialButton(
                  text: "Continue with Facebook",
                  bgColor: const Color(0xFF1877F2),
                  iconPath:
                  "https://cdn-icons-png.flaticon.com/512/733/733547.png",
                  textColor: Colors.white,
                  onTap: () async {
                    try {
                      final user =
                      await _authService.signInWithFacebookAndUpsert();
                      if (user != null) {
                        showAuthSnack(context, "Logged in with Facebook!",
                            success: true);
                        Navigator.pushReplacementNamed(context, '/home');
                      }
                    } catch (e) {
                      showAuthSnack(context, "Facebook Sign-In failed: $e");
                    }
                  },
                ),
                const SizedBox(height: 12),

                // ---------- Google Login ----------
                SocialButton(
                  text: "Continue with Google",
                  bgColor: Colors.white,
                  iconPath:
                  "https://cdn-icons-png.flaticon.com/512/2991/2991148.png",
                  textColor: Colors.black87,
                  border: true,
                  onTap: () async {
                    try {
                      final user =
                      await _authService.signInWithGoogleAndUpsert();
                      if (user != null) {
                        showAuthSnack(context, "Logged in with Google!",
                            success: true);
                        Navigator.pushReplacementNamed(context, '/home');
                      }
                    } catch (e) {
                      showAuthSnack(context, "Google Sign-In failed: $e");
                    }
                  },
                ),

                const SizedBox(height: 24),
                _signupRedirect(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------- Helper Widgets ----------
  Widget _loginToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          _toggleButton("Phone", isPhoneSelected, () {
            setState(() => isPhoneSelected = true);
          }),
          _toggleButton("Email", !isPhoneSelected, () {
            setState(() => isPhoneSelected = false);
          }),
        ],
      ),
    );
  }

  Widget _toggleButton(String text, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? Colors.black : Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            text,
            style: GoogleFonts.inter(
              color: active ? Colors.white : Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _divider(String label) => Row(
    children: [
      Expanded(
          child: Divider(
              color: Colors.black.withOpacity(0.3), endIndent: 8)),
      Text(label, style: GoogleFonts.inter(fontSize: 14)),
      Expanded(
          child: Divider(
              color: Colors.black.withOpacity(0.3), indent: 8)),
    ],
  );

  Widget _signupRedirect() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text("Don’t have an account? ",
          style: GoogleFonts.inter(fontSize: 14)),
      GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/signup'),
        child: Text("Sign Up",
            style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black)),
      ),
    ],
  );
}
