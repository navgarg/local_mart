import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VerifyResetOtpScreen extends StatefulWidget {
  const VerifyResetOtpScreen({super.key});

  @override
  State<VerifyResetOtpScreen> createState() => _VerifyResetOtpScreenState();
}

class _VerifyResetOtpScreenState extends State<VerifyResetOtpScreen> {
  final List<TextEditingController> _otp = List.generate(4, (_) => TextEditingController());
  int secondsRemaining = 59;
  bool enableResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

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

  void _resend() {
    setState(() {
      secondsRemaining = 59; enableResend = false;
    });
    _startTimer();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("OTP resent successfully"),
        backgroundColor: Colors.black87,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool viaPhone = (ModalRoute.of(context)?.settings.arguments as bool?) ?? true;

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
                viaPhone ? "Verify phone" : "Verify email",
                style: GoogleFonts.poppins(
                  fontSize: 22, fontWeight: FontWeight.w700, color: Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                viaPhone
                    ? "Code has been sent to your phone"
                    : "Code has been sent to your Email",
                style: GoogleFonts.inter(fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 24),

              // OTP row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(4, (i) {
                  return SizedBox(
                    width: 60, height: 60,
                    child: TextField(
                      controller: _otp[i],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        counterText: "",
                        filled: true, fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      onChanged: (v) {
                        if (v.isNotEmpty && i < 3) FocusScope.of(context).nextFocus();
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),

              GestureDetector(
                onTap: enableResend ? _resend : null,
                child: Text(
                  enableResend ? "Didn’t receive code? Resend now"
                      : "Resend code in $secondsRemaining s",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: enableResend ? Colors.teal.shade700 : Colors.black87,
                    fontWeight: enableResend ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              const Spacer(),

              // Next
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/reset-password'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    "Next",
                    style: GoogleFonts.inter(
                      fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
