import 'package:flutter/material.dart';

class SkillMartTheme {
  static const Color primaryBlue = Color(0xFF0056b3);
  static const Color accentOrange = Color(0xFFf48c06);
  static const Color accentGreen = Color(0xFF56ab2f);

  // Added the missing gradient getter
  static const LinearGradient gradient = LinearGradient(
    colors: [primaryBlue, Color(0xFF00a8ff)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static final ThemeData theme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Poppins',
    scaffoldBackgroundColor: const Color(0xFFF4F7FF),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12), 
        borderSide: BorderSide.none
      ),
    ),
  );
}