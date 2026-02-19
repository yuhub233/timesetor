import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../constants/app_constants.dart';

class TimeProvider extends ChangeNotifier {
  String _virtualTime = '--:--';
  String _realTime = '';
  double _currentSpeed = 1.0;
  String _currentActivity = 'rest';
  String _status = 'unknown';
  double _entertainmentMultiplier = 2.0;
  String? _error;

  Timer? _updateTimer;

  String get virtualTime => _virtualTime;
  String get realTime => _realTime;
  double get currentSpeed => _currentSpeed;
  String get currentActivity => _currentActivity;
  String get status => _status;
  double get entertainmentMultiplier => _entertainmentMultiplier;
  bool get isAwake => _status == 'awake';
  String? get error => _error;

  Future<void> fetchCurrentTime() async {
    try {
      final response = await ApiService.get('/time/current');
      final previousStatus = _status;
      
      _status = response['status'] ?? 'unknown';
      _virtualTime = response['virtual_time_display'] ?? '--:--';
      _realTime = response['real_time'] ?? '';
      _currentSpeed = (response['current_speed'] ?? 1.0).toDouble();
      _currentActivity = response['current_activity'] ?? 'rest';
      _error = null;

      if (_status == 'awake' && previousStatus != 'awake') {
        startAutoUpdate();
      }

      notifyListeners();

      if (_status == 'awake') {
        await NotificationService.showTimeNotification(_virtualTime, _currentSpeed);
      }
    } catch (e) {
      debugPrint('Failed to fetch time: $e');
      _error = '获取时间失败';
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> recordWake() async {
    try {
      final response = await ApiService.post('/time/wake', {});
      _entertainmentMultiplier = (response['entertainment_multiplier'] ?? 2.0).toDouble();
      _status = 'awake';
      _error = null;
      startAutoUpdate();
      notifyListeners();
      return {'success': true, 'data': response};
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return {'success': false, 'error': e.message};
    } catch (e) {
      _error = '记录起床失败';
      notifyListeners();
      return {'success': false, 'error': '记录起床失败'};
    }
  }

  Future<Map<String, dynamic>> recordSleep() async {
    try {
      final response = await ApiService.post('/time/sleep', {});
      _status = 'sleep';
      _error = null;
      stopAutoUpdate();
      await NotificationService.cancelAll();
      notifyListeners();
      return {'success': true, 'data': response};
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return {'success': false, 'error': e.message};
    } catch (e) {
      _error = '记录睡觉失败';
      notifyListeners();
      return {'success': false, 'error': '记录睡觉失败'};
    }
  }

  Future<void> updateActivity(String activityType, {String? appName}) async {
    try {
      final response = await ApiService.post('/activity/update', {
        'activity_type': activityType,
        'app_name': appName,
      });
      _currentActivity = response['activity_type'] ?? activityType;
      _currentSpeed = (response['speed'] ?? 1.0).toDouble();
      _error = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to update activity: $e');
    }
  }

  void startAutoUpdate() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(AppConstants.autoUpdateInterval, (_) {
      fetchCurrentTime();
    });
  }

  void stopAutoUpdate() {
    _updateTimer?.cancel();
    _updateTimer = null;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stopAutoUpdate();
    super.dispose();
  }
}
