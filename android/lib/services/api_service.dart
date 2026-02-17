import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static String _baseUrl = 'http://localhost:5000/api';
  static String? _token;
  
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _baseUrl = prefs.getString('serverUrl') ?? 'http://localhost:5000/api';
  }
  
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
  
  static String get baseUrl => _baseUrl;
  static String? get token => _token;
  
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
