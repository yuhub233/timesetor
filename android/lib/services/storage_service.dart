import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class StorageService {
  static SharedPreferences? _prefs;

  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static String? getToken() {
    return _prefs?.getString(AppConstants.keyToken);
  }

  static Future<void> setToken(String token) async {
    await _prefs?.setString(AppConstants.keyToken, token);
  }

  static Future<void> clearToken() async {
    await _prefs?.remove(AppConstants.keyToken);
  }

  static String getServerUrl() {
    return _prefs?.getString(AppConstants.keyServerUrl) ?? AppConstants.defaultServerUrl;
  }

  static Future<void> setServerUrl(String url) async {
    await _prefs?.setString(AppConstants.keyServerUrl, url);
  }

  static int? getUserId() {
    return _prefs?.getInt(AppConstants.keyUserId);
  }

  static Future<void> setUserId(int userId) async {
    await _prefs?.setInt(AppConstants.keyUserId, userId);
  }

  static Future<void> clearUserId() async {
    await _prefs?.remove(AppConstants.keyUserId);
  }
}
