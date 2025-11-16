import 'package:flutter/material.dart';

Widget buildStars(double rating, {double size = 14}) {
  return Row(
    children: List.generate(5, (i) {
      double lower = i + 0.25;
      double upper = i + 0.75;

      if (rating >= i + 1) {
        return Icon(Icons.star, size: size, color: Colors.amber);
      } else if (rating >= lower && rating < upper) {
        return Icon(Icons.star_half, size: size, color: Colors.amber);
      } else {
        return Icon(Icons.star_border, size: size, color: Colors.amber);
      }
    }),
  );
}
