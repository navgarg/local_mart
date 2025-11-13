import 'package:flutter/material.dart';

class SocialButton extends StatelessWidget {
  final String text;
  final String iconPath;
  final Color bgColor;
  final Color textColor;
  final bool border;
  final VoidCallback onTap;

  const SocialButton({
    super.key,
    required this.text,
    required this.iconPath,
    required this.bgColor,
    required this.textColor,
    this.border = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        width: double.infinity,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: border ? Border.all(color: Colors.grey.shade300) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(iconPath, height: 22, width: 22),
            const SizedBox(width: 10),
            Text(
              text,
              style: t.bodyMedium?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
