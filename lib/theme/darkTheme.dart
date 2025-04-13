import 'package:flutter/material.dart';

final darkTheme = ThemeData(
  brightness: Brightness.dark,
  fontFamily: 'Pretendard',
  textTheme: const TextTheme(
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Color(0xFFECEFF1),
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      fontSize: 16,
      color: Color(0xFFECEFF1),
      height: 1.5,
    ),
    bodySmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w300,
      color: Color(0xFFB0BEC5),
      height: 1.5,
    ),
  ),
  // floatingActionButtonTheme: const FloatingActionButtonThemeData(
  //   backgroundColor: Color(0xFF4FC3F7),
  //   foregroundColor: Colors.black,
  // ),
  // checkboxTheme: CheckboxThemeData(
  //   fillColor: MaterialStateProperty.all(const Color(0xFF81D4FA)),
  // ),
);
