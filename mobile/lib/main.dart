import 'package:flutter/material.dart';
import 'screens/onboarding_screen.dart';

void main() => runApp(const SkillMartApp());

class SkillMartApp extends StatelessWidget {
  const SkillMartApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SkillMart',
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF0056b3),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0056b3)),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF002a5a),
          elevation: 0,
        ),
      ),
      home: const OnboardingScreen(),
    );
  }
}