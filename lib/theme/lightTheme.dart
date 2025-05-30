import 'package:flutter/material.dart';

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  fontFamily: 'Pretendard',
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.blue,
    brightness: Brightness.light,
  ),
  useMaterial3: true,
  textTheme: const TextTheme(
    titleLarge: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    ),
    titleMedium: TextStyle(
      fontSize: 18,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
    ),
    bodySmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w300,
    ),
  ),
);