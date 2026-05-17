import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'package:timeago/timeago.dart' as timeago;

class AdminNotificationHistoryScreen extends StatefulWidget {
  final String initialFilter;
  const AdminNotificationHistoryScreen({super.key, this.initialFilter = 'all'});

  @override
  State<AdminNotificationHistoryScreen> createState() => _AdminNotificationHistoryScreenState();
}

class _AdminNotificationHistoryScreenState extends State<AdminNotificationHistoryScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _notifications = [];
  bool _isLoading = true;
  late String _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final list = await _api.getNotificationsHistory(token);
      setState(() {
        _notifications = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  List<dynamic> get _filteredList {
    if (_filter == 'all') return _notifications;
    return _notifications.where((n) {
      if (_filter == 'newsletter') return n['type'] == 'newsletter';
      if (_filter == 'broadcast') return n['type'] == 'broadcast' || n['type'] == 'admin_broadcast';
      return n['type'] == _filter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dispatch Audit Log", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(onPressed: _fetch, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(colorScheme),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _filteredList.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(15),
                    itemCount: _filteredList.length,
                    itemBuilder: (context, index) => _buildNotificationCard(_filteredList[index], colorScheme),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(ColorScheme colorScheme) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _filterChip('All', 'all'),
          _filterChip('Newsletters', 'newsletter'),
          _filterChip('Broadcasts', 'broadcast'),
          _filterChip('Security', 'security'),
          _filterChip('Projects', 'project_update'),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    bool selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (val) {
          if (val) setState(() => _filter = value);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off, size: 64, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text("No dispatched notifications found", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(dynamic n, ColorScheme colorScheme) {
    final type = n['type'] ?? 'info';
    final user = n['userId'] ?? {};
    final userName = user['name'] ?? 'Unknown User';
    final userEmail = user['email'] ?? '';
    final userRole = user['role'] ?? '';
    
    IconData icon;
    Color color;

    switch (type) {
      case 'newsletter':
        icon = Icons.mark_as_unread_outlined;
        color = Colors.teal;
        break;
      case 'broadcast':
      case 'admin_broadcast':
        icon = Icons.campaign_outlined;
        color = Colors.purple;
        break;
      case 'security':
        icon = Icons.security_outlined;
        color = Colors.orange;
        break;
      case 'project_update':
        icon = Icons.analytics_outlined;
        color = Colors.blue;
        break;
      default:
        icon = Icons.info_outline;
        color = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(n['title'] ?? 'No Title', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(timeago.format(DateTime.parse(n['createdAt'])), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(type.toString().toUpperCase(), style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(n['message'] ?? '', style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withOpacity(0.8))),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "To: $userName ($userEmail)",
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  userRole.toString().toUpperCase(),
                  style: const TextStyle(fontSize: 10, color: Colors.blueGrey, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
