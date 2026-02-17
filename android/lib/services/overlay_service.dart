import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class OverlayService {
  static bool _isRunning = false;
  
  static Future<void> requestPermission() async {
    debugPrint('Overlay permission request - feature temporarily disabled');
  }
  
  static Future<bool> hasPermission() async {
    return false;
  }
  
  static Future<void> showOverlay({
    String virtualTime = '--:--',
    double speed = 1.0,
    String bgColor = '#000000',
    String textColor = '#FFFFFF',
    double fontSize = 24,
    double opacity = 1.0,
  }) async {
    debugPrint('Overlay show - feature temporarily disabled');
    _isRunning = true;
  }
  
  static Future<void> updateOverlay({
    String? virtualTime,
    double? speed,
    String? bgColor,
    String? textColor,
    double? fontSize,
    double? opacity,
  }) async {
    if (!_isRunning) return;
    debugPrint('Overlay update - feature temporarily disabled');
  }
  
  static Future<void> hideOverlay() async {
    debugPrint('Overlay hide - feature temporarily disabled');
    _isRunning = false;
  }
  
  static bool get isRunning => _isRunning;
}
