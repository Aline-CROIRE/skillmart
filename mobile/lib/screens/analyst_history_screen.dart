import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project_model.dart';
import '../services/api_service.dart';
import '../theme.dart';

class AnalystHistoryScreen extends StatefulWidget {
  const AnalystHistoryScreen({super.key});
  @override
  State<AnalystHistoryScreen> createState() => _AnalystHistoryScreenState();
}

class _AnalystHistoryScreenState extends State<AnalystHistoryScreen> {
  final ApiService _api = ApiService();
  List<Project> _history = [];
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final data = await _api.getAnalystHistory(token);
      if (mounted) {
        setState(() {
          _history = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Submitted Projects"),
        centerTitle: true,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _fetch,
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
            ? Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_outlined, size: 80, color: Colors.grey.withOpacity(0.5)),
                  const SizedBox(height: 15),
                  const Text("No submitted projects yet", style: TextStyle(color: Colors.grey)),
                ],
              ))
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _history.length,
                itemBuilder: (context, i) => _buildHistoryCard(_history[i]),
              ),
      ),
    );
  }

  Widget _buildHistoryCard(Project p) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: _getStatusColor(p.status).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(_getStatusIcon(p.status), color: _getStatusColor(p.status)),
        ),
        title: Text(p.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            Text("Status: ${p.status.replaceAll('_', ' ').toUpperCase()}", 
              style: TextStyle(color: _getStatusColor(p.status), fontSize: 12, fontWeight: FontWeight.bold)),
            if (p.reviewNote != null && p.reviewNote!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text("Note: ${p.reviewNote}", maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
      case 'pending_approval': return Colors.green;
      case 'needs_changes': return Colors.orange;
      case 'rejected': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'approved':
      case 'pending_approval': return Icons.check_circle_outline;
      case 'needs_changes': return Icons.edit_note;
      case 'rejected': return Icons.cancel_outlined;
      default: return Icons.help_outline;
    }
  }
}
