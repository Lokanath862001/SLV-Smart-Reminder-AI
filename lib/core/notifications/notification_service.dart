import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static final StreamController<String?> notificationStream =
      StreamController<String?>.broadcast();

  static Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    // Create high importance channel for alarm intents
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'slv_alarm_channel_v1',
      'SLV Reminder Alarm Channel',
      description: 'Used for important voice alarms and active reminders',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          notificationStream.add(response.payload);
        }
      },
    );
  }

  static Future<void> showReminderNotification({
    required String id,
    required String title,
    required String body,
    required String category,
  }) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'slv_alarm_channel_v1',
      'SLV Reminder Alarm Channel',
      channelDescription: 'Used for important voice alarms and active reminders',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      styleInformation: BigTextStyleInformation(body),
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      id.hashCode,
      title,
      '[$category] $body',
      notificationDetails,
      payload: id,
    );
  }

  static Future<void> cancel(String id) async {
    await _notificationsPlugin.cancel(id.hashCode);
  }

  static Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
}
