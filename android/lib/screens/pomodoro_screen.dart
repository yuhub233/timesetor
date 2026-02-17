import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../providers/time_provider.dart';

enum PomodoroPhase { work, shortBreak, longBreak, idle }

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});
  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  
  int _workDuration = 25;
  int _shortBreakDuration = 5;
  int _longBreakDuration = 15;
  int _longBreakInterval = 4;
  
  int _remainingSeconds = 25 * 60;
  PomodoroPhase _phase = PomodoroPhase.idle;
  bool _isRunning = false;
  int? _sessionId;
  Timer? _timer;
  int _completedPomodoros = 0;
  int _totalMinutes = 0;
  
  bool _showCustomInput = false;
  final _customWorkController = TextEditingController(text: '25');
  final _customBreakController = TextEditingController(text: '5');
  
  @override
  void initState() {
    super.initState();
    _fetchStats();
    _fetchConfig();
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    _customWorkController.dispose();
    _customBreakController.dispose();
    super.dispose();
  }
  
  Future<void> _fetchConfig() async {
    try {
      final response = await ApiService.get('/config');
      final pomodoroConfig = response['pomodoro'];
      if (mounted) {
        setState(() {
          _workDuration = pomodoroConfig['work_duration'] ?? 25;
          _shortBreakDuration = pomodoroConfig['short_break'] ?? 5;
          _longBreakDuration = pomodoroConfig['long_break'] ?? 15;
          _longBreakInterval = pomodoroConfig['long_break_interval'] ?? 4;
          _remainingSeconds = _workDuration * 60;
        });
      }
    } catch (_) {}
  }
  
  Future<void> _fetchStats() async {
    try {
      final response = await ApiService.get('/data/daily');
      final sessions = response['pomodoro_sessions'] as List? ?? [];
      if (mounted) {
        setState(() {
          _completedPomodoros = sessions.where((s) => s['status'] == 'completed' && s['session_type'] == 'work').length;
          _totalMinutes = sessions.fold(0, (sum, s) => sum + (s['actual_duration_minutes'] as int? ?? 0));
        });
      }
    } catch (_) {}
  }
  
  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
  
  int get _currentDuration {
    switch (_phase) {
      case PomodoroPhase.work:
        return _workDuration * 60;
      case PomodoroPhase.shortBreak:
        return _shortBreakDuration * 60;
      case PomodoroPhase.longBreak:
        return _longBreakDuration * 60;
      case PomodoroPhase.idle:
        return _workDuration * 60;
    }
  }
  
  Future<void> _startPhase(PomodoroPhase phase) async {
    if (_isRunning) return;
    
    int duration;
    String sessionType;
    
    switch (phase) {
      case PomodoroPhase.work:
        duration = _workDuration;
        sessionType = 'work';
        break;
      case PomodoroPhase.shortBreak:
        duration = _shortBreakDuration;
        sessionType = 'break';
        break;
      case PomodoroPhase.longBreak:
        duration = _longBreakDuration;
        sessionType = 'break';
        break;
      case PomodoroPhase.idle:
        return;
    }
    
    try {
      final response = await ApiService.post('/pomodoro/start', {
        'duration_minutes': duration,
        'session_type': sessionType,
      });
      _sessionId = response['session_id'];
      
      setState(() {
        _phase = phase;
        _remainingSeconds = duration * 60;
        _isRunning = true;
      });
      
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_remainingSeconds > 0) {
          setState(() => _remainingSeconds--);
        } else {
          _completePhase();
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('启动失败: $e')),
        );
      }
    }
  }
  
  Future<void> _completePhase() async {
    _timer?.cancel();
    _timer = null;
    
    final completedPhase = _phase;
    final completedSessionId = _sessionId;
    
    PomodoroPhase? nextPhase;
    if (completedPhase == PomodoroPhase.work) {
      _completedPomodoros++;
      _totalMinutes += _workDuration;
      
      if (_completedPomodoros % _longBreakInterval == 0) {
        nextPhase = PomodoroPhase.longBreak;
      } else {
        nextPhase = PomodoroPhase.shortBreak;
      }
    } else {
      nextPhase = PomodoroPhase.work;
    }
    
    try {
      await ApiService.post('/pomodoro/end', {
        'session_id': completedSessionId,
        'actual_duration_minutes': _getPhaseDuration(completedPhase),
        'status': 'completed',
        'next_type': nextPhase == PomodoroPhase.work ? 'work' : 'break',
      });
    } catch (_) {}
    
    await NotificationService.showPomodoroComplete();
    
    if (mounted) {
      String message;
      if (completedPhase == PomodoroPhase.work) {
        message = '🍅 番茄钟完成！休息一下吧';
      } else {
        message = '休息结束，开始下一个番茄钟';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      
      setState(() {
        _isRunning = false;
        _phase = PomodoroPhase.idle;
        _sessionId = null;
      });
      
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted && nextPhase != null) {
        _startPhase(nextPhase);
      }
    }
  }
  
  int _getPhaseDuration(PomodoroPhase phase) {
    switch (phase) {
      case PomodoroPhase.work:
        return _workDuration;
      case PomodoroPhase.shortBreak:
        return _shortBreakDuration;
      case PomodoroPhase.longBreak:
        return _longBreakDuration;
      case PomodoroPhase.idle:
        return 0;
    }
  }
  
  Future<void> _pauseTimer() async {
    setState(() => _isRunning = false);
    _timer?.cancel();
    _timer = null;
  }
  
  Future<void> _resetTimer() async {
    _timer?.cancel();
    _timer = null;
    
    if (_sessionId != null) {
      try {
        await ApiService.post('/pomodoro/end', {
          'session_id': _sessionId,
          'actual_duration_minutes': (_currentDuration - _remainingSeconds) ~/ 60,
          'status': 'cancelled',
        });
      } catch (_) {}
    }
    
    setState(() {
      _isRunning = false;
      _phase = PomodoroPhase.idle;
      _remainingSeconds = _workDuration * 60;
      _sessionId = null;
    });
  }
  
  void _applyCustomDurations() {
    final work = int.tryParse(_customWorkController.text);
    final breakTime = int.tryParse(_customBreakController.text);
    
    if (work != null && work > 0 && work <= 120) {
      _workDuration = work;
    }
    if (breakTime != null && breakTime > 0 && breakTime <= 60) {
      _shortBreakDuration = breakTime;
    }
    
    if (!_isRunning) {
      setState(() {
        _remainingSeconds = _workDuration * 60;
      });
    }
    
    setState(() {
      _showCustomInput = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final progress = _currentDuration > 0 ? 1 - (_remainingSeconds / _currentDuration) : 0.0;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('番茄钟'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => setState(() => _showCustomInput = !_showCustomInput),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_showCustomInput)
              Card(
                color: const Color(0xFF1A1A2E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('自定义时长', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _customWorkController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: '工作(分钟)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _customBreakController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: '休息(分钟)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _applyCustomDurations,
                          child: const Text('应用'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_showCustomInput) const SizedBox(height: 16),
            
            Card(
              color: const Color(0xFF1A1A2E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _phase == PomodoroPhase.work ? Icons.work : 
                          _phase == PomodoroPhase.shortBreak || _phase == PomodoroPhase.longBreak 
                            ? Icons.coffee : Icons.timer,
                          color: _getPhaseColor(),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getPhaseLabel(),
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 200,
                          height: 200,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 8,
                            backgroundColor: Colors.grey.withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation(_getPhaseColor()),
                          ),
                        ),
                        Column(
                          children: [
                            Text(
                              _formatTime(_remainingSeconds),
                              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                            ),
                            if (_isRunning)
                              Consumer<TimeProvider>(
                                builder: (context, timeProvider, _) {
                                  return Text(
                                    '${timeProvider.currentSpeed.toStringAsFixed(1)}x',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[400],
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: _isRunning ? _pauseTimer : () => _startPhase(PomodoroPhase.work),
                          child: Text(_isRunning ? '暂停' : '开始'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _resetTimer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.withOpacity(0.2),
                          ),
                          child: const Text('重置'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: Text('$_workDuration分钟'),
                          selected: !_isRunning && _phase == PomodoroPhase.idle,
                          onSelected: _isRunning ? null : (selected) {
                            setState(() {
                              _workDuration = _workDuration;
                              _remainingSeconds = _workDuration * 60;
                            });
                          },
                        ),
                        ChoiceChip(
                          label: const Text('15分钟'),
                          selected: false,
                          onSelected: _isRunning ? null : (selected) {
                            if (selected) {
                              setState(() {
                                _workDuration = 15;
                                _remainingSeconds = 15 * 60;
                              });
                            }
                          },
                        ),
                        ChoiceChip(
                          label: const Text('30分钟'),
                          selected: false,
                          onSelected: _isRunning ? null : (selected) {
                            if (selected) {
                              setState(() {
                                _workDuration = 30;
                                _remainingSeconds = 30 * 60;
                              });
                            }
                          },
                        ),
                        ChoiceChip(
                          label: const Text('45分钟'),
                          selected: false,
                          onSelected: _isRunning ? null : (selected) {
                            if (selected) {
                              setState(() {
                                _workDuration = 45;
                                _remainingSeconds = 45 * 60;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: const Color(0xFF1A1A2E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '$_completedPomodoros',
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF667EEA)),
                          ),
                          const Text('完成番茄'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '$_totalMinutes',
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF667EEA)),
                          ),
                          const Text('总分钟数'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Color _getPhaseColor() {
    switch (_phase) {
      case PomodoroPhase.work:
        return const Color(0xFF667EEA);
      case PomodoroPhase.shortBreak:
        return const Color(0xFF4ADE80);
      case PomodoroPhase.longBreak:
        return const Color(0xFF4ADE80);
      case PomodoroPhase.idle:
        return const Color(0xFF667EEA);
    }
  }
  
  String _getPhaseLabel() {
    switch (_phase) {
      case PomodoroPhase.work:
        return '工作中';
      case PomodoroPhase.shortBreak:
        return '短休息';
      case PomodoroPhase.longBreak:
        return '长休息';
      case PomodoroPhase.idle:
        return '番茄钟';
    }
  }
}
