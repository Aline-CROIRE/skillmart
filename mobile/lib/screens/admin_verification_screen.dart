import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project_model.dart';
import '../services/api_service.dart';
import 'admin_audit_screen.dart';

class AdminVerificationScreen extends StatefulWidget {
  const AdminVerificationScreen({super.key});

  @override
  State<AdminVerificationScreen> createState() => _AdminVerificationScreenState();
}

class _AdminVerificationScreenState extends State<AdminVerificationScreen> {
  final ApiService _api = ApiService();
  List<Project> _queue = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final data = await _api.getAdminQueue(token);
    if (mounted) {
      setState(() {
        _queue = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Verification Queue", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0056b3),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _queue.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetch,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _queue.length,
                    itemBuilder: (context, i) => _buildProjectCard(_queue[i]),
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text("No projects pending review", style: TextStyle(color: Colors.grey, fontSize: 16)),
    );
  }

  Widget _buildProjectCard(Project p) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE1EFFE),
          child: Icon(Icons.pending_actions, color: Color(0xFF0056b3)),
        ),
        title: Text(p.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Category: ${p.category}"),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AdminAuditScreen(project: p)),
          ).then((_) => _fetch());
        },
      ),
    );
  }
}