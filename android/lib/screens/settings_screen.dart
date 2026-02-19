import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../constants/app_constants.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('服务器', [
            Consumer<SettingsProvider>(
              builder: (context, settings, _) => ListTile(
                title: const Text('服务器地址'),
                subtitle: Text(settings.serverUrl),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showServerDialog(context, settings),
              ),
            ),
          ]),
          _buildSection('账户', [
            ListTile(
              title: const Text('退出登录'),
              leading: const Icon(Icons.logout, color: Colors.red),
              textColor: Colors.red,
              onTap: () => _showLogoutDialog(context),
            ),
          ]),
          _buildSection('关于', [
            const ListTile(
              title: Text('版本'),
              subtitle: Text('1.0.0'),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Card(
          color: AppConstants.cardColor,
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Future<void> _showServerDialog(BuildContext context, SettingsProvider settings) async {
    final controller = TextEditingController(text: settings.serverUrl);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('服务器地址'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'http://localhost:5000/api',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await settings.setServerUrl(result);
    }
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('退出'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<AuthProvider>().logout();
    }
  }
}
