import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project_model.dart';
import '../services/api_service.dart';
import 'project_details_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});
  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final ApiService _api = ApiService();
  List<Project> _projects = [];
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('userId'); // Get my ID
    
    // API now filters out my creations and my purchases automatically
    final data = await _api.getAllProjects(userId: uid);
    
    if (mounted) setState(() { _projects = data; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: _fetch,
        child: CustomScrollView(
          slivers: [
            _buildHeader(),
            _isLoading 
              ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
              : _projects.isEmpty 
                ? _buildDiscoveryEmptyState() 
                : _buildProjectGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() => SliverAppBar(
    expandedHeight: 120, pinned: true, elevation: 0,
    flexibleSpace: FlexibleSpaceBar(
      title: const Text("Explore Excellence", style: TextStyle(fontWeight: FontWeight.bold)),
      background: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF0056b3), Color(0xFF002a5a)]))),
    ),
  );

  Widget _buildProjectGrid() => SliverPadding(
    padding: const EdgeInsets.all(20),
    sliver: SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, mainAxisSpacing: 15, crossAxisSpacing: 15, childAspectRatio: 0.72,
      ),
      delegate: SliverChildBuilderDelegate((context, i) => _card(_projects[i]), childCount: _projects.length),
    ),
  );

  Widget _card(Project p) => InkWell(
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProjectDetailsScreen(project: p))).then((_) => _fetch()),
    child: Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Container(width: double.infinity, decoration: const BoxDecoration(color: Color(0xFFF1F5F9), borderRadius: BorderRadius.vertical(top: Radius.circular(20))), child: const Icon(Icons.auto_stories, color: Color(0xFF0056b3)))),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.title, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1),
              Text("RWF ${p.price}", style: const TextStyle(color: Color(0xFF0056b3), fontWeight: FontWeight.w900)),
            ]),
          )
        ],
      ),
    ),
  );

  Widget _buildDiscoveryEmptyState() => const SliverFillRemaining(
    child: Center(child: Text("You've seen everything! Check back later.")),
  );
}