import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 6.0),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black,
        ),
      ),
    );
  }
}
