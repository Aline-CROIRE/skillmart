import 'package:flutter/material.dart';
import 'screens/upload_screen.dart';
import 'screens/seller_dashboard.dart';
import 'screens/admin_dashboard.dart';

void main() {
  runApp(const SkillMartApp());
}

class SkillMartApp extends StatelessWidget {
  const SkillMartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SkillMart AI')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const UploadScreen())),
              icon: const Icon(Icons.add),
              label: const Text('Submit New Project'),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SellerDashboard())),
              icon: const Icon(Icons.dashboard),
              label: const Text('Seller Dashboard'),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminDashboard())),
              icon: const Icon(Icons.admin_panel_settings),
              label: const Text('Admin Dashboard'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[50]),
            ),
          ],
        ),
      ),
    );
  }
}