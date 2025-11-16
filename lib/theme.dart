import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF00A693); // Teal-ish (Figma base)
  static const Color secondaryColor = Color(0xFFFED36A); // Soft yellow
  static const Color backgroundColor = Color(0xFFF5F7FA); // Light greyish blue
  static const Color cardColor = Colors.white;
  static const Color errorColor = Colors.redAccent;
  static const Color successColor = Color(0xFF4CAF50);
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color textColor = Color(0xFF333333);
  static const Color labelColor = Color(0xFF888888);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: false,
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    cardColor: cardColor,
    fontFamily: 'Roboto',

    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: backgroundColor,
      error: errorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
    ),

    textTheme: const TextTheme(
      headlineSmall: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      bodyMedium: TextStyle(fontSize: 16, color: textColor),
      bodySmall: TextStyle(fontSize: 14, color: labelColor),
      labelSmall: TextStyle(fontSize: 12, color: labelColor),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderSide: const BorderSide(color: borderColor),
        borderRadius: BorderRadius.circular(10),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: borderColor),
        borderRadius: BorderRadius.circular(10),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: primaryColor, width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
      hintStyle: const TextStyle(color: labelColor),
      labelStyle: const TextStyle(color: textColor),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: textColor,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: textColor,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: textColor),
    ),

    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primaryColor,
      unselectedItemColor: labelColor,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: const TextStyle(fontSize: 12),
      unselectedLabelStyle: const TextStyle(fontSize: 12),
    ),
  );
}
