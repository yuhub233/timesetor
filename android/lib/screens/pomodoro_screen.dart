import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  final List<int> _durations = [15, 25, 30, 45, 60];
  int _selectedDuration = 25;
  int _remainingSeconds = 25 * 60;
  bool _isRunning = false;
  int? _sessionId;
  Timer? _timer;
  
  int _completedCount = 0;
  int _totalMinutes = 0;
  
  @override
  void initState() {
    super.initState();
    _fetchStats();
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  
  Future<void> _fetchStats() async {
    try {
      final response = await ApiService.get('/data/daily');
      final sessions = response['pomodoro_sessions'] as List? ?? [];
      setState(() {
        _completedCount = sessions.where((s) => s['status'] == 'completed').length;
        _totalMinutes = sessions.fold(0, (sum, s) => sum + (s['actual_duration_minutes'] as int? ?? 0));
      });
    } catch (_) {}
  }
  
  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
  
  Future<void> _startTimer() async {
    if (_sessionId == null) {
      try {
        final response = await ApiService.post('/pomodoro/start', {
          'duration_minutes': _selectedDuration,
          'session_type': 'work',
        });
        _sessionId = response['session_id'];
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('启动失败: $e')),
          );
        }
        return;
      }
    }
    
    setState(() => _isRunning = true);
    
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _completeTimer();
      }
    });
  }
  
  void _pauseTimer() {
    setState(() => _isRunning = false);
    _timer?.cancel();
    _timer = null;
  }
  
  Future<void> _resetTimer() async {
    _pauseTimer();
    setState(() {
      _remainingSeconds = _selectedDuration * 60;
      _sessionId = null;
    });
  }
  
  Future<void> _completeTimer() async {
    _pauseTimer();
    
    if (_sessionId != null) {
      try {
        await ApiService.post('/pomodoro/end', {
          'session_id': _sessionId,
          'actual_duration_minutes': _selectedDuration,
          'status': 'completed',
        });
        setState(() {
          _completedCount++;
          _totalMinutes += _selectedDuration;
        });
      } catch (_) {}
    }
    
    await NotificationService.showPomodoroComplete();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🍅 番茄钟完成！')),
      );
    }
    
    _resetTimer();
  }
  
  @override
  Widget build(BuildContext context) {
    final progress = 1 - (_remainingSeconds / (_selectedDuration * 60));
    
    return Scaffold(
      appBar: AppBar(title: const Text('番茄钟')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              color: const Color(0xFF1A1A2E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Text(
                      '番茄钟',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                            valueColor: const AlwaysStoppedAnimation(
                              Color(0xFF667EEA),
                            ),
                          ),
                        ),
                        Text(
                          _formatTime(_remainingSeconds),
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: _isRunning ? _pauseTimer : _startTimer,
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
                    const Text('时长（分钟）'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _durations.map((d) => ChoiceChip(
                        label: Text('$d'),
                        selected: _selectedDuration == d,
                        onSelected: _isRunning
                            ? null
                            : (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedDuration = d;
                                    _remainingSeconds = d * 60;
                                  });
                                }
                              },
                      )).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: const Color(0xFF1A1A2E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '$_completedCount',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF667EEA),
                            ),
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
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF667EEA),
                            ),
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
}
