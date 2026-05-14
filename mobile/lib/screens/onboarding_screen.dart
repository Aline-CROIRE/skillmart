import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/s_curve_painter.dart';
import 'auth_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  @override
  void initState() {
    super.initState();
    // Automatically move to the login screen after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (_) => const AuthScreen())
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          CustomPaint(
            painter: SCurvePainter(color: Theme.of(context).colorScheme.primary.withOpacity(0.1)), 
            child: Container()
          ),
          Padding(
            padding: const EdgeInsets.all(30.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo with Glow effect
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.2), 
                          blurRadius: 40, 
                          spreadRadius: 10
                        )
                      ],
                    ),
                    child: Image.asset('assets/logo.png', height: 120),
                  ).animate().scale(duration: 1000.ms, curve: Curves.elasticOut),
                  
                  const SizedBox(height: 50),
                  Text(
                    "SkillMart", 
                    style: TextStyle(
                      fontSize: 48, 
                      fontWeight: FontWeight.w900, 
                      color: Theme.of(context).colorScheme.primary
                    )
                  ).animate().fadeIn(delay: 400.ms, duration: 800.ms),
                  Text(
                    "Learn. Build. Sell. Grow.", 
                    style: TextStyle(
                      fontSize: 20, 
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                    )
                  ).animate().fadeIn(delay: 800.ms, duration: 800.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}