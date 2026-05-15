import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _api = ApiService();

  int _step = 1; // 1: Email, 2: Code & New Password
  bool _isLoading = false;

  void _snack(String m, {bool err = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: err ? Colors.red : Colors.green));
  }

  Future<void> _requestReset() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _snack('Please enter a valid email', err: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final msg = await _api.forgotPassword(email);
      _snack(msg);
      setState(() => _step = 2);
    } catch (e) {
      _snack(e.toString(), err: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitReset() async {
    final code = _codeCtrl.text.trim();
    final pass = _passCtrl.text;
    final confirm = _confirmPassCtrl.text;

    if (code.length != 6) {
      _snack('Enter the 6-digit code', err: true);
      return;
    }
    if (pass.length < 6) {
      _snack('Password must be at least 6 characters', err: true);
      return;
    }
    if (pass != confirm) {
      _snack('Passwords do not match', err: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final msg = await _api.resetPassword(_emailCtrl.text.trim(), code, pass);
      _snack(msg);
      Navigator.pop(context);
    } catch (e) {
      _snack(e.toString(), err: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/background.webp', fit: BoxFit.cover)),
          Positioned.fill(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(color: Colors.black.withOpacity(0.4)))),
          SafeArea(
            child: Column(
              children: [
                Align(alignment: Alignment.topLeft, child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context))),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.all(30),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface.withOpacity(isDark ? 0.6 : 0.85),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.white.withOpacity(0.2)),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.lock_reset, size: 60, color: Colors.blue),
                                const SizedBox(height: 15),
                                Text(_step == 1 ? "Forgot Password" : "Reset Password", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 10),
                                Text(
                                  _step == 1 
                                    ? "Enter your email to receive a 6-digit recovery code." 
                                    : "Enter the code from your email and your new password.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                                ),
                                const SizedBox(height: 25),
                                if (_step == 1) ...[
                                  _buildField(_emailCtrl, "Email Address", Icons.email, false),
                                  const SizedBox(height: 20),
                                  _isLoading ? const CircularProgressIndicator() : SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _requestReset, child: const Text("SEND CODE"))),
                                ] else ...[
                                  _buildField(_codeCtrl, "6-Digit Code", Icons.pin, false, isNum: true),
                                  _buildField(_passCtrl, "New Password", Icons.lock, true),
                                  _buildField(_confirmPassCtrl, "Confirm Password", Icons.lock_outline, true),
                                  const SizedBox(height: 20),
                                  _isLoading ? const CircularProgressIndicator() : SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _submitReset, child: const Text("RESET PASSWORD"))),
                                  TextButton(onPressed: () => setState(() => _step = 1), child: const Text("Change Email")),
                                ]
                              ],
                            ),
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

  Widget _buildField(TextEditingController ctrl, String hint, IconData icon, bool isPass, {bool isNum = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: ctrl,
        obscureText: isPass,
        keyboardType: isNum ? TextInputType.number : TextInputType.emailAddress,
        inputFormatters: isNum ? [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)] : null,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
      ),
    );
  }
}
