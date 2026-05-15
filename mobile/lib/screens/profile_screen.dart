import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../main.dart';
import '../theme.dart';
import 'auth_screen.dart';
import 'transaction_history_screen.dart';
import 'edit_profile_screen.dart';
import 'team_management_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _api = ApiService();
  String _name = "User";
  String _email = "";
  String _bio = "";
  String _avatarUrl = "";
  bool _emailVerified = false;
  String _role = "User";
  bool _isProfileConfirmed = false;
  String _idUrl = "";
  String _selfieUrl = "";
  int _balance = 0;
  bool _isLoading = true;
  bool _isUploading = false;
  File? _localAvatar;

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
          _bio = profile['bio'] ?? "";
          _avatarUrl = profile['avatar'] ?? "";
          _emailVerified = profile['emailVerified'] == true;
          _role = prefs.getString('role') ?? 'User';
          _isProfileConfirmed = profile['isProfileConfirmed'] == true;
          _idUrl = profile['nationalIdUrl'] ?? "";
          _selfieUrl = profile['verificationSelfieUrl'] ?? "";
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
              
              if (_role != 'Admin') ...[
                _sectionHeader("Finances"),
                _buildWalletCard(isDark),
                const SizedBox(height: 20),
                _tile("Transaction History", Icons.history, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionHistoryScreen()));
                }),
                const SizedBox(height: 25),
              ],
              
              _sectionHeader("Appearance"),
              _buildThemeToggle(isDark, colorScheme),
              
              const SizedBox(height: 25),
              _sectionHeader("Security & Preferences"),
              _tile("Edit Profile", Icons.edit_note, _openEditProfile),
              _tile("Change Password", Icons.lock_outline, _showChangePasswordDialog),
              _tile("Privacy Settings", Icons.security, () {}),
              
              if (_role == 'Analyst') ...[
                const SizedBox(height: 25),
                _sectionHeader("Vetting & Verification"),
                _tile(
                  "Upload National ID", 
                  Icons.badge_outlined, 
                  _pickAndUploadNationalId, 
                  subtitle: _idUrl.isNotEmpty ? "File Uploaded ✅" : "Action Required ⚠️"
                ),
                _tile(
                  "Verification Selfie", 
                  Icons.face_retouching_natural, 
                  _pickAndUploadVerificationSelfie,
                  subtitle: _selfieUrl.isNotEmpty ? "Selfie Uploaded ✅" : "Action Required ⚠️"
                ),
                if (_isProfileConfirmed)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: const Row(
                        children: [
                          Icon(Icons.verified_user, color: Colors.green, size: 20),
                          SizedBox(width: 10),
                          Text("Your profile is fully confirmed", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
              ],
              
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                _email,
                style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
                textAlign: TextAlign.center,
              ),
            ),
            if (_emailVerified) ...[
              const SizedBox(width: 6),
              Icon(Icons.verified, size: 18, color: Colors.green.shade600),
            ],
          ],
        ),
        if (_bio.isNotEmpty) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _bio,
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurface.withOpacity(0.55), fontSize: 14),
            ),
          ),
        ],
        if (!_emailVerified && _email.isNotEmpty) ...[
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: _openEditProfile,
            icon: const Icon(Icons.mark_email_unread_outlined, size: 18),
            label: const Text('Verify email (optional)'),
          ),
        ],
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

  Widget _tile(String t, IconData i, VoidCallback onTap, {Color? color, String? subtitle}) {
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
          subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.5))) : null,
          trailing: const Icon(Icons.chevron_right, size: 20),
        ),
      ),
    );
  }

  Future<void> _openEditProfile() async {
    final updated = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          initialName: _name,
          initialEmail: _email,
          initialBio: _bio,
          emailVerified: _emailVerified,
        ),
      ),
    );

    if (updated != null && mounted) {
      setState(() {
        _name = updated['name'] ?? _name;
        _email = updated['email'] ?? _email;
        _bio = updated['bio'] ?? '';
        _emailVerified = updated['emailVerified'] == true;
      });
    }
  }

  Future<void> _pickAndUploadNationalId() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null) return;

    setState(() => _isUploading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      await _api.uploadNationalId(result.files.first, token);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("ID Uploaded! Waiting for Admin confirmation."), backgroundColor: Colors.blue));
        _load();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  

  Future<void> _pickAndUploadVerificationSelfie() async {
    final picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);
    if (photo == null) return;

    setState(() => _isUploading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      
      // Need to convert XFile to PlatformFile for ApiService or just update ApiService to handle XFile
      // Actually, I'll update ApiService to handle path or PlatformFile consistently.
      // For now, I'll use PlatformFile from path.
      final pFile = PlatformFile(name: photo.name, path: photo.path, size: await photo.length());
      
      await _api.uploadVerificationSelfie(pFile, token);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Verification Selfie Taken & Uploaded!"), backgroundColor: Colors.blue));
        _load();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
  }

  void _showChangePasswordDialog() {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool loading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Change Password"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: oldCtrl, obscureText: true, decoration: const InputDecoration(labelText: "Current Password")),
              TextField(controller: newCtrl, obscureText: true, decoration: const InputDecoration(labelText: "New Password")),
              TextField(controller: confirmCtrl, obscureText: true, decoration: const InputDecoration(labelText: "Confirm New Password")),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
            loading ? const CircularProgressIndicator() : ElevatedButton(
              onPressed: () async {
                if (newCtrl.text != confirmCtrl.text) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
                   return;
                }
                setDialogState(() => loading = true);
                try {
                  final prefs = await SharedPreferences.getInstance();
                  final token = prefs.getString('token') ?? '';
                  await ApiService().changePassword(oldCtrl.text, newCtrl.text, token);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password updated!"), backgroundColor: Colors.green));
                  }
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
                } finally {
                  if (mounted) setDialogState(() => loading = false);
                }
              },
              child: const Text("UPDATE"),
            ),
          ],
        ),
      ),
    );
  }
}