import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AgeSelector extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onChanged;

  const AgeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bands = const ['<18', '18–25', '26–35', '36–45', '46–60', '60+'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: bands.map((band) {
        final bool isSelected = selected == band;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: GestureDetector(
            onTap: () => onChanged(band),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              height: 55,
              decoration: BoxDecoration(
                color: isSelected ? Colors.black : Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  band,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
