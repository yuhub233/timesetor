import 'package:flutter/foundation.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../constants/app_constants.dart';

class SettingsProvider extends ChangeNotifier {
  String _serverUrl = AppConstants.defaultServerUrl;

  String get serverUrl => _serverUrl;

  Future<void> initialize() async {
    _serverUrl = StorageService.getServerUrl();
    notifyListeners();
  }

  Future<void> setServerUrl(String url) async {
    _serverUrl = url;
    await StorageService.setServerUrl(url);
    await ApiService.setServerUrl(url);
    notifyListeners();
  }

  Future<bool> testConnection(String url) async {
    return await ApiService.testConnection(url);
  }
}
