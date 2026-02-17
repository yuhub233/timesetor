import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

class NotificationService {
  static const channelId = 'timesetor_time';
  static const channelName = 'TimeSetor Time Display';
  
  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _notifications.initialize(settings);
    
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
  }
  
  static Future<void> showTimeNotification(String virtualTime, double speed) async {
    final speedText = speed > 1.5 ? '${speed.toStringAsFixed(1)}x 快' : speed < 0.8 ? '${speed.toStringAsFixed(1)}x 慢' : '正常';
    final androidDetails = AndroidNotificationDetails(channelId, channelName, importance: Importance.low, priority: Priority.low, ongoing: true, showWhen: false);
    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _notifications.show(0, virtualTime, '流速: $speedText', details);
  }
  
  static Future<void> showPomodoroComplete() async {
    final androidDetails = const AndroidNotificationDetails('timesetor_pomodoro', 'TimeSetor Pomodoro', importance: Importance.high, priority: Priority.high);
    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _notifications.show(2, '🍅 番茄钟完成', '休息一下吧！', details);
  }
}
