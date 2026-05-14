import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project_model.dart';
import '../services/api_service.dart';
import 'analyst_audit_screen.dart';

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

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final data = await _api.getAdminQueue(token);
    setState(() {
      _queue = data;
      _name = prefs.getString('userName') ?? "Expert";
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          _buildPremiumHeader(),
          _buildStatsSection(),
          _isLoading 
            ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
            : _queue.isEmpty
              ? _buildEmptyQueue()
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _buildEvaluationCard(_queue[i]),
                      childCount: _queue.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader() {
    return SliverAppBar(
      expandedHeight: 180, pinned: true, elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF0056b3), Color(0xFF002a5a)]),
          ),
          padding: const EdgeInsets.fromLTRB(25, 80, 25, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Hello, $_name", style: const TextStyle(color: Colors.white70, fontSize: 16)),
              const Text("Quality Control Hub", style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _stat("Queue", _queue.length.toString(), Colors.orange),
            _divider(),
            _stat("Status", "Online", Colors.green),
            _divider(),
            _stat("Role", "Verifier", const Color(0xFF0056b3)),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String val, Color color) => Column(
    children: [
      Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      Text(val, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: color)),
    ],
  );

  Widget _divider() => Container(height: 30, width: 1, color: Colors.grey[200]);

  Widget _buildEvaluationCard(Project p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AnalystAuditScreen(project: p))).then((_) => _fetch()),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              Container(
                height: 50, width: 50,
                decoration: BoxDecoration(color: const Color(0xFFE1EFFE), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.fact_check, color: Color(0xFF0056b3)),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text("${p.sellerName} • ${p.category}", style: const TextStyle(color: Colors.grey, fontSize: 13)),
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

  Widget _buildEmptyQueue() {
    return const SliverFillRemaining(
      child: Center(child: Text("The queue is empty. Great job!", style: TextStyle(color: Colors.grey))),
    );
  }
}