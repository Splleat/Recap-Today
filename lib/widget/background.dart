import 'package:flutter/material.dart';

BoxDecoration commonTabDecoration() {
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFE3F2FD),
        Color(0xFFBBDEFB),
      ],
    )
  );
}
