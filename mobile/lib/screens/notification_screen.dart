import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';
import '../services/api_service.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final ApiService _api = ApiService();
  List<AppNotification> _notifications = [];
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
      final list = await _api.getNotifications(token);
      if (mounted) {
        setState(() {
          _notifications = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllRead() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    await _api.markAllNotificationsAsRead(token);
    _fetch();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Notifications", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          if (_notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: _markAllRead, 
              child: const Text("Mark all as read", style: TextStyle(fontSize: 12))
            )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetch,
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
            ? _buildEmptyState(context)
            : ListView.builder(
                padding: const EdgeInsets.all(15),
                itemCount: _notifications.length,
                itemBuilder: (context, index) => _buildNotificationTile(_notifications[index]),
              ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_rounded, size: 80, color: Theme.of(context).colorScheme.primary.withOpacity(0.1)),
          const SizedBox(height: 20),
          const Text("No notifications yet", style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(AppNotification n) {
    IconData icon;
    Color color;

    switch (n.type) {
      case 'project_update':
        icon = Icons.analytics_outlined;
        color = Colors.blue;
        break;
      case 'security':
        icon = Icons.security_outlined;
        color = Colors.orange;
        break;
      case 'wallet':
        icon = Icons.account_balance_wallet_outlined;
        color = Colors.green;
        break;
      case 'admin_broadcast':
      case 'broadcast':
        icon = Icons.campaign_outlined;
        color = Colors.purple;
        break;
      case 'newsletter':
        icon = Icons.mark_as_unread_outlined;
        color = Colors.teal;
        break;
      default:
        icon = Icons.info_outline;
        color = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: n.isRead ? Colors.transparent : color.withOpacity(0.2))
      ),
      color: n.isRead ? Theme.of(context).cardColor : color.withOpacity(0.05),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(n.title, style: TextStyle(fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            Text(n.message, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
            const SizedBox(height: 8),
            Text(timeago.format(n.createdAt), style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        onTap: () async {
          if (!n.isRead) {
            final prefs = await SharedPreferences.getInstance();
            await _api.markNotificationAsRead(n.id, prefs.getString('token') ?? '');
            _fetch();
          }
          // TODO: Navigate to related item if n.relatedId exists
        },
      ),
    );
  }
}
