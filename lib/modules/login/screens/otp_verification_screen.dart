import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart'; //  use the same AuthService

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _otpControllers =
  List.generate(6, (_) => TextEditingController());

  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _verificationId;
  String? _phoneNumber;

  bool enableResend = false;
  bool isVerifying = false;
  int secondsRemaining = 59;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
    ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _verificationId = args['verificationId'];
      _phoneNumber = args['phone'];
    }
    _startTimer();
  }

  // 🔹 Timer logic
  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      if (secondsRemaining > 0) {
        setState(() => secondsRemaining--);
        _startTimer();
      } else {
        setState(() => enableResend = true);
      }
    });
  }

  // 🔹 Verify OTP
  Future<void> _verifyOtp() async {
    String otp = _otpControllers.map((c) => c.text).join();

    if (otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter full 6-digit OTP")),
      );
      return;
    }

    if (_verificationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Verification ID missing ")),
      );
      return;
    }

    setState(() => isVerifying = true);

    try {
      await _authService.signInWithOTP(_verificationId!, otp);
      setState(() => isVerifying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(" OTP Verified!")),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } on FirebaseAuthException catch (e) {
      setState(() => isVerifying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(" ${e.message ?? 'Invalid OTP'}")),
      );
    }
  }

  // 🔹 Resend OTP using AuthService
  Future<void> _resendOtp() async {
    if (_phoneNumber == null) return;
    setState(() {
      enableResend = false;
      secondsRemaining = 59;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Resending OTP...")),
    );

    await _authService.verifyPhoneNumber(
      phoneNumber: "+91$_phoneNumber",
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Auto verification completed ")),
        );
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      },
      verificationFailed: (FirebaseAuthException e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(" ${e.message}")),
        );
      },
      codeSent: (String newVerificationId) {
        _verificationId = newVerificationId;
        _startTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(" New OTP sent")),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF7FECEC),
              Color(0xFFFFFFFF),
            ],
          ),
        ),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Verify phone number",
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Enter the 6-digit OTP sent to your number",
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 36),

            // 🔹 OTP Boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 45,
                  height: 60,
                  child: TextField(
                    controller: _otpControllers[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      counterText: "",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty && index < 5) {
                        FocusScope.of(context).nextFocus();
                      }
                    },
                  ),
                );
              }),
            ),

            const SizedBox(height: 22),

            //  Timer / Resend
            GestureDetector(
              onTap: enableResend ? _resendOtp : null,
              child: Text(
                enableResend
                    ? "Didn’t receive code? Resend now"
                    : "Resend code in $secondsRemaining s",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color:
                  enableResend ? Colors.teal.shade700 : Colors.black87,
                  fontWeight:
                  enableResend ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),

            const SizedBox(height: 30),

            //  Verify Button
            ElevatedButton(
              onPressed: isVerifying ? null : _verifyOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: isVerifying
                  ? const CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2)
                  : Text(
                "Verify",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}




