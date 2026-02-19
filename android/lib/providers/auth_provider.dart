import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  User? _user;
  String? _error;
  bool _isLoading = false;

  bool get isLoggedIn => _isLoggedIn;
  User? get user => _user;
  String? get error => _error;
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    try {
      final token = StorageService.getToken();
      final userId = StorageService.getUserId();
      if (token != null && userId != null) {
        _isLoggedIn = true;
        _user = User(id: userId, username: '');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Auth initialize error: $e');
    }
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await ApiService.post('/auth/login', {
        'username': username,
        'password': password,
      });

      final token = response['token'] as String;
      final userId = response['user_id'] as int;

      await ApiService.setToken(token);
      await StorageService.setUserId(userId);

      _user = User.fromJson(response);
      _isLoggedIn = true;
      _setLoading(false);
      notifyListeners();

      return {'success': true};
    } on ApiException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return {'success': false, 'error': e.message};
    } catch (e) {
      _setError('登录失败');
      _setLoading(false);
      return {'success': false, 'error': '登录失败'};
    }
  }

  Future<Map<String, dynamic>> register(String username, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await ApiService.post('/auth/register', {
        'username': username,
        'password': password,
      });

      final token = response['token'] as String;
      final userId = response['user_id'] as int;

      await ApiService.setToken(token);
      await StorageService.setUserId(userId);

      _user = User.fromJson(response);
      _isLoggedIn = true;
      _setLoading(false);
      notifyListeners();

      return {'success': true};
    } on ApiException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return {'success': false, 'error': e.message};
    } catch (e) {
      _setError('注册失败');
      _setLoading(false);
      return {'success': false, 'error': '注册失败'};
    }
  }

  Future<void> logout() async {
    await ApiService.clearToken();
    await StorageService.clearUserId();
    _isLoggedIn = false;
    _user = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
