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
    if (!isLogin && _pass.text != _confirmPass.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = isLogin 
          ? await _api.login(_email.text, _pass.text)
          : await _api.register(_name.text, _email.text, _pass.text, "User");

      if (mounted && res != null) {
        final prefs = await SharedPreferences.getInstance();
        
        // CRITICAL FIX: Save everything returned by the backend
        await prefs.setString('token', res['token'] ?? '');
        await prefs.setString('role', res['role'] ?? 'User');
        await prefs.setString('userName', res['name'] ?? 'User');
        await prefs.setString('userId', res['_id'] ?? ''); // SAVE DATABASE ID

        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainMenuScreen()));
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid Credentials")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity, height: double.infinity,
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF0056b3), Color(0xFF002a5a)])),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/logo.png', height: 80),
                  const SizedBox(height: 20),
                  if (!isLogin) _buildField(_name, "Full Name", Icons.person, false),
                  _buildField(_email, "Email", Icons.email, false),
                  _buildField(_pass, "Password", Icons.lock, true),
                  if (!isLogin) _buildField(_confirmPass, "Confirm Password", Icons.lock_outline, true),
                  const SizedBox(height: 25),
                  _isLoading ? const CircularProgressIndicator() : 
                  SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0056b3)),
                    onPressed: _submit, 
                    child: Text(isLogin ? "LOGIN" : "REGISTER", style: const TextStyle(color: Colors.white))
                  )),
                  TextButton(onPressed: () => setState(() => isLogin = !isLogin), child: Text(isLogin ? "Create Account" : "Login Instead"))
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String hint, IconData icon, bool isPass) {
    return Padding(padding: const EdgeInsets.only(bottom: 15), child: TextField(controller: controller, obscureText: isPass ? _obscureText : false, decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon), suffixIcon: isPass ? IconButton(icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _obscureText = !_obscureText)) : null, filled: true, fillColor: Colors.blue[50], border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))));
  }
}