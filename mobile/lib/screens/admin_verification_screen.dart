import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project_model.dart';
import '../services/api_service.dart';
import '../theme.dart';
import 'admin_audit_screen.dart';
import '../widgets/notification_bell.dart';
import 'admin_broadcast_screen.dart';
import 'admin_newsletter_screen.dart';
import 'admin_notification_history_screen.dart';

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
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final data = await _api.getAdminQueue(token);
      if (mounted) {
        setState(() {
          _queue = data;
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
      body: RefreshIndicator(
        onRefresh: _fetch,
        child: CustomScrollView(
          slivers: [
            _buildPremiumHeader(context),
            _buildStatsSection(context),
            _isLoading
                ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
                : _queue.isEmpty
                    ? _buildEmptyState(context)
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) => _buildProjectCard(_queue[i], context),
                            childCount: _queue.length,
                          ),
                        ),
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SliverAppBar(
      expandedHeight: 180, pinned: true, elevation: 0,
      actions: [
        NotificationBell(color: isDark ? Colors.white : Colors.black),
        const SizedBox(width: 10),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: isDark ? SkillMartTheme.darkGradient : SkillMartTheme.lightBackgroundGradient,
          ),
          padding: const EdgeInsets.fromLTRB(25, 80, 25, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Admin Panel", style: TextStyle(color: isDark ? Colors.white.withOpacity(0.7) : Colors.black54, fontSize: 16)),
                  Row(
                    children: [
                      _adminActionBtn(
                        context, 
                        "Broadcast", 
                        Icons.campaign_outlined, 
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminBroadcastScreen()))
                      ),
                      const SizedBox(width: 8),
                      _adminActionBtn(
                        context, 
                        "Newsletter", 
                        Icons.mark_as_unread_outlined, 
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminNewsletterScreen()))
                      ),
                    ],
                  ),
                ],
              ),
              Text("Final Approval Hub", style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 26, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _adminActionBtn(BuildContext context, String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Theme.of(context).shadowColor.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _stat("Pending", _queue.length.toString(), Colors.orange, context),
            _divider(context),
            _stat("System", "Healthy", Colors.green, context),
            _divider(context),
            _stat("Role", "Admin", Theme.of(context).colorScheme.primary, context),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String val, Color color, BuildContext context) => Column(
    children: [
      Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12)),
      Text(val, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: color)),
    ],
  );

  Widget _divider(BuildContext context) => Container(height: 30, width: 1, color: Theme.of(context).dividerColor);

  Widget _buildEmptyState(BuildContext context) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fact_check_outlined, size: 80, color: Theme.of(context).colorScheme.primary.withOpacity(0.1)),
            const SizedBox(height: 20),
            Text("All projects cleared!", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 18, fontWeight: FontWeight.bold)),
            const Text("No projects awaiting final approval.", style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectCard(Project p, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => AdminAuditScreen(project: p))).then((_) => _fetch());
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Theme.of(context).shadowColor.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              Container(
                height: 50, width: 50,
                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.verified_user_outlined, color: Colors.blue),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurface)),
                    Text("Ready for Final Sign-off", style: TextStyle(color: Colors.green.shade600, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }
}