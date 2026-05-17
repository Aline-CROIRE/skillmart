import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../screens/notification_screen.dart';

class NotificationBell extends StatefulWidget {
  final Color? color;
  const NotificationBell({super.key, this.color});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  final ApiService _api = ApiService();
  int _unreadCount = 0;
  StreamSubscription? _notifSubscription;

  @override
  void initState() {
    super.initState();
    _fetchUnreadCount();
    
    // Listen for real-time notification arrivals in foreground
    _notifSubscription = PushNotificationService.onMessageReceived.stream.listen((_) {
      _fetchUnreadCount();
    });
  }

  @override
  void dispose() {
    _notifSubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? "";
      if (token.isNotEmpty) {
        final count = await _api.getUnreadNotificationCount(token);
        if (mounted) {
          setState(() {
            _unreadCount = count;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching unread count: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationScreen()),
          ).then((_) => _fetchUnreadCount()),
          icon: Icon(Icons.notifications_none_rounded, color: widget.color),
        ),
        if (_unreadCount > 0)
          Positioned(
            right: 6,
            top: 6,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 1.5),
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Center(
                  child: Text(
                    _unreadCount > 99 ? '99+' : "$_unreadCount",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
