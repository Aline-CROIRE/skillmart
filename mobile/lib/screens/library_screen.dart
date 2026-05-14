import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project_model.dart';
import '../services/api_service.dart';
import 'project_details_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final ApiService _api = ApiService();
  List<Project> _myCollection = [];
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final data = await _api.getUserLibrary(prefs.getString('token') ?? '');
    if (mounted) setState(() { _myCollection = data; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text("My Learnings", style: TextStyle(fontWeight: FontWeight.bold))),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _myCollection.isEmpty 
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _myCollection.length,
              itemBuilder: (context, i) => _buildCollectionCard(_myCollection[i]),
            ),
    );
  }

  Widget _buildCollectionCard(Project p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: InkWell(
        borderRadius: BorderRadius.circular(25),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProjectDetailsScreen(project: p, isOwned: true))),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              Container(
                height: 60, width: 60,
                decoration: BoxDecoration(color: const Color(0xFFE1EFFE), borderRadius: BorderRadius.circular(15)),
                child: const Icon(Icons.done_all_rounded, color: Color(0xFF0056b3)),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const Text("Full access unlocked", style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_add_outlined, size: 70, color: Colors.blueGrey[100]),
          const SizedBox(height: 20),
          const Text("Your collection is waiting", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Text("Explore projects to add them here."),
        ],
      ),
    );
  }
}