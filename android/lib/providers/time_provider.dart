import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/overlay_service.dart';

class TimeProvider extends ChangeNotifier {
  String _virtualTime = '--:--';
  double _currentSpeed = 1.0;
  String _currentActivity = 'rest';
  String _status = 'unknown';
  Timer? _updateTimer;
  bool _overlayEnabled = false;
  
  String get virtualTime => _virtualTime;
  double get currentSpeed => _currentSpeed;
  String get currentActivity => _currentActivity;
  String get status => _status;
  bool get isAwake => _status == 'awake';
  bool get overlayEnabled => _overlayEnabled;
  
  Future<void> fetchCurrentTime() async {
    try {
      final response = await ApiService.get('/time/current');
      _status = response['status'] ?? 'unknown';
      _virtualTime = response['virtual_time_display'] ?? '--:--';
      _currentSpeed = (response['current_speed'] ?? 1.0).toDouble();
      _currentActivity = response['current_activity'] ?? 'rest';
      notifyListeners();
      
      await NotificationService.showTimeNotification(_virtualTime, _currentSpeed);
      
      if (_overlayEnabled) {
        await OverlayService.updateOverlay(
          virtualTime: _virtualTime,
          speed: _currentSpeed,
        );
      }
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
      
      if (_overlayEnabled) {
        await OverlayService.updateOverlay(
          virtualTime: _virtualTime,
          speed: _currentSpeed,
        );
      }
    } catch (e) { debugPrint('Failed to update activity: $e'); }
  }
  
  Future<void> enableOverlay() async {
    final hasPermission = await OverlayService.hasPermission();
    if (!hasPermission) {
      await OverlayService.requestPermission();
    }
    await OverlayService.showOverlay(
      virtualTime: _virtualTime,
      speed: _currentSpeed,
    );
    _overlayEnabled = true;
    notifyListeners();
  }
  
  Future<void> disableOverlay() async {
    await OverlayService.hideOverlay();
    _overlayEnabled = false;
    notifyListeners();
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
