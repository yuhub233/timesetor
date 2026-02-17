import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class SettingsProvider extends ChangeNotifier {
  Map<String, dynamic> _config = {};
  List<String> _entertainmentApps = [];
  List<String> _studyApps = [];
  bool _isLoading = false;
  
  Map<String, dynamic> get config => _config;
  List<String> get entertainmentApps => _entertainmentApps;
  List<String> get studyApps => _studyApps;
  bool get isLoading => _isLoading;
  
  Future<void> loadConfig() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await ApiService.get('/config');
      _config = response;
      if (response['android'] != null) {
        _entertainmentApps = List<String>.from(response['android']['entertainment_apps'] ?? []);
        _studyApps = List<String>.from(response['android']['study_apps'] ?? []);
      }
    } catch (e) { debugPrint('Failed to load config: $e'); }
    _isLoading = false;
    notifyListeners();
  }
  
  bool isEntertainmentApp(String packageName) => _entertainmentApps.contains(packageName);
  bool isStudyApp(String packageName) => _studyApps.contains(packageName);
}