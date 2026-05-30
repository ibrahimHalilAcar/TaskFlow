import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  NotificationService._init();

  Future<void> init() async {
    if (kIsWeb) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return;

    const android = AndroidNotificationDetails(
      'taskflow_channel',
      'TaskFlow Bildirimleri',
      channelDescription: 'Görev hatırlatıcıları',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: android);
    await _plugin.show(id, title, body, details);
  }

  Future<void> cancelAll() async {
    if (kIsWeb) return;
    await _plugin.cancelAll();
  }
}