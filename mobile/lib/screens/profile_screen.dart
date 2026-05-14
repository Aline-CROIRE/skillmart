import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';
import '../main.dart';
import '../theme.dart';
import 'auth_screen.dart';
import 'transaction_history_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = "User";
  String _email = "";
  String _avatarUrl = "";
  int _balance = 0;
  bool _isLoading = true;
  bool _isUploading = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final profile = await ApiService().getProfile(token);
      if (mounted && profile != null) {
        setState(() {
          _name = profile['name'] ?? "Member";
          _email = profile['email'] ?? "";
          _avatarUrl = profile['avatar'] ?? "";
          _balance = profile['walletBalance'] ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null) return;

    setState(() => _isUploading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    
    final response = await ApiService().updateAvatar(result.files.first, token);
    if (mounted) {
      setState(() {
        _isUploading = false;
        if (response != null) {
          _avatarUrl = response['avatar'] ?? "";
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile picture updated!"), backgroundColor: Colors.green));
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Account Management"), 
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            children: [
              _buildProfileHeader(colorScheme),
              const SizedBox(height: 25),
              
              _sectionHeader("Finances"),
              _buildWalletCard(isDark),
              const SizedBox(height: 20),
              _tile("Transaction History", Icons.history, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionHistoryScreen()));
              }),
              
              const SizedBox(height: 25),
              _sectionHeader("Appearance"),
              _buildThemeToggle(isDark, colorScheme),
              
              const SizedBox(height: 25),
              _sectionHeader("Security & Preferences"),
              _tile("Edit Profile", Icons.edit_note, () {}),
              _tile("Change Password", Icons.lock_outline, () {}),
              _tile("Privacy Settings", Icons.security, () {}),
              
              const SizedBox(height: 25),
              _sectionHeader("Support"),
              _tile("Help Center", Icons.help_outline, () {}),
              _tile("About SkillMart", Icons.info_outline, () {}),
              
              const SizedBox(height: 30),
              _tile("Logout", Icons.logout, _handleLogout, color: Colors.red),
              const SizedBox(height: 50),
            ],
          ),
    );
  }

  Widget _buildProfileHeader(ColorScheme colorScheme) {
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 55,
              backgroundColor: colorScheme.primary.withOpacity(0.1),
              backgroundImage: _avatarUrl.isNotEmpty ? NetworkImage(_avatarUrl) : null,
              child: _avatarUrl.isEmpty 
                ? Icon(Icons.person, size: 55, color: colorScheme.primary)
                : null,
            ),
            if (_isUploading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                  child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                ),
              ),
            Positioned(
              bottom: 0, right: 0,
              child: InkWell(
                onTap: _isUploading ? null : _pickAndUploadAvatar,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                  child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Text(_name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
        Text(_email, style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5))),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12, 
          fontWeight: FontWeight.bold, 
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.2
        ),
      ),
    );
  }

  Widget _buildThemeToggle(bool isDark, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
      ),
      child: SwitchListTile(
        title: const Text("Dark Mode", style: TextStyle(fontWeight: FontWeight.bold)),
        secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: colorScheme.primary),
        value: isDark,
        onChanged: (val) {
          SkillMartApp.of(context).toggleTheme();
        },
      ),
    );
  }

  Widget _buildWalletCard(bool isDark) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Wallet Balance", style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 13)),
              const SizedBox(height: 5),
              Text("RWF $_balance", style: TextStyle(color: colorScheme.onSurface, fontSize: 24, fontWeight: FontWeight.w900)),
            ],
          ),
          IconButton(
            onPressed: () async {
               final prefs = await SharedPreferences.getInstance();
               await ApiService().addFunds(100000, prefs.getString('token')!);
               _load(); 
            },
            icon: Icon(Icons.add_circle, color: colorScheme.primary, size: 40),
          )
        ],
      ),
    );
  }

  Widget _tile(String t, IconData i, VoidCallback onTap, {Color? color}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(15),
        ),
        child: ListTile(
          onTap: onTap,
          leading: Icon(i, color: color ?? colorScheme.primary),
          title: Text(t, style: TextStyle(color: color ?? colorScheme.onSurface, fontWeight: FontWeight.w600)),
          trailing: const Icon(Icons.chevron_right, size: 20),
        ),
      ),
    );
  }

  void _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
  }
}