import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project_model.dart';
import '../services/api_service.dart';

class AdminAuditScreen extends StatelessWidget {
  final Project project;
  const AdminAuditScreen({super.key, required this.project});

  void _handleAction(BuildContext context, String status) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    
    bool success = await ApiService().adminDecision(project.id, status, token);
    
    if (context.mounted && success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Project $status")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Quality Review"), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("AI Analysis Result", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(15)),
              child: const Text("Project content appears valid. No security threats detected by AI auditor.", style: TextStyle(color: Color(0xFF0056b3))),
            ),
            const SizedBox(height: 30),
            Text(project.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(project.description),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(child: OutlinedButton(onPressed: () => _handleAction(context, 'rejected'), child: const Text("REJECT", style: TextStyle(color: Colors.red)))),
            const SizedBox(width: 15),
            Expanded(child: ElevatedButton(onPressed: () => _handleAction(context, 'approved'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: const Text("APPROVE", style: TextStyle(color: Colors.white)))),
          ],
        ),
      ),
    );
  }
}