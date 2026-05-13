import 'package:flutter/material.dart';
import '../models/project_model.dart';
import '../services/api_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final ApiService _apiService = ApiService();

  void _handleDecision(String id, String status) async {
    bool success = await _apiService.adminDecision(id, status);
    if (success) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Project $status')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Review Queue')),
      body: FutureBuilder<List<Project>>(
        future: _apiService.getAdminQueue(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final projects = snapshot.data!;
          if (projects.isEmpty) return const Center(child: Text('No projects to review'));
          
          return ListView.builder(
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final p = projects[index];
              return Card(
                child: ListTile(
                  title: Text(p.title),
                  subtitle: Text(p.description),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: () => _handleDecision(p.id, 'approved')),
                      IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => _handleDecision(p.id, 'rejected')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}