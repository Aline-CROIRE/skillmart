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
    final uid = prefs.getString('userId'); 
    
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
        crossAxisCount: 2, mainAxisSpacing: 15, crossAxisSpacing: 15, childAspectRatio: 0.7,
      ),
      delegate: SliverChildBuilderDelegate((context, i) => _card(_projects[i], context), childCount: _projects.length),
    ),
  );

  Widget _card(Project p, BuildContext context) {
    final isPending = p.status != 'approved';
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProjectDetailsScreen(project: p))).then((_) => _fetch()),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface, 
          borderRadius: BorderRadius.circular(20), 
          boxShadow: [BoxShadow(color: Theme.of(context).shadowColor.withOpacity(0.05), blurRadius: 10)]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: Container(
                      color: colorScheme.primary.withOpacity(0.05),
                      width: double.infinity,
                      height: double.infinity,
                      child: p.thumbnailUrl.isNotEmpty 
                        ? Image.network(
                            p.thumbnailUrl.startsWith('http') ? p.thumbnailUrl : "https://skillmart-api.onrender.com${p.thumbnailUrl}",
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                            },
                            errorBuilder: (context, error, stackTrace) => Center(
                              child: Icon(Icons.broken_image_outlined, color: colorScheme.primary.withOpacity(0.3)),
                            ),
                          )
                        : Icon(Icons.auto_stories, color: colorScheme.primary),
                    ),
                  ),
                  if (isPending)
                    Positioned(
                      top: 10, right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(10)),
                        child: const Text("PENDING", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              )
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.title, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                isPending 
                  ? Text("Awaiting Analytics", style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5), fontSize: 11))
                  : Text("RWF ${p.price}", style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w900, fontSize: 14)),
              ]),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoveryEmptyState(BuildContext context) => SliverFillRemaining(
    child: Center(child: Text("You've seen everything! Check back later.", style: TextStyle(color: Theme.of(context).colorScheme.onSurface))),
  );
}