import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../main.dart';
import '../theme.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  bool _isLoading = false;
  bool _obscureText = true;

  final TextEditingController _email = TextEditingController();
  final TextEditingController _pass = TextEditingController();
  final TextEditingController _confirmPass = TextEditingController();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _phone = TextEditingController(text: "+250");
  final ApiService _api = ApiService();

  Future<void> _submit() async {
    if (!isLogin && _pass.text != _confirmPass.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
      return;
    }

    if (!isLogin && _phone.text.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please provide a valid Rwanda phone number")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? fcmToken;
      try {
        fcmToken = await PushNotificationService.getToken();
      } catch (e) {
        debugPrint("FCM error: $e");
      }

      final res = isLogin 
          ? await _api.login(_email.text, _pass.text, fcmToken: fcmToken)
          : await _api.register(_name.text, _email.text, _pass.text, "User", fcmToken: fcmToken, phoneNumber: _phone.text);

      if (mounted && res != null) {
        if (!isLogin) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("Verify Email"),
              content: Text(res['message'] ?? "Registration successful. Please check your email to verify your account."),
              actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
            )
          );
          setState(() => isLogin = true);
          return;
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', res['token'] ?? '');
        await prefs.setString('role', res['role'] ?? 'User');
        await prefs.setString('userName', res['name'] ?? 'User');
        await prefs.setString('userId', res['_id'] ?? '');

        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainMenuScreen()));
      } else if (mounted) {
        final msg = res?['message'] ?? "Invalid Credentials";
        bool isUnverified = msg.toLowerCase().contains("verify");

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          action: isUnverified ? SnackBarAction(label: "RESEND LINK", onPressed: _resendEmail) : null,
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendEmail() async {
    if (_email.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter your email first")));
      return;
    }
    final res = await _api.resendVerification(_email.text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res?['message'] ?? "Failed to resend"), backgroundColor: Colors.blue));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/background.webp', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(color: isDark ? Colors.black.withOpacity(0.5) : Colors.white.withOpacity(0.2)),
            ),
          ),
          SafeArea(
            child: Stack(
              children: [
                Positioned(
                  top: 10, right: 10,
                  child: IconButton(
                    icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, color: isDark ? Colors.white : Colors.black),
                    onPressed: () => SkillMartApp.of(context).toggleTheme(),
                  ),
                ),
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                        child: Container(
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            color: colorScheme.surface.withOpacity(isDark ? 0.6 : 0.85),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                                child: Image.asset('assets/logo.png', height: 80),
                              ),
                              const SizedBox(height: 20),
                              if (!isLogin) ...[
                                _buildField(_name, "Full Name", Icons.person, false),
                                _buildField(_phone, "Phone Number", Icons.phone, false, keyboardType: TextInputType.phone),
                              ],
                              _buildField(_email, "Email", Icons.email, false),
                              _buildField(_pass, "Password", Icons.lock, true),
                              if (!isLogin) _buildField(_confirmPass, "Confirm Password", Icons.lock_outline, true),
                              const SizedBox(height: 25),
                              _isLoading ? const CircularProgressIndicator() : 
                              SizedBox(
                                width: double.infinity, height: 50, 
                                child: ElevatedButton(
                                  onPressed: _submit, 
                                  child: Text(isLogin ? "LOGIN" : "REGISTER", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
                                )
                              ),
                              TextButton(
                                onPressed: () => setState(() => isLogin = !isLogin), 
                                child: Text(isLogin ? "Create Account" : "Login Instead", style: TextStyle(color: colorScheme.primary))
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String hint, IconData icon, bool isPass, {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15), 
      child: TextField(
        controller: controller, 
        obscureText: isPass ? _obscureText : false,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint, 
          prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary), 
          suffixIcon: isPass ? IconButton(
            icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off, color: Theme.of(context).colorScheme.primary), 
            onPressed: () => setState(() => _obscureText = !_obscureText)
          ) : null,
        )
      )
    );
  }
}