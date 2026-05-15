import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AdminAnalyticsRequestsScreen extends StatefulWidget {
  const AdminAnalyticsRequestsScreen({super.key});
  @override
  State<AdminAnalyticsRequestsScreen> createState() => _AdminAnalyticsRequestsScreenState();
}

class _AdminAnalyticsRequestsScreenState extends State<AdminAnalyticsRequestsScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _requests = [];
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final data = await _api.getAnalyticsRequests(token);
      if (mounted) {
        setState(() {
          _requests = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _decision(Map<String, dynamic> req, String status) async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final success = await _api.updateAnalyticsRequestStatus(
        req['projectId'], 
        req['requestId'], 
        status, 
        token
      );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Access $status")));
        _fetch();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text("Analytics Access Requests"), elevation: 0),
      body: RefreshIndicator(
        onRefresh: _fetch,
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
            ? const Center(child: Text("No pending requests", style: TextStyle(color: Colors.grey)))
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _requests.length,
                itemBuilder: (context, i) => _buildRequestCard(_requests[i]),
              ),
      ),
    );
  }

  Widget _buildRequestCard(dynamic req) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(req['projectTitle'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 5),
            Text("Requested by: ${req['userName']}", style: const TextStyle(fontSize: 14)),
            Text(req['userEmail'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const Divider(height: 25),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _decision(req, 'denied'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text("DENY"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _decision(req, 'granted'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text("GRANT ACCESS"),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
