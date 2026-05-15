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
  List<Project> _purchased = [];
  List<Project> _bookmarked = [];
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    
    final profile = await _api.getProfile(token);
    if (mounted && profile != null) {
      setState(() {
        if (profile['purchasedProjects'] != null) {
          _purchased = (profile['purchasedProjects'] as List).map((p) => Project.fromJson(p)).toList();
        }
        if (profile['bookmarkedProjects'] != null) {
          _bookmarked = (profile['bookmarkedProjects'] as List).map((p) => Project.fromJson(p)).toList();
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text("My Collection", style: TextStyle(fontWeight: FontWeight.bold))),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetch,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (_purchased.isNotEmpty) ...[
                  _sectionTitle("UNLOCKED ACCESS"),
                  ..._purchased.map((p) => _buildProjectCard(p, true)),
                  const SizedBox(height: 30),
                ],
                
                if (_bookmarked.isNotEmpty) ...[
                  _sectionTitle("BOOKMARKED"),
                  ..._bookmarked.map((p) => _buildProjectCard(p, false)),
                ],

                if (_purchased.isEmpty && _bookmarked.isEmpty)
                  _buildEmptyState(),
              ],
            ),
          ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, left: 5),
      child: Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, letterSpacing: 1.2)),
    );
  }

  Widget _buildProjectCard(Project p, bool isPurchased) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: InkWell(
        borderRadius: BorderRadius.circular(25),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProjectDetailsScreen(project: p, isOwned: isPurchased))).then((_) => _fetch()),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Theme.of(context).shadowColor.withOpacity(0.05), blurRadius: 10)],
          ),
          child: Row(
            children: [
              Container(
                height: 50, width: 50,
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(isPurchased ? Icons.check_circle : Icons.bookmark, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(isPurchased ? "Full Access Unlocked" : "Tracking Updates", style: TextStyle(color: isPurchased ? Colors.green : Colors.orange, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 100),
          Icon(Icons.bookmark_border, size: 80, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
          const SizedBox(height: 20),
          const Text("Your collection is empty", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Text("Bookmark projects to track their progress."),
        ],
      ),
    );
  }
}