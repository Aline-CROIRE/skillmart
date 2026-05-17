import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project_model.dart';
import '../services/api_service.dart';
import '../theme.dart';
import 'analyst_preview_screen.dart';
import 'analyst_audit_screen.dart';
import '../widgets/notification_bell.dart';

class AnalystQueueScreen extends StatefulWidget {
  const AnalystQueueScreen({super.key});
  @override
  State<AnalystQueueScreen> createState() => _AnalystQueueScreenState();
}

class _AnalystQueueScreenState extends State<AnalystQueueScreen> {
  final ApiService _api = ApiService();
  List<Project> _queue = [];
  bool _isLoading = true;
  String _name = "Analyst";
  bool _needsVerification = false;
  bool _needsConfirmation = false;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() {
      _isLoading = true;
      _needsVerification = false;
      _needsConfirmation = false;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final data = await _api.getAdminQueue(token);
      if (mounted) {
        setState(() {
          _queue = data;
          _name = prefs.getString('userName') ?? "Expert";
          _isLoading = false;
        });
      }
    } catch (e) {
      final err = e.toString();
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (err.contains('verify your email')) _needsVerification = true;
          if (err.contains('awaiting Admin confirmation')) _needsConfirmation = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildPremiumHeader(context),
          _buildStatsSection(context),
          _isLoading 
            ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
            : _needsVerification || _needsConfirmation
              ? _buildRestrictedUI(context)
              : _queue.isEmpty
                ? _buildEmptyQueue(context)
                : SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => _buildEvaluationCard(_queue[i], context),
                        childCount: _queue.length,
                      ),
                    ),
                  ),
        ],
      ),
    );
  }

  Widget _buildRestrictedUI(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_person_outlined, size: 80, color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
            const SizedBox(height: 20),
            Text(
              _needsVerification ? "Email Verification Required" : "Profile Confirmation Pending",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              _needsVerification 
                ? "Please verify your email address to access project evaluations."
                : "Your profile is awaiting confirmation. Ensure your National ID and Picture are uploaded in your account settings.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // Navigate to profile tab (Index 2 in MainMenu)
                // Since this is inside a tab, we might need a better way, but for now:
              },
              child: const Text("COMPLETE PROFILE"),
            )
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
              Text("Hello, $_name", style: TextStyle(color: isDark ? Colors.white.withOpacity(0.7) : Colors.black54, fontSize: 16)),
              Text("Available Projects", style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 26, fontWeight: FontWeight.bold)),
            ],
          ),
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
            _stat("Queue", _queue.length.toString(), Colors.orange, context),
            _divider(context),
            _stat("Status", "Online", Colors.green, context),
            _divider(context),
            _stat("Role", "Verifier", Theme.of(context).colorScheme.primary, context),
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

  

  Widget _buildEvaluationCard(Project p, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          final assigned = await Navigator.push<bool>(
            context, 
            MaterialPageRoute(builder: (_) => AnalystPreviewScreen(project: p))
          );
          if (assigned == true) _fetch();
        },
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
                child: Icon(Icons.assignment_outlined, color: colorScheme.primary),
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

  Widget _buildEmptyQueue(BuildContext context) {
    return SliverFillRemaining(
      child: Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 80, color: Colors.green.withOpacity(0.5)),
          const SizedBox(height: 15),
          Text("No pending projects. Great job!", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
        ],
      )),
    );
  }
}