import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project_model.dart';
import '../services/api_service.dart';
import '../theme.dart';
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _fetch,
        child: CustomScrollView(
          slivers: [
            _buildHeader(context),
            _isLoading 
              ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
              : _projects.isEmpty 
                ? _buildDiscoveryEmptyState(context) 
                : _buildProjectGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SliverAppBar(
      expandedHeight: 120, pinned: true, elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: Text("Explore Excellence", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
        background: Container(decoration: BoxDecoration(gradient: isDark ? SkillMartTheme.darkGradient : SkillMartTheme.lightBackgroundGradient)),
      ),
    );
  }

  Widget _buildProjectGrid() => SliverPadding(
    padding: const EdgeInsets.all(20),
    sliver: SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, mainAxisSpacing: 15, crossAxisSpacing: 15, childAspectRatio: 0.72,
      ),
      delegate: SliverChildBuilderDelegate((context, i) => _card(_projects[i], context), childCount: _projects.length),
    ),
  );

  Widget _card(Project p, BuildContext context) => InkWell(
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProjectDetailsScreen(project: p))).then((_) => _fetch()),
    child: Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface, 
        borderRadius: BorderRadius.circular(20), 
        boxShadow: [BoxShadow(color: Theme.of(context).shadowColor.withOpacity(0.05), blurRadius: 10)]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity, 
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.05), 
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20))
              ), 
              child: Icon(Icons.auto_stories, color: Theme.of(context).colorScheme.primary)
            )
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.title, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface), maxLines: 1),
              Text("RWF ${p.price}", style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w900)),
            ]),
          )
        ],
      ),
    ),
  );

  Widget _buildDiscoveryEmptyState(BuildContext context) => SliverFillRemaining(
    child: Center(child: Text("You've seen everything! Check back later.", style: TextStyle(color: Theme.of(context).colorScheme.onSurface))),
  );
}