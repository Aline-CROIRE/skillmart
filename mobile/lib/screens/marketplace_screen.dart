import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/project_model.dart';
import '../services/api_service.dart';
import '../theme.dart';
import 'project_details_screen.dart';
import 'notification_screen.dart';

import '../widgets/notification_bell.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});
  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final ApiService _api = ApiService();
  List<Project> _projects = [];
  bool _isLoading = true;
  String _currentUserId = "";

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('userId') ?? "";
    
    final data = await _api.getAllProjects(userId: uid);
    
    if (mounted) {
      setState(() {
        _projects = data;
        _isLoading = false;
        _currentUserId = uid;
      });
    }
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
      actions: [
        NotificationBell(color: isDark ? Colors.white : Colors.black),
        const SizedBox(width: 10),
      ],
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
    bool isMine = p.sellerId == _currentUserId;
    bool isApproved = p.status == 'approved';
    bool needsWork = p.status == 'needs_changes';
    
    String badgeText = "PENDING";
    Color badgeColor = Colors.orange;

    if (isApproved) {
      badgeText = "VERIFIED";
      badgeColor = Colors.green;
    } else if (needsWork) {
      badgeText = isMine ? "REVIEW" : "PENDING";
      badgeColor = isMine ? Theme.of(context).colorScheme.primary : Colors.orange;
    } else if (p.status == 'under_review') {
      badgeText = "IN REVIEW";
      badgeColor = Colors.blue;
    }

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
                        ? CachedNetworkImage(
                            imageUrl: p.thumbnailUrl.startsWith('http') ? p.thumbnailUrl : "https://skillmart-api.onrender.com${p.thumbnailUrl}",
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            errorWidget: (context, url, error) => Center(
                              child: Icon(Icons.broken_image_outlined, color: colorScheme.primary.withOpacity(0.3)),
                            ),
                          )
                        : Icon(Icons.auto_stories, color: colorScheme.primary),
                    ),
                  ),
                  if (p.status != 'approved')
                    Positioned(
                      top: 10, right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(10)),
                        child: Text(badgeText, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
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
                !isApproved 
                  ? Text("Awaiting Analytics", style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5), fontSize: 11))
                  : Text("RWF ${p.price}", style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w900, fontSize: 14)),
              ]),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoveryEmptyState(BuildContext context) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 80, color: Theme.of(context).colorScheme.primary.withOpacity(0.1)),
            const SizedBox(height: 20),
            const Text("No projects found", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text("Try searching for something else."),
          ],
        ),
      ),
    );
  }
}