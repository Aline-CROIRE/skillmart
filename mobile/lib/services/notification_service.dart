import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import '../services/api_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Background processing here
}

class PushNotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  // Stream to notify UI when a notification arrives in foreground
  static final StreamController<RemoteMessage> onMessageReceived = StreamController<RemoteMessage>.broadcast();

  static Future<void> initialize() async {
    // 1. Request Permission & Configure iOS Foreground Banners
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Setup Android Channels (Categories for Muting - Must be MAX for Heads-up Banners)
    final List<AndroidNotificationChannel> channels = [
      const AndroidNotificationChannel('projects', 'Project Updates', importance: Importance.max),
      const AndroidNotificationChannel('security', 'Account Security', importance: Importance.max),
      const AndroidNotificationChannel('wallet', 'Wallet & Payments', importance: Importance.max),
      const AndroidNotificationChannel('broadcast', 'Announcements', importance: Importance.max),
      const AndroidNotificationChannel('newsletter', 'SkillMart Newsletters', importance: Importance.max),
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

    // 4. Handle Background Messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 5. Handle Foreground Messages
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

    // 6. Token Management
    _fcm.getToken().then((token) async {
      if (token != null) {
        debugPrint('====== FCM TOKEN ======');
        debugPrint(token);
        debugPrint('=======================');
        final prefs = await SharedPreferences.getInstance();
        final storedToken = prefs.getString('fcmToken');
        if (token != storedToken) {
          final authToken = prefs.getString('token');
          if (authToken != null) {
            try {
              await ApiService().updateProfileInfo({'fcmToken': token}, authToken);
              await prefs.setString('fcmToken', token);
              debugPrint('====== FCM TOKEN SENT TO BACKEND ======');
            } catch (e) {
              debugPrint('FCM token update failed: $e');
            }
          } else {
            debugPrint('====== FCM TOKEN NOT SENT - NO AUTH TOKEN (not logged in yet) ======');
          }
        } else {
          debugPrint('====== FCM TOKEN UNCHANGED - NOT RESENT ======');
        }
      }
    });
  }

  static Future<String?> getToken() async {
    return await _fcm.getToken();
  }
}
