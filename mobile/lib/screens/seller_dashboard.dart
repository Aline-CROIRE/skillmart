import 'package:flutter/material.dart';
import '../models/project_model.dart';
import '../services/api_service.dart';

class SellerDashboard extends StatefulWidget {
  const SellerDashboard({super.key});

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> {
  final ApiService _apiService = ApiService();
  final String sellerId = "user_flutter_mobile";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Projects')),
      body: FutureBuilder<List<Project>>(
        future: _apiService.getSellerProjects(sellerId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final projects = snapshot.data!;
          return ListView.builder(
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final p = projects[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(p.title),
                  subtitle: Text('Status: ${p.status.toUpperCase()}'),
                  trailing: Icon(
                    p.status == 'approved' ? Icons.check_circle : Icons.pending,
                    color: p.status == 'approved' ? Colors.green : Colors.orange,
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