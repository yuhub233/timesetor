import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegister = false;
  bool _isLoading = false;
  String? _error;
  
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  Future<void> _handleSubmit() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _error = '请填写用户名和密码');
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    final authProvider = context.read<AuthProvider>();
    Map<String, dynamic> result = _isRegister
        ? await authProvider.register(_usernameController.text, _passwordController.text)
        : await authProvider.login(_usernameController.text, _passwordController.text);
    setState(() => _isLoading = false);
    if (!result['success']) setState(() => _error = result['error']);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              color: const Color(0xFF1A1A2E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('TimeSetor', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF667EEA))),
                    const SizedBox(height: 8),
                    Text('不常规时间管理系统', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                    const SizedBox(height: 32),
                    TextField(controller: _usernameController, decoration: const InputDecoration(labelText: '用户名', border: OutlineInputBorder())),
                    const SizedBox(height: 16),
                    TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: '密码', border: OutlineInputBorder())),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(_isRegister ? '注册' : '登录'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(onPressed: () => setState(() => _isRegister = !_isRegister), child: Text(_isRegister ? '已有账号？登录' : '没有账号？注册')),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}