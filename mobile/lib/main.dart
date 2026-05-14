import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/onboarding_screen.dart';
import 'theme.dart';

void main() => runApp(const SkillMartApp());

class SkillMartApp extends StatefulWidget {
  const SkillMartApp({super.key});

  // Allows descending widgets to access the changeTheme method
  static _SkillMartAppState of(BuildContext context) => 
      context.findAncestorStateOfType<_SkillMartAppState>()!;

  @override
  State<SkillMartApp> createState() => _SkillMartAppState();
}

class _SkillMartAppState extends State<SkillMartApp> {
  ThemeMode _themeMode = ThemeMode.light; // Default to Light

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode');
    if (isDark != null) {
      setState(() {
        _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      });
    }
  }

  void toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
      prefs.setBool('isDarkMode', _themeMode == ThemeMode.dark);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SkillMart',
      theme: SkillMartTheme.lightTheme,
      darkTheme: SkillMartTheme.darkTheme,
      themeMode: _themeMode,
      home: const OnboardingScreen(),
    );
  }
}