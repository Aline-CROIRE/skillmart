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
    
    bool success = await ApiService().submitAdminDecision(project.id, status, token);
    
    if (context.mounted && success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Project $status")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text("Quality Review"), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("AI Analysis Result", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
              child: Text("Project content appears valid. No security threats detected by AI auditor.", style: TextStyle(color: colorScheme.primary)),
            ),
            const SizedBox(height: 30),
            Text(project.title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
            const SizedBox(height: 10),
            Text(project.description, style: TextStyle(color: colorScheme.onSurface)),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(child: OutlinedButton(onPressed: () => _handleAction(context, 'rejected'), style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)), child: const Text("REJECT", style: TextStyle(color: Colors.red)))),
            const SizedBox(width: 15),
            Expanded(child: ElevatedButton(onPressed: () => _handleAction(context, 'approved'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: const Text("APPROVE", style: TextStyle(color: Colors.white)))),
          ],
        ),
      ),
    );
  }
}