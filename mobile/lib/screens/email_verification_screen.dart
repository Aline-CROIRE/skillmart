import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'dart:async';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _codeController = TextEditingController();
  
  bool _isLoading = false;
  bool _codeSent = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _codeController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _resendCooldown = 60);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown > 0) {
        setState(() => _resendCooldown--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _sendCode() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) throw "Authentication error";

      final msg = await _api.sendEmailVerification(token);
      if (mounted) {
        setState(() {
          _codeSent = true;
        });
        _startCooldown();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyCode() async {
    if (_codeController.text.trim().length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a valid 6-digit code")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) throw "Authentication error";

      await _api.verifyEmail(token, _codeController.text.trim());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Email Verified Successfully!"), backgroundColor: Colors.green));
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainMenuScreen()));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _skip() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainMenuScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Verify Email"),
        actions: [
          TextButton(
            onPressed: _skip,
            child: const Text("Skip", style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.mark_email_unread_outlined, size: 80, color: Colors.blueAccent),
              const SizedBox(height: 24),
              const Text(
                "Secure Your Account",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                "Verifying your email allows you to recover your account, receive important updates, and create projects on the platform.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: colorScheme.onSurface.withOpacity(0.7)),
              ),
              const SizedBox(height: 40),
              
              if (!_codeSent) ...[
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _sendCode,
                  icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send),
                  label: const Padding(padding: EdgeInsets.symmetric(vertical: 15), child: Text("SEND VERIFICATION CODE", style: TextStyle(fontWeight: FontWeight.bold))),
                ),
              ] else ...[
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, letterSpacing: 5, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: "000000",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _verifyCode,
                  child: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                    : const Padding(padding: EdgeInsets.symmetric(vertical: 15), child: Text("VERIFY EMAIL", style: TextStyle(fontWeight: FontWeight.bold))),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: (_isLoading || _resendCooldown > 0) ? null : _sendCode,
                  child: Text(
                    _resendCooldown > 0 ? "Resend code in ${_resendCooldown}s" : "Didn't receive code? Resend",
                    style: TextStyle(color: colorScheme.primary),
                  ),
                ),
              ],
              
              const Spacer(),
              TextButton(
                onPressed: _skip,
                child: Text("Skip for now", style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5))),
              )
            ],
          ),
        ),
      ),
    );
  }
}
