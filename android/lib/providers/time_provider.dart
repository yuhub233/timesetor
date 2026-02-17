import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class TimeProvider extends ChangeNotifier {
  String _virtualTime = '--:--';
  String _realTime = '';
  double _currentSpeed = 1.0;
  String _currentActivity = 'rest';
  String _status = 'unknown';
  Timer? _updateTimer;
  
  String get virtualTime => _virtualTime;
  String get realTime => _realTime;
  double get currentSpeed => _currentSpeed;
  String get currentActivity => _currentActivity;
  String get status => _status;
  bool get isAwake => _status == 'awake';
  
  Future<void> fetchCurrentTime() async {
    try {
      final response = await ApiService.get('/time/current');
      _status = response['status'] ?? 'unknown';
      _virtualTime = response['virtual_time_display'] ?? '--:--';
      _realTime = response['real_time'] ?? '';
      _currentSpeed = (response['current_speed'] ?? 1.0).toDouble();
      _currentActivity = response['current_activity'] ?? 'rest';
      notifyListeners();
      await NotificationService.showTimeNotification(_virtualTime, _currentSpeed);
    } catch (e) { debugPrint('Failed to fetch time: $e'); }
  }
  
  Future<Map<String, dynamic>> recordWake() async {
    try {
      await ApiService.post('/time/wake', {});
      _status = 'awake';
      startAutoUpdate();
      notifyListeners();
      return {'success': true};
    } on ApiException catch (e) { return {'success': false, 'error': e.message}; } catch (e) { return {'success': false, 'error': '记录起床失败'}; }
  }
  
  Future<Map<String, dynamic>> recordSleep() async {
    try {
      await ApiService.post('/time/sleep', {});
      _status = 'sleep';
      stopAutoUpdate();
      notifyListeners();
      return {'success': true};
    } on ApiException catch (e) { return {'success': false, 'error': e.message}; } catch (e) { return {'success': false, 'error': '记录睡觉失败'}; }
  }
  
  Future<void> updateActivity(String activityType, {String? appName}) async {
    try {
      final response = await ApiService.post('/activity/update', {'activity_type': activityType, 'app_name': appName});
      _currentActivity = response['activity_type'];
      _currentSpeed = (response['speed'] ?? 1.0).toDouble();
      notifyListeners();
    } catch (e) { debugPrint('Failed to update activity: $e'); }
  }
  
  void startAutoUpdate() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) => fetchCurrentTime());
  }
  
  void stopAutoUpdate() {
    _updateTimer?.cancel();
    _updateTimer = null;
  }
  
  @override
  void dispose() {
    stopAutoUpdate();
    super.dispose();
  }
}