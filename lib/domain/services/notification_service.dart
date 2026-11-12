import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _notifications.initialize(
      settings: settings,
    );

    final android = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await android?.requestNotificationsPermission();

    final ios = _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static Future<void> showAirQualityAlert(String quality) async {
    const androidDetails = AndroidNotificationDetails(
      'air_quality_alerts',
      'Alertas de qualidade do ar',
      channelDescription:
          'Notificações quando a qualidade do ar estiver moderada ou pior.',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id: 1,
      title: '⚠️ Alerta de qualidade do ar',
      body: 'A qualidade do ar está $quality. Verifique o ambiente!',
      notificationDetails: details,
    );
  }
}
