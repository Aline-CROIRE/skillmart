import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  final String initialName;
  final String initialEmail;
  final String initialPhoneNumber;
  final String initialBio;
  final bool emailVerified;

  const EditProfileScreen({
    super.key,
    required this.initialName,
    required this.initialEmail,
    required this.initialPhoneNumber,
    required this.initialBio,
    required this.emailVerified,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = ApiService();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _bioCtrl;
  final _codeCtrl = TextEditingController();

  bool _emailVerified = false;
  bool _saving = false;
  bool _sendingCode = false;
  bool _verifying = false;
  bool _codeSent = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
    _emailCtrl = TextEditingController(text: widget.initialEmail);
    _phoneCtrl = TextEditingController(text: widget.initialPhoneNumber);
    _bioCtrl = TextEditingController(text: widget.initialBio);
    _emailVerified = widget.emailVerified;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _bioCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<String> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final token = await _token();
      final updated = await _api.updateProfileInfo({
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phoneNumber': _phoneCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
      }, token);

      if (!mounted) return;
      final emailChanged = _emailCtrl.text.trim().toLowerCase() !=
          widget.initialEmail.trim().toLowerCase();

      setState(() {
        _emailVerified = updated['emailVerified'] == true;
        if (emailChanged) {
          _codeSent = false;
          _codeCtrl.clear();
        }
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', updated['name'] ?? _nameCtrl.text.trim());

      _snack('Profile updated successfully');
      Navigator.pop(context, updated);
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _sendVerificationCode() async {
    setState(() => _sendingCode = true);
    try {
      final token = await _token();
      final message = await _api.sendEmailVerification(token);
      if (mounted) {
        setState(() => _codeSent = true);
        _snack(message);
      }
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _sendingCode = false);
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeCtrl.text.trim();
    if (code.length != 6) {
      _snack('Enter the 6-digit code from your email', error: true);
      return;
    }

    setState(() => _verifying = true);
    try {
      final token = await _token();
      final result = await _api.verifyEmail(token, code);
      if (!mounted) return;

      setState(() {
        _emailVerified = true;
        _codeSent = false;
        _codeCtrl.clear();
      });

      _snack(result['message'] ?? 'Email verified');
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _sectionLabel('Profile Information'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Full name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email is required';
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone_outlined),
                hintText: 'e.g., +250 788 000 000',
              ),
              keyboardType: TextInputType.phone,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Phone number is required for verification' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bioCtrl,
              decoration: const InputDecoration(
                labelText: 'Bio (optional)',
                prefixIcon: Icon(Icons.info_outline),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              maxLength: 300,
            ),
            const SizedBox(height: 24),
            _sectionLabel('Email Verification (optional)'),
            const SizedBox(height: 8),
            Text(
              'Verifying your email helps secure your account. You can skip this and verify anytime.',
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.6),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            _buildVerificationCard(colorScheme),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _saving ? null : _saveProfile,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildVerificationCard(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: colorScheme.primary.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _emailVerified ? Icons.verified : Icons.mark_email_unread_outlined,
                color: _emailVerified ? Colors.green : colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _emailVerified ? 'Email verified' : 'Email not verified',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              if (_emailVerified)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Verified',
                    style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          if (!_emailVerified) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _sendingCode ? null : _sendVerificationCode,
              icon: _sendingCode
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_outlined, size: 18),
              label: Text(_codeSent ? 'Resend code' : 'Send verification code'),
            ),
            if (_codeSent) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _codeCtrl,
                decoration: const InputDecoration(
                  labelText: '6-digit code',
                  prefixIcon: Icon(Icons.pin_outlined),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _verifying ? null : _verifyCode,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                child: _verifying
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Verify email'),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
