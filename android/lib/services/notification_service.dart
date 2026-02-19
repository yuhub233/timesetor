import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notifications.initialize(initializationSettings);
  }

  static Future<void> showTimeNotification(
      String virtualTime, double speed) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'timesetor_time_channel',
      'Time Display',
      channelDescription: 'Displays current virtual time',
      importance: Importance.low,
      priority: Priority.low,
      showWhen: false,
      ongoing: true,
      autoCancel: false,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notifications.show(
      0,
      'TimeSetor',
      '$virtualTime (${speed.toStringAsFixed(1)}x)',
      platformChannelSpecifics,
    );
  }

  static Future<void> showPomodoroComplete() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'timesetor_pomodoro_channel',
      'Pomodoro',
      channelDescription: 'Pomodoro timer notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notifications.show(
      1,
      '🍅 番茄钟完成！',
      '休息一下吧',
      platformChannelSpecifics,
    );
  }

  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
