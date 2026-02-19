import 'dart:convert';
import 'package:http/http.dart' as http;
import 'storage_service.dart';

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException({required this.message, required this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  static String _baseUrl = '';
  static String? _token;

  static Future<void> initialize() async {
    _baseUrl = StorageService.getServerUrl();
    _token = StorageService.getToken();
  }

  static Future<void> setServerUrl(String url) async {
    _baseUrl = url;
    await StorageService.setServerUrl(url);
  }

  static Future<void> setToken(String token) async {
    _token = token;
    await StorageService.setToken(token);
  }

  static Future<void> clearToken() async {
    _token = null;
    await StorageService.clearToken();
  }

  static String? get token => _token;
  static String get baseUrl => _baseUrl;

  static Map<String, String> _headers({Map<String, String>? extra}) {
    final headers = {
      'Content-Type': 'application/json',
      ...?extra,
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  static Future<Map<String, dynamic>> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('$_baseUrl$endpoint'),
      headers: _headers(),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl$endpoint'),
      headers: _headers(),
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final response = await http.put(
      Uri.parse('$_baseUrl$endpoint'),
      headers: _headers(),
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.body.isEmpty) {
      return {};
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 400) {
      throw ApiException(
        message: data['error'] ?? 'Request failed',
        statusCode: response.statusCode,
      );
    }

    return data;
  }

  static Future<bool> testConnection(String url) async {
    try {
      final response = await http
          .get(Uri.parse('$url/health'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
