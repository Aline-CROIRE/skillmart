import 'package:flutter/material.dart';
import 'screens/onboarding_screen.dart';

void main() => runApp(const SkillMartApp());

class SkillMartApp extends StatelessWidget {
  const SkillMartApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, primarySwatch: Colors.blue),
      home: const OnboardingScreen(),
    );
  }
}