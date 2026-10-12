import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'analytics_service.dart';

/// Background handler — must be a top-level function.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background: ${message.messageId}');
}

class AppNotificationService {
  AppNotificationService._();
  static final AppNotificationService instance = AppNotificationService._();

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // Android high-importance channel
  final AndroidNotificationChannel _androidChannel =
      const AndroidNotificationChannel(
    'vendora_high_importance',
    'Vendora Notifications',
    description: 'Important notifications from Vendora',
    importance: Importance.max,
  );

  Future<void> init() async {
    if (_initialized) return;

    try {
      // Windows & Linux: flutter_local_notifications doesn't support them yet
      if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
        debugPrint('[Notifications] Desktop: push not supported on this OS.');
        _initialized = true;
        return;
      }

      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      await _requestPermission();
      await _initLocalNotifications();
      _listenForeground();
      _listenOpened();
      await _subscribeGeneral();

      _initialized = true;
      debugPrint('[Notifications] ready.');
    } catch (e) {
      debugPrint('[Notifications] init error: $e');
    }
  }

  // ── Permission ─────────────────────────────────────────────────────────────

  Future<void> _requestPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[FCM] auth: ${settings.authorizationStatus.name}');
  }

  // ── Local notifications (Android + iOS + macOS) ────────────────────────────

  Future<void> _initLocalNotifications() async {
    if (kIsWeb) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings();

    await _local.initialize(
      const InitializationSettings(android: android, iOS: darwin, macOS: darwin),
      onDidReceiveNotificationResponse: (details) {
        AppAnalytics.instance
            .logNotificationTapped(type: details.payload ?? 'general');
      },
    );

    // Create Android channel
    if (!kIsWeb && Platform.isAndroid) {
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_androidChannel);
    }
  }

  // ── Foreground handler ────────────────────────────────────────────────────

  void _listenForeground() {
    FirebaseMessaging.onMessage.listen((msg) {
      debugPrint('[FCM] foreground: ${msg.notification?.title}');
      _showLocal(msg);
    });
  }

  Future<void> _showLocal(RemoteMessage msg) async {
    if (kIsWeb) return;
    final n = msg.notification;
    if (n == null) return;

    await _local.show(
      msg.hashCode,
      n.title,
      n.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        macOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: msg.data['type'],
    );
  }

  // ── Opened handler ────────────────────────────────────────────────────────

  void _listenOpened() {
    // From terminated
    FirebaseMessaging.instance.getInitialMessage().then((msg) {
      if (msg != null) {
        AppAnalytics.instance
            .logNotificationTapped(type: msg.data['type'] ?? 'general');
      }
    });

    // From background
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      AppAnalytics.instance
          .logNotificationTapped(type: msg.data['type'] ?? 'general');
    });
  }

  // ── Topic ─────────────────────────────────────────────────────────────────

  Future<void> _subscribeGeneral() async {
    try {
      await FirebaseMessaging.instance.subscribeToTopic('all-notifications');
    } catch (_) {}
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      await FirebaseMessaging.instance.subscribeToTopic(topic);
    } catch (_) {}
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
    } catch (_) {}
  }

  Future<String?> get fcmToken async {
    try {
      return kIsWeb
          ? await FirebaseMessaging.instance.getToken(
              vapidKey: const String.fromEnvironment('FCM_VAPID_KEY').isEmpty
                  ? null
                  : const String.fromEnvironment('FCM_VAPID_KEY'),
            )
          : await FirebaseMessaging.instance.getToken();
    } catch (_) {
      return null;
    }
  }
}
