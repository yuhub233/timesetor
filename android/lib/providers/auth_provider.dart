import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  String? _userId;
  Map<String, dynamic> _settings = {};
  
  bool get isLoggedIn => _isLoggedIn;
  String? get userId => _userId;
  Map<String, dynamic> get settings => _settings;
  
  Future<void> checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('userId');
    final token = prefs.getString('token');
    
    if (token != null && _userId != null) {
      await ApiService.setToken(token);
      _isLoggedIn = true;
      _settings = _parseSettings(prefs.getString('settings'));
    }
    
    notifyListeners();
  }
  
  Map<String, dynamic> _parseSettings(String? json) {
    if (json == null) return {};
    try {
      return Map<String, dynamic>.from(const JsonDecoder().convert(json));
    } catch (_) {
      return {};
    }
  }
  
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await ApiService.post('/auth/login', {
        'username': username,
        'password': password,
      });
      
      await _saveAuth(response);
      _isLoggedIn = true;
      notifyListeners();
      
      return {'success': true};
    } on ApiException catch (e) {
      return {'success': false, 'error': e.message};
    } catch (e) {
      return {'success': false, 'error': '登录失败'};
    }
  }
  
  Future<Map<String, dynamic>> register(String username, String password) async {
    try {
      final response = await ApiService.post('/auth/register', {
        'username': username,
        'password': password,
      });
      
      await _saveAuth(response);
      _isLoggedIn = true;
      notifyListeners();
      
      return {'success': true};
    } on ApiException catch (e) {
      return {'success': false, 'error': e.message};
    } catch (e) {
      return {'success': false, 'error': '注册失败'};
    }
  }
  
  Future<void> _saveAuth(Map<String, dynamic> response) async {
    final prefs = await SharedPreferences.getInstance();
    
    _userId = response['user_id'].toString();
    await prefs.setString('userId', _userId!);
    
    await ApiService.setToken(response['token']);
    await prefs.setString('token', response['token']);
    
    if (response['settings'] != null) {
      _settings = Map<String, dynamic>.from(response['settings']);
      await prefs.setString('settings', const JsonEncoder().convert(_settings));
    }
  }
  
  Future<void> updateSettings(Map<String, dynamic> newSettings) async {
    try {
      await ApiService.put('/user/settings', {'settings': newSettings});
      
      _settings = {..._settings, ...newSettings};
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('settings', const JsonEncoder().convert(_settings));
      
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
  
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userId');
    await prefs.remove('settings');
    await ApiService.clearToken();
    
    _isLoggedIn = false;
    _userId = null;
    _settings = {};
    
    notifyListeners();
  }
}
