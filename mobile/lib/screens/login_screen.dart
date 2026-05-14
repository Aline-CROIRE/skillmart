import 'package:flutter/material.dart';
import '../theme.dart'; // Ensure this matches your file path

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLogin = true;
  final _emailController = TextEditingController();
  final _passController = TextEditingController();

  void _handleAuth() {
    debugPrint("Email: ${_emailController.text}");
    // Integration logic goes here later
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: SkillMartTheme.gradient),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("SkillMart", 
                    style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 40),
                TextField(
                  controller: _emailController, 
                  decoration: const InputDecoration(hintText: "Email", prefixIcon: Icon(Icons.email))
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passController, 
                  obscureText: true, 
                  decoration: const InputDecoration(hintText: "Password", prefixIcon: Icon(Icons.lock))
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _handleAuth,
                    child: Text(isLogin ? "LOGIN" : "REGISTER"),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => isLogin = !isLogin),
                  child: Text(isLogin ? "Need an account? Register" : "Have an account? Login", 
                      style: const TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}