import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../constants/app_constants.dart';

enum PomodoroPhase { work, shortBreak, longBreak }

class PomodoroProvider extends ChangeNotifier {
  bool _isRunning = false;
  bool _isPaused = false;
  PomodoroPhase _currentPhase = PomodoroPhase.work;
  int _remainingSeconds = AppConstants.defaultPomodoroWorkDuration * 60;
  int _totalSeconds = AppConstants.defaultPomodoroWorkDuration * 60;
  int? _sessionId;
  int _completedWorkSessions = 0;
  int _totalMinutes = 0;
  String? _error;

  Timer? _timer;

  bool get isRunning => _isRunning;
  bool get isPaused => _isPaused;
  PomodoroPhase get currentPhase => _currentPhase;
  int get remainingSeconds => _remainingSeconds;
  int get totalSeconds => _totalSeconds;
  int? get sessionId => _sessionId;
  int get completedWorkSessions => _completedWorkSessions;
  int get totalMinutes => _totalMinutes;
  double get progress => _totalSeconds > 0 ? 1 - (_remainingSeconds / _totalSeconds) : 0;
  String? get error => _error;

  String get phaseLabel {
    switch (_currentPhase) {
      case PomodoroPhase.work:
        return '工作中';
      case PomodoroPhase.shortBreak:
        return '短休息';
      case PomodoroPhase.longBreak:
        return '长休息';
    }
  }

  Future<void> fetchStats() async {
    try {
      final response = await ApiService.get('/data/daily');
      final sessions = response['pomodoro_sessions'] as List? ?? [];
      _completedWorkSessions = sessions.where((s) => s['status'] == 'completed' && s['session_type'] == 'work').length;
      _totalMinutes = sessions.fold(0, (sum, s) => sum + (s['actual_duration_minutes'] as int? ?? 0));
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to fetch pomodoro stats: $e');
    }
  }

  Future<void> startWork({int durationMinutes = AppConstants.defaultPomodoroWorkDuration}) async {
    try {
      final response = await ApiService.post('/pomodoro/start', {
        'duration_minutes': durationMinutes,
        'session_type': 'work',
      });
      _sessionId = response['session_id'] as int?;
      _currentPhase = PomodoroPhase.work;
      _totalSeconds = durationMinutes * 60;
      _remainingSeconds = _totalSeconds;
      _isRunning = true;
      _isPaused = false;
      _error = null;
      _startTimer();
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
    } catch (e) {
      _error = '启动番茄钟失败';
      notifyListeners();
    }
  }

  Future<void> startShortBreak() async {
    _currentPhase = PomodoroPhase.shortBreak;
    _totalSeconds = AppConstants.defaultPomodoroShortBreak * 60;
    _remainingSeconds = _totalSeconds;
    _isRunning = true;
    _isPaused = false;
    _error = null;
    _startTimer();
    notifyListeners();
  }

  Future<void> startLongBreak() async {
    _currentPhase = PomodoroPhase.longBreak;
    _totalSeconds = AppConstants.defaultPomodoroLongBreak * 60;
    _remainingSeconds = _totalSeconds;
    _isRunning = true;
    _isPaused = false;
    _error = null;
    _startTimer();
    notifyListeners();
  }

  void pause() {
    _isPaused = true;
    _timer?.cancel();
    notifyListeners();
  }

  void resume() {
    _isPaused = false;
    _startTimer();
    notifyListeners();
  }

  Future<void> reset() async {
    _timer?.cancel();
    if (_sessionId != null && _currentPhase == PomodoroPhase.work) {
      try {
        await ApiService.post('/pomodoro/end', {
          'session_id': _sessionId,
          'actual_duration_minutes': 0,
          'status': 'cancelled',
        });
      } catch (_) {}
    }
    _isRunning = false;
    _isPaused = false;
    _currentPhase = PomodoroPhase.work;
    _totalSeconds = AppConstants.defaultPomodoroWorkDuration * 60;
    _remainingSeconds = _totalSeconds;
    _sessionId = null;
    _error = null;
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        _completePhase();
      }
    });
  }

  Future<void> _completePhase() async {
    _timer?.cancel();

    if (_currentPhase == PomodoroPhase.work && _sessionId != null) {
      try {
        await ApiService.post('/pomodoro/end', {
          'session_id': _sessionId,
          'actual_duration_minutes': _totalSeconds ~/ 60,
          'status': 'completed',
        });
        _completedWorkSessions++;
        _totalMinutes += _totalSeconds ~/ 60;
      } catch (_) {}
    }

    await NotificationService.showPomodoroComplete();

    if (_currentPhase == PomodoroPhase.work) {
      if (_completedWorkSessions % AppConstants.pomodoroLongBreakInterval == 0) {
        await startLongBreak();
      } else {
        await startShortBreak();
      }
    } else {
      _isRunning = false;
      _isPaused = false;
      _currentPhase = PomodoroPhase.work;
      _totalSeconds = AppConstants.defaultPomodoroWorkDuration * 60;
      _remainingSeconds = _totalSeconds;
      _sessionId = null;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
