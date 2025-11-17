import 'package:flutter/material.dart';

void showAuthSnack(BuildContext context, String message, {bool success = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(success ? " $message" : " $message"),
      backgroundColor: success ? Colors.green[600] : Colors.red[600],
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
