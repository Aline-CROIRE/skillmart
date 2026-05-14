import 'package:flutter/material.dart';
import '../models/project_model.dart';
import '../services/api_service.dart';

class ProjectDetailsScreen extends StatelessWidget {
  final Project project;
  const ProjectDetailsScreen({super.key, required this.project});

  void _handlePurchase(BuildContext context) async {
    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Processing purchase...")),
    );

    // Call API
    bool success = await ApiService().purchaseProject(project.id, "USER_TOKEN");
    
    // Check if screen is still active before showing result
    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Success! You now have access."), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Purchase failed. Check your balance."), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Project Details"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0056b3),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200, width: double.infinity,
              decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.description_outlined, size: 80, color: Color(0xFF0056b3)),
            ),
            const SizedBox(height: 30),
            Text(project.title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(project.category, style: const TextStyle(color: Color(0xFFf48c06), fontWeight: FontWeight.bold)),
            const SizedBox(height: 25),
            const Text("Overview", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(project.description, style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.5)),
            const SizedBox(height: 120),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Full Access", style: TextStyle(color: Colors.grey)),
                  Text("RWF ${project.price}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0056b3))),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => _handlePurchase(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0056b3),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("GET STARTED", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }
}