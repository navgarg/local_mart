import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/gender_selector.dart';

class GenderQuestionScreen extends StatefulWidget {
  const GenderQuestionScreen({super.key});

  @override
  State<GenderQuestionScreen> createState() => _GenderQuestionScreenState();
}

class _GenderQuestionScreenState extends State<GenderQuestionScreen> {
  String? _selectedGender;

  @override
  Widget build(BuildContext context) {
    final role = ModalRoute.of(context)!.settings.arguments as String?;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF7FECEC),
              Color(0xFFE0FFFF),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hello!",
                  style: GoogleFonts.poppins(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Let’s start with something simple.",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 60),
                Text(
                  "What’s your gender?",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 24),
                GenderSelector(
                  selectedGender: _selectedGender,
                  onChanged: (val) {
                    setState(() => _selectedGender = val);

                    // Smooth transition to age question
                    Future.delayed(const Duration(milliseconds: 300), () {
                      Navigator.pushReplacementNamed(
                        context,
                        '/age-question',
                        arguments: {
                          'role': role,
                          'gender': val,
                        },
                      );
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
