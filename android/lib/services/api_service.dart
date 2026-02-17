import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static String _baseUrl = 'http://localhost:5000/api';
  static String? _token;
  static String? _internalUrl;
  static String? _externalUrl;
  static bool _useInternal = true;
  
  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');
      _internalUrl = prefs.getString('internalServerUrl');
      _externalUrl = prefs.getString('externalServerUrl');
      
      final savedUrl = prefs.getString('serverUrl');
      if (savedUrl != null && savedUrl.isNotEmpty) {
        _baseUrl = savedUrl;
      }
      
      _useInternal = prefs.getBool('useInternal') ?? true;
      
      await _detectNetworkAndSwitch();
    } catch (e) {
      debugPrint('ApiService initialize error: $e');
    }
  }
  
  static Future<void> _detectNetworkAndSwitch() async {
    try {
      if (_internalUrl == null || _internalUrl!.isEmpty) return;
      if (_externalUrl == null || _externalUrl!.isEmpty) return;
      
      bool isInternal = await _checkInternalNetwork();
      
      if (isInternal && _useInternal) {
        _baseUrl = _internalUrl!;
      } else {
        _baseUrl = _externalUrl!;
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('serverUrl', _baseUrl);
      await prefs.setBool('useInternal', isInternal);
    } catch (e) {
      debugPrint('Network detection error: $e');
    }
  }
  
  static Future<bool> _checkInternalNetwork() async {
    if (_internalUrl == null || _internalUrl!.isEmpty) return false;
    
    try {
      final testUrl = _internalUrl!.replaceAll('/api', '/api/health');
      final response = await http.get(
        Uri.parse(testUrl),
      ).timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Internal network check failed: $e');
      return false;
    }
  }
  
  static Future<bool> testConnection(String url) async {
    try {
      String testUrl = url;
      if (!testUrl.endsWith('/api')) {
        if (testUrl.endsWith('/')) {
          testUrl = '${testUrl}api';
        } else {
          testUrl = '$testUrl/api';
        }
      }
      final response = await http.get(
        Uri.parse('$testUrl/health'),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Connection test failed: $e');
      return false;
    }
  }
  
  static Future<void> setServerUrl(String url) async {
    if (!url.endsWith('/api')) {
      if (url.endsWith('/')) {
        url = '${url}api';
      } else {
        url = '$url/api';
      }
    }
    _baseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('serverUrl', url);
  }
  
  static Future<void> setInternalUrl(String url) async {
    if (url.isNotEmpty && !url.endsWith('/api')) {
      if (url.endsWith('/')) {
        url = '${url}api';
      } else {
        url = '$url/api';
      }
    }
    _internalUrl = url.isEmpty ? null : url;
    final prefs = await SharedPreferences.getInstance();
    if (url.isEmpty) {
      await prefs.remove('internalServerUrl');
    } else {
      await prefs.setString('internalServerUrl', url);
    }
    await _detectNetworkAndSwitch();
  }
  
  static Future<void> setExternalUrl(String url) async {
    if (url.isNotEmpty && !url.endsWith('/api')) {
      if (url.endsWith('/')) {
        url = '${url}api';
      } else {
        url = '$url/api';
      }
    }
    _externalUrl = url.isEmpty ? null : url;
    final prefs = await SharedPreferences.getInstance();
    if (url.isEmpty) {
      await prefs.remove('externalServerUrl');
    } else {
      await prefs.setString('externalServerUrl', url);
    }
    await _detectNetworkAndSwitch();
  }
  
  static String get baseUrl => _baseUrl;
  static String? get internalUrl => _internalUrl;
  static String? get externalUrl => _externalUrl;
  static bool get isUsingInternal => _useInternal;
  static String? get token => _token;
  
  static Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }
  
  static Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }
  
  static Map<String, String> _headers({Map<String, String>? extra}) {
    final headers = {'Content-Type': 'application/json', ...?extra};
    if (_token != null) headers['Authorization'] = 'Bearer $_token';
    return headers;
  }
  
  static Future<Map<String, dynamic>> get(String endpoint) async {
    final response = await http.get(Uri.parse('$_baseUrl$endpoint'), headers: _headers());
    return _handleResponse(response);
  }
  
  static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    final response = await http.post(Uri.parse('$_baseUrl$endpoint'), headers: _headers(), body: jsonEncode(data));
    return _handleResponse(response);
  }
  
  static Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> data) async {
    final response = await http.put(Uri.parse('$_baseUrl$endpoint'), headers: _headers(), body: jsonEncode(data));
    return _handleResponse(response);
  }
  
  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.body.isEmpty) return {};
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) throw ApiException(message: data['error'] ?? 'Request failed', statusCode: response.statusCode);
    return data;
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException({required this.message, required this.statusCode});
  @override
  String toString() => message;
}
