import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class PushNotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  // Stream to notify UI when a notification arrives in foreground
  static final StreamController<RemoteMessage> onMessageReceived = StreamController<RemoteMessage>.broadcast();

  static Future<void> initialize() async {
    // 1. Request Permission
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Setup Android Channels (Categories for Muting)
    final List<AndroidNotificationChannel> channels = [
      AndroidNotificationChannel('projects', 'Project Updates'),
      AndroidNotificationChannel('security', 'Account Security'),
      AndroidNotificationChannel('wallet', 'Wallet & Payments'),
      AndroidNotificationChannel('broadcast', 'Announcements'),
      AndroidNotificationChannel('newsletter', 'SkillMart Newsletters'),
    ];

    for (var channel in channels) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    // 3. Initialize Local Notifications (for foreground alerts)
    final initializationSettings = InitializationSettings(
      android: const AndroidInitializationSettings('@drawable/ic_stat_logo'),
      iOS: const DarwinInitializationSettings(),
    );
    await _localNotifications.initialize(
      settings: initializationSettings,
    );

    // 4. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      onMessageReceived.add(message); // Notify listeners (like the bell badge)
      
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        String channelId = android.channelId ?? 'default';
        String channelName = 'System Notifications';
        
        if (channelId == 'projects') channelName = 'Project Updates';
        if (channelId == 'security') channelName = 'Account Security';
        if (channelId == 'wallet') channelName = 'Wallet & Payments';
        if (channelId == 'broadcast') channelName = 'Announcements';
        if (channelId == 'newsletter') channelName = 'SkillMart Newsletters';

        _localNotifications.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              channelId,
              channelName,
              channelDescription: 'SkillMart Notifications',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    });

    // 5. Token Management
    _fcm.getToken().then((token) async {
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        final storedToken = prefs.getString('fcmToken');
        if (token != storedToken) {
          final authToken = prefs.getString('token');
          if (authToken != null) {
            try {
              await ApiService().updateProfileInfo({'fcmToken': token}, authToken);
              await prefs.setString('fcmToken', token);
            } catch (e) {
              // Ignore if not logged in
            }
          }
        }
      }
    });
  }

  static Future<String?> getToken() async {
    return await _fcm.getToken();
  }
}
