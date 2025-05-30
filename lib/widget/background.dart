import 'package:flutter/material.dart';

BoxDecoration commonTabDecoration(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isDark
      ? [
        const Color(0xFF263238),
        const Color(0xFF37474F),
      ]
      : [
        const Color(0xFFE3F2FD),
        const Color(0xFFBBDEFB),
      ],
    )
  );
}
