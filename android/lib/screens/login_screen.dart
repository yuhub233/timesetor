import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _serverUrlController = TextEditingController();
  final _internalUrlController = TextEditingController();
  final _externalUrlController = TextEditingController();
  bool _isRegister = false;
  bool _isLoading = false;
  bool _showServerConfig = false;
  bool _testingConnection = false;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _serverUrlController.text = ApiService.baseUrl.replaceAll('/api', '');
    _internalUrlController.text = ApiService.internalUrl?.replaceAll('/api', '') ?? '';
    _externalUrlController.text = ApiService.externalUrl?.replaceAll('/api', '') ?? '';
  }
  
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _serverUrlController.dispose();
    _internalUrlController.dispose();
    _externalUrlController.dispose();
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
  
  Future<void> _testConnection() async {
    setState(() { _testingConnection = true; _error = null; });
    final url = _serverUrlController.text.trim();
    final success = await ApiService.testConnection(url);
    setState(() => _testingConnection = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? '连接成功!' : '连接失败，请检查地址')),
      );
    }
  }
  
  Future<void> _saveServerUrl() async {
    final url = _serverUrlController.text.trim();
    if (url.isEmpty) {
      setState(() => _error = '请输入服务器地址');
      return;
    }
    await ApiService.setServerUrl(url);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('服务器地址已保存: ${ApiService.baseUrl}')),
      );
    }
  }
  
  Future<void> _saveNetworkUrls() async {
    final internal = _internalUrlController.text.trim();
    final external = _externalUrlController.text.trim();
    
    await ApiService.setInternalUrl(internal);
    await ApiService.setExternalUrl(external);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('网络配置已保存\n当前使用: ${ApiService.isUsingInternal ? "内网" : "外网"}')),
      );
    }
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('TimeSetor', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF667EEA))),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(_showServerConfig ? Icons.close : Icons.settings, color: Colors.grey[400], size: 20),
                          onPressed: () => setState(() => _showServerConfig = !_showServerConfig),
                          tooltip: '服务器设置',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('不常规时间管理系统', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                    if (_showServerConfig) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('快速配置', style: TextStyle(color: Colors.grey[300], fontSize: 12, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _serverUrlController,
                              decoration: const InputDecoration(
                                labelText: '服务器地址',
                                hintText: '例如: http://192.168.1.100:5000',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _testingConnection ? null : _testConnection,
                                    icon: _testingConnection 
                                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                      : const Icon(Icons.wifi_find, size: 16),
                                    label: const Text('测试'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey[700],
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _saveServerUrl,
                                    icon: const Icon(Icons.save, size: 16),
                                    label: const Text('保存'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF667EEA),
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Text('自动切换内外网', style: TextStyle(color: Colors.grey[300], fontSize: 12, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _internalUrlController,
                              decoration: const InputDecoration(
                                labelText: '内网地址',
                                hintText: '例如: http://192.168.1.100:5000',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _externalUrlController,
                              decoration: const InputDecoration(
                                labelText: '外网地址',
                                hintText: '例如: http://your-domain.com:5000',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _saveNetworkUrls,
                                icon: const Icon(Icons.sync, size: 16),
                                label: const Text('保存并自动检测'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF667EEA),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            if (ApiService.internalUrl != null || ApiService.externalUrl != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  '当前: ${ApiService.isUsingInternal ? "内网" : "外网"}',
                                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
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
