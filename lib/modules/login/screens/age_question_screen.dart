import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/age_selector.dart';

class AgeQuestionScreen extends StatefulWidget {
  const AgeQuestionScreen({super.key});

  @override
  State<AgeQuestionScreen> createState() => _AgeQuestionScreenState();
}

class _AgeQuestionScreenState extends State<AgeQuestionScreen> {
  String? _selectedAge;

  @override
  Widget build(BuildContext context) {
    final args =
    ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    final role = args?['role'];
    final gender = args?['gender'];

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
                  "Almost there!",
                  style: GoogleFonts.poppins(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Can we know your age group?",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 60),
                Text(
                  "Select your age range:",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 24),
                AgeSelector(
                  selected: _selectedAge,
                  onChanged: (val) {
                    setState(() => _selectedAge = val);

                    // Smooth transition to address/location screen
                    Navigator.pushReplacementNamed(
                      context,
                      '/map-location',
                      arguments: {
                        'role': role,
                        'gender': gender,
                        'age': val,
                      },
                    );
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
