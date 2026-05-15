import 'package:flutter/material.dart';

class SkillMartTheme {
  // Vibrant Professional Colors (Reflecting App Logo)
  static const Color primaryBlue = Color(0xFF1D4ED8); // Vibrant Royal Blue
  static const Color accentOrange = Color(0xFFF97316); // Vibrant Orange
  static const Color accentGreen = Color(0xFF10B981); // Emerald Green for success
  
  // Gradients
  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient lightBackgroundGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF1F5F9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF172554), Color(0xFF701A75)], // Navy Blue to Vibrant Fuchsia
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Light Theme
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Poppins',
    brightness: Brightness.light,
    primaryColor: primaryBlue,
    scaffoldBackgroundColor: const Color(0xFFF8FAFC),
    colorScheme: const ColorScheme.light(
      primary: primaryBlue,
      secondary: accentOrange,
      surface: Colors.white,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      error: Color(0xFFEF4444),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: primaryBlue,
      elevation: 0,
      centerTitle: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        elevation: 2,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryBlue, width: 2),
      ),
      labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
    ),
  );

  // Dark Theme
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Poppins',
    brightness: Brightness.dark,
    primaryColor: primaryBlue,
    scaffoldBackgroundColor: const Color(0xFF0F172A), // Keep very dark navy for contrast
    colorScheme: const ColorScheme.dark(
      primary: primaryBlue,
      secondary: accentOrange,
      surface: Color(0xFF172554), // Navy Blue surface
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      error: Color(0xFFEF4444),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF172554),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        elevation: 2,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1E293B),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryBlue, width: 2),
      ),
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
    ),
  );
}