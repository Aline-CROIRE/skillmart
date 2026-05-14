import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
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
  final ApiService _api = ApiService();

  Future<void> _submit() async {
    // 1. Basic Validation
    if (!isLogin && _pass.text != _confirmPass.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match"), backgroundColor: Colors.red),
      );
      return;
    }

    if (_email.text.isEmpty || _pass.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic>? res;

      if (isLogin) {
        res = await _api.login(_email.text, _pass.text);
      } else {
        // New users default to 'User' role
        res = await _api.register(_name.text, _email.text, _pass.text, "User");
      }

      if (mounted && res != null) {
        // 2. Persist User Data (Token, Role, Name)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', res['token'] ?? '');
        await prefs.setString('role', res['role'] ?? 'User');
        await prefs.setString('userName', res['name'] ?? 'Friend');

        // 3. Navigate to the Smart Home Screen
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (_) => MainMenuScreen())
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Authentication failed. Check your details.")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0056b3), Color(0xFF002a5a)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/logo.png', height: 80),
                  const SizedBox(height: 20),
                  Text(
                    isLogin ? "Welcome Back" : "Join the Community",
                    style: const TextStyle(
                      fontSize: 24, 
                      fontWeight: FontWeight.bold, 
                      color: Color(0xFF0056b3)
                    ),
                  ),
                  const SizedBox(height: 25),
                  if (!isLogin) _buildField(_name, "Full Name", Icons.person, false),
                  _buildField(_email, "Email Address", Icons.email, false),
                  _buildField(_pass, "Password", Icons.lock, true),
                  if (!isLogin) _buildField(_confirmPass, "Confirm Password", Icons.lock_outline, true),
                  const SizedBox(height: 25),
                  _isLoading 
                    ? const CircularProgressIndicator(color: Color(0xFF0056b3))
                    : SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0056b3),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          onPressed: _submit,
                          child: Text(
                            isLogin ? "LOGIN" : "CREATE ACCOUNT", 
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                          ),
                        ),
                      ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => setState(() => isLogin = !isLogin),
                    child: Text(
                      isLogin ? "Don't have an account? Register" : "Already have an account? Login",
                      style: const TextStyle(color: Color(0xFF0056b3)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String hint, IconData icon, bool isPassword) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _obscureText : false,
        style: const TextStyle(color: Color(0xFF002a5a)),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFF0056b3)),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off, color: const Color(0xFF0056b3)),
                  onPressed: () => setState(() => _obscureText = !_obscureText),
                )
              : null,
          filled: true,
          fillColor: const Color(0xFFF1F5F9),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}