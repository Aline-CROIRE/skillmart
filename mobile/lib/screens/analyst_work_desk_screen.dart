import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project_model.dart';
import '../services/api_service.dart';
import '../theme.dart';
import 'analyst_audit_screen.dart';

class AnalystWorkDeskScreen extends StatefulWidget {
  const AnalystWorkDeskScreen({super.key});
  @override
  State<AnalystWorkDeskScreen> createState() => _AnalystWorkDeskScreenState();
}

class _AnalystWorkDeskScreenState extends State<AnalystWorkDeskScreen> {
  final ApiService _api = ApiService();
  List<Project> _assignments = [];
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final data = await _api.getAnalystAssignments(token);
      if (mounted) {
        setState(() {
          _assignments = data;
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("My Work Desk"),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetch),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetch,
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _assignments.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _assignments.length,
                itemBuilder: (context, i) => _buildProjectCard(_assignments[i]),
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in_outlined, size: 80, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 15),
          const Text("No active assignments", style: TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 10),
          Text("Assign a project to yourself from the 'Submitted' tab.", style: TextStyle(color: Colors.grey.withOpacity(0.7), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildProjectCard(Project p) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AnalystAuditScreen(project: p))).then((_) => _fetch()),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Theme.of(context).shadowColor.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              Container(
                height: 50, width: 50,
                decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.pending_actions, color: colorScheme.primary),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text("${p.sellerName} • ${p.category}", style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5), fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
