class AppConstants {
  static const String defaultServerUrl = 'http://localhost:5000/api';
  
  static const String keyToken = 'token';
  static const String keyServerUrl = 'serverUrl';
  static const String keyUserId = 'userId';
  
  static const Color primaryColor = Color(0xFF667EEA);
  static const Color secondaryColor = Color(0xFF764BA2);
  static const Color backgroundColor = Color(0xFF0F0F1A);
  static const Color cardColor = Color(0xFF1A1A2E);
  static const Color restColor = Color(0xFF4ADE80);
  static const Color entertainmentColor = Color(0xFFF5576C);
  static const Color studyColor = Color(0xFF667EEA);
  
  static const Duration autoUpdateInterval = Duration(seconds: 1);
  
  static const int defaultPomodoroWorkDuration = 25;
  static const int defaultPomodoroShortBreak = 5;
  static const int defaultPomodoroLongBreak = 15;
  static const int pomodoroLongBreakInterval = 4;
}
