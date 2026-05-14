import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project_model.dart';
import '../services/api_service.dart';
import 'upload_screen.dart';

class MyProjectsScreen extends StatefulWidget {
  const MyProjectsScreen({super.key});
  @override
  State<MyProjectsScreen> createState() => _MyProjectsScreenState();
}

class _MyProjectsScreenState extends State<MyProjectsScreen> {
  final ApiService _api = ApiService();
  List<Project> _myWork = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final userId = prefs.getString('userId') ?? '';
      
      final data = await _api.getSellerProjects(userId, token);
      if (mounted) setState(() { _myWork = data; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("My Creations", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [IconButton(onPressed: _fetch, icon: const Icon(Icons.refresh))],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _myWork.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _fetch,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _myWork.length,
                    itemBuilder: (context, i) => _projectCard(_myWork[i]),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadScreen())).then((_) => _fetch()),
        backgroundColor: const Color(0xFF0056b3),
        label: const Text("New Creation", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmpty() => const Center(
    child: Text("You haven't shared anything yet. Start today!"),
  );

  Widget _projectCard(Project p) {
    bool needsWork = p.status == 'needs_changes';
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(p.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                _statusBadge(p.status),
              ],
            ),
            const SizedBox(height: 5),
            Text(p.category, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            if (needsWork) ...[
              const SizedBox(height: 15),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Analyst Feedback:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                    const SizedBox(height: 5),
                    Text(p.reviewNote, style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (_) => UploadScreen(existingProject: p))
                  ).then((_) => _fetch()),
                  icon: const Icon(Icons.edit_document, size: 18),
                  label: const Text("FIX & RESUBMIT"),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0056b3), foregroundColor: Colors.white),
                ),
              )
            ],
            if (p.status == 'approved') ...[
               const Divider(height: 30),
               Text("Earnings: RWF ${p.price}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            ]
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    String label = "Pending"; Color color = Colors.orange;
    if (status == 'approved') { label = "Verified"; color = Colors.green; }
    if (status == 'needs_changes') { label = "Needs Work"; color = Colors.orange; }
    if (status == 'rejected') { label = "Declined"; color = Colors.red; }
    if (status == 'under_review') { label = "In Review"; color = Colors.blue; }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withAlpha(30), borderRadius: BorderRadius.circular(8)),
      child: Text(label.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}