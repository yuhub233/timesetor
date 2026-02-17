import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _wakeTimeController = TextEditingController(text: '08:00');
  final _sleepTimeController = TextEditingController(text: '23:00');
  final _entertainmentController = TextEditingController(text: '2');
  final _studyController = TextEditingController(text: '4');
  bool _saving = false;
  String? _message;
  
  @override
  void initState() { super.initState(); _loadSettings(); }
  
  void _loadSettings() {
    final settings = context.read<AuthProvider>().settings;
    if (settings.isNotEmpty) {
      _wakeTimeController.text = settings['target_wake_time'] ?? '08:00';
      _sleepTimeController.text = settings['target_sleep_time'] ?? '23:00';
      _entertainmentController.text = (settings['target_entertainment_hours'] ?? 2).toString();
      _studyController.text = (settings['target_study_hours'] ?? 4).toString();
    }
  }
  
  @override
  void dispose() {
    _wakeTimeController.dispose();
    _sleepTimeController.dispose();
    _entertainmentController.dispose();
    _studyController.dispose();
    super.dispose();
  }
  
  Future<void> _saveSettings() async {
    setState(() { _saving = true; _message = null; });
    try {
      await context.read<AuthProvider>().updateSettings({
        'target_wake_time': _wakeTimeController.text,
        'target_sleep_time': _sleepTimeController.text,
        'target_entertainment_hours': double.tryParse(_entertainmentController.text) ?? 2,
        'target_study_hours': double.tryParse(_studyController.text) ?? 4,
      });
      setState(() => _message = '设置已保存');
    } catch (e) { setState(() => _message = '保存失败: $e'); }
    setState(() => _saving = false);
    Future.delayed(const Duration(seconds: 3), () { if (mounted) setState(() => _message = null); });
  }
  
  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('确定')),
        ],
      ),
    );
    if (confirmed == true && mounted) await context.read<AuthProvider>().logout();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              color: const Color(0xFF1A1A2E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('时间设置', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    TextField(controller: _wakeTimeController, decoration: const InputDecoration(labelText: '目标起床时间', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextField(controller: _sleepTimeController, decoration: const InputDecoration(labelText: '目标睡觉时间', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextField(controller: _entertainmentController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '目标娱乐时长（小时）', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextField(controller: _studyController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '目标学习时长（小时）', border: OutlineInputBorder())),
                    const SizedBox(height: 16),
                    SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _saving ? null : _saveSettings, child: Text(_saving ? '保存中...' : '保存设置'))),
                    if (_message != null) ...[
                      const SizedBox(height: 8),
                      Text(_message!, style: TextStyle(color: _message!.contains('失败') ? Colors.red : Colors.green)),
                    ],
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('账户', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Text('用户ID: ${context.watch<AuthProvider>().userId ?? "未知"}', style: TextStyle(color: Colors.grey[400])),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: _logout, style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), child: const Text('退出登录')),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('关于', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text('TimeSetor v1.0.0\n不常规时间管理系统', style: TextStyle(color: Colors.grey[400])),
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