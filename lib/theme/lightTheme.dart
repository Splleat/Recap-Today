import 'package:flutter/material.dart';

final lightTheme = ThemeData(
  brightness: Brightness.light,
  fontFamily: 'Pretendard',
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.blue,
  ),
  useMaterial3: true,
  // textTheme: const TextTheme(
  //   titleLarge: TextStyle(
  //     fontSize: 20,
  //     fontWeight: FontWeight.bold,
  //     color: Color(0xFF263238),
  //     height: 1.5,
  //   ),
  //   bodyMedium: TextStyle(
  //     fontSize: 16,
  //     color: Color(0xFF263238),
  //     height: 1.5,
  //   ),
  //   bodySmall: TextStyle(
  //     fontSize: 14,
  //     fontWeight: FontWeight.w300,
  //     color: Color(0xFF607D8B),
  //     height: 1.5,
  //   ),
  // ),
  // floatingActionButtonTheme: const FloatingActionButtonThemeData(
  //   backgroundColor: Color(0xFF0288D1),
  //   foregroundColor: Colors.white,
  // ),
  // checkboxTheme: CheckboxThemeData(
  //   fillColor: MaterialStateProperty.all(const Color(0xFF4FC3F7)),
  // ),
);