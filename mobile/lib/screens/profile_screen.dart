import 'dart:io';
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
  File? _localAvatar;

  String _phoneNumber = "";
  String _bio = "";

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
          _phoneNumber = profile['phoneNumber'] ?? "";
          _bio = profile['bio'] ?? "";
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _editProfile() async {
    final nameCtrl = TextEditingController(text: _name);
    final bioCtrl = TextEditingController(text: _bio);
    final emailCtrl = TextEditingController(text: _email);
    final phoneCtrl = TextEditingController(text: _phoneNumber);

    final updated = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Profile"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Full Name")),
              TextField(controller: bioCtrl, decoration: const InputDecoration(labelText: "Bio")),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: "Email (Requires Verification)")),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: "Phone Number")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("SAVE CHANGES")),
        ],
      )
    );

    if (updated == true) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      
      setState(() => _isLoading = true);
      final res = await ApiService().updateProfile(
        token: token,
        name: nameCtrl.text,
        bio: bioCtrl.text,
        email: emailCtrl.text,
        phoneNumber: phoneCtrl.text,
      );

      if (mounted) {
        final msg = res?['message'] ?? "Profile updated";
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.blue));
        _load(); // Refresh
      }
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null) return;

    final pickedFile = result.files.first;
    if (pickedFile.path == null) return;

    // Show Circular Preview Dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text("Preview Profile Picture"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("This is how your avatar will look:"),
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 80,
              backgroundImage: FileImage(File(pickedFile.path!)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("CANCEL")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("USE THIS")),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isUploading = true;
      _localAvatar = File(pickedFile.path!);
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    
    final response = await ApiService().updateAvatar(pickedFile, token);
    if (mounted) {
      setState(() {
        _isUploading = false;
        if (response != null) {
          _avatarUrl = response['avatar'] ?? "";
          _localAvatar = null;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile picture updated!"), backgroundColor: Colors.green));
        }
      });
    }
  }

  void _showFullImage() {
    if (_avatarUrl.isEmpty && _localAvatar == null) return;
    
    Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.transparent, iconTheme: const IconThemeData(color: Colors.white)),
      body: Center(
        child: Hero(
          tag: 'profile_pic',
          child: _localAvatar != null 
            ? Image.file(_localAvatar!) 
            : Image.network(_avatarUrl),
        ),
      ),
    )));
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
    ImageProvider? image;
    if (_localAvatar != null) {
      image = FileImage(_localAvatar!);
    } else if (_avatarUrl.isNotEmpty) {
      image = NetworkImage(_avatarUrl);
    }

    return Column(
      children: [
        Stack(
          children: [
            GestureDetector(
              onTap: _showFullImage,
              child: Hero(
                tag: 'profile_pic',
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: colorScheme.primary.withOpacity(0.1),
                  backgroundImage: image,
                  child: image == null 
                    ? Icon(Icons.person, size: 55, color: colorScheme.primary)
                    : null,
                ),
              ),
            ),
            if (_isUploading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                  child: const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
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