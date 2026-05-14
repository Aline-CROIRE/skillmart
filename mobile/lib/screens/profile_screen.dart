import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'auth_screen.dart';
import 'transaction_history_screen.dart'; // IMPORT THIS

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = "User";
  int _balance = 0;
  bool _isLoading = true;

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
          _balance = profile['walletBalance'] ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text("My Wallet"), elevation: 0),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(25),
            children: [
              _buildWalletCard(),
              const SizedBox(height: 30),
              // NAVIGATION FIXED HERE
              _tile("Transaction History", Icons.history, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionHistoryScreen()));
              }),
              _tile("Logout", Icons.logout, _handleLogout, color: Colors.red),
            ],
          ),
    );
  }

  Widget _buildWalletCard() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0056b3), Color(0xFF002a5a)]),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Available Balance", style: TextStyle(color: Colors.white70)),
          Text("RWF $_balance", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
               final prefs = await SharedPreferences.getInstance();
               await ApiService().addFunds(100000, prefs.getString('token')!);
               _load(); // Refresh balance
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF0056b3)),
            child: const Text("ADD RWF 100,000"),
          )
        ],
      ),
    );
  }

  Widget _tile(String t, IconData i, VoidCallback onTap, {Color? color}) => ListTile(
    onTap: onTap,
    leading: Icon(i, color: color ?? const Color(0xFF002a5a)),
    title: Text(t, style: TextStyle(color: color ?? const Color(0xFF002a5a), fontWeight: FontWeight.bold)),
    trailing: const Icon(Icons.chevron_right),
  );

  void _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
  }
}