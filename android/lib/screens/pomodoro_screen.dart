import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pomodoro_provider.dart';
import '../constants/app_constants.dart';

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PomodoroProvider>().fetchStats();
    });
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('番茄钟')),
      body: Consumer<PomodoroProvider>(
        builder: (context, pomodoro, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Card(
                  color: AppConstants.cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Text(
                          pomodoro.phaseLabel,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 200,
                              height: 200,
                              child: CircularProgressIndicator(
                                value: pomodoro.progress,
                                strokeWidth: 8,
                                backgroundColor: Colors.grey.withOpacity(0.2),
                                valueColor: const AlwaysStoppedAnimation(
                                  AppConstants.primaryColor,
                                ),
                              ),
                            ),
                            Text(
                              _formatTime(pomodoro.remainingSeconds),
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
                            if (!pomodoro.isRunning || pomodoro.isPaused)
                              ElevatedButton(
                                onPressed: pomodoro.isPaused
                                    ? () => pomodoro.resume()
                                    : () => pomodoro.startWork(),
                                child: Text(pomodoro.isPaused ? '继续' : '开始'),
                              )
                            else
                              ElevatedButton(
                                onPressed: () => pomodoro.pause(),
                                child: const Text('暂停'),
                              ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: () => pomodoro.reset(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.withOpacity(0.2),
                              ),
                              child: const Text('重置'),
                            ),
                          ],
                        ),
                        if (!pomodoro.isRunning && !pomodoro.isPaused) ...[
                          const SizedBox(height: 24),
                          const Text('时长（分钟）'),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [15, 25, 30, 45, 60].map((d) {
                              return ChoiceChip(
                                label: Text('$d'),
                                selected: d == AppConstants.defaultPomodoroWorkDuration,
                                onSelected: (selected) {
                                  if (selected) {
                                    pomodoro.startWork(durationMinutes: d);
                                  }
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  color: AppConstants.cardColor,
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
                                '${pomodoro.completedWorkSessions}',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: AppConstants.primaryColor,
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
                                '${pomodoro.totalMinutes}',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: AppConstants.primaryColor,
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
          );
        },
      ),
    );
  }
}
