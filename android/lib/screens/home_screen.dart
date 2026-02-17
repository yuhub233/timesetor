import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/time_provider.dart';
import '../providers/auth_provider.dart';
import 'pomodoro_screen.dart';
import 'data_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = const [
    TimeDisplayScreen(),
    PomodoroScreen(),
    DataScreen(),
    SettingsScreen(),
  ];
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TimeProvider>().fetchCurrentTime();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.access_time_outlined),
            selectedIcon: Icon(Icons.access_time),
            label: '时间',
          ),
          NavigationDestination(
            icon: Icon(Icons.timer_outlined),
            selectedIcon: Icon(Icons.timer),
            label: '番茄钟',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: '数据',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }
}

class TimeDisplayScreen extends StatelessWidget {
  const TimeDisplayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TimeSetor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<TimeProvider>().fetchCurrentTime(),
          ),
        ],
      ),
      body: Consumer<TimeProvider>(
        builder: (context, timeProvider, _) {
          if (!timeProvider.isAwake) {
            return _buildWakePrompt(context, timeProvider);
          }
          return _buildTimeDisplay(context, timeProvider);
        },
      ),
    );
  }
  
  Widget _buildWakePrompt(BuildContext context, TimeProvider timeProvider) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(24),
        color: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '早安！',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                '点击下方按钮记录起床时间',
                style: TextStyle(color: Colors.grey[400]),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final result = await timeProvider.recordWake();
                  if (!result['success'] && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(result['error'])),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                ),
                child: const Text('起床', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTimeDisplay(BuildContext context, TimeProvider timeProvider) {
    return SingleChildScrollView(
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
                  Text(
                    timeProvider.virtualTime,
                    style: TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.bold,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      foreground: Paint()
                        ..shader = const LinearGradient(
                          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                        ).createShader(const Rect.fromLTWH(0, 0, 400, 100)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSpeedBadge(timeProvider.currentSpeed),
                      const SizedBox(width: 16),
                      _buildActivityIndicator(timeProvider.currentActivity),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '真实时间: ${_formatRealTime(timeProvider.realTime)}',
                    style: TextStyle(color: Colors.grey[400]),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '当前活动',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActivityButton(
                          context,
                          '休息',
                          'rest',
                          timeProvider,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildActivityButton(
                          context,
                          '娱乐',
                          'entertainment',
                          timeProvider,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildActivityButton(
                          context,
                          '学习',
                          'study',
                          timeProvider,
                        ),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('确认睡觉'),
                        content: const Text('确定要记录睡觉时间吗？'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('取消'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('确定'),
                          ),
                        ],
                      ),
                    );
                    
                    if (confirmed == true) {
                      final result = await timeProvider.recordSleep();
                      if (!result['success'] && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(result['error'])),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('睡觉'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSpeedBadge(double speed) {
    String text;
    Color color;
    
    if (speed > 1.5) {
      text = '${speed.toStringAsFixed(1)}x 快';
      color = const Color(0xFF667EEA);
    } else if (speed < 0.8) {
      text = '${speed.toStringAsFixed(1)}x 慢';
      color = const Color(0xFFF5576C);
    } else {
      text = '正常';
      color = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
    );
  }
  
  Widget _buildActivityIndicator(String activity) {
    final labels = {
      'rest': '休息中',
      'entertainment': '娱乐中',
      'study': '学习中',
    };
    
    final colors = {
      'rest': const Color(0xFF4ADE80),
      'entertainment': const Color(0xFFF5576C),
      'study': const Color(0xFF667EEA),
    };
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: colors[activity] ?? Colors.grey,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(labels[activity] ?? '未知'),
      ],
    );
  }
  
  Widget _buildActivityButton(
    BuildContext context,
    String label,
    String activity,
    TimeProvider timeProvider,
  ) {
    final isSelected = timeProvider.currentActivity == activity;
    
    return ElevatedButton(
      onPressed: () => timeProvider.updateActivity(activity),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? null : Colors.grey.withOpacity(0.2),
        foregroundColor: isSelected ? null : Colors.grey,
      ),
      child: Text(label),
    );
  }
  
  String _formatRealTime(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '--:--';
    try {
      final dateTime = DateTime.parse(isoString);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '--:--';
    }
  }
}
