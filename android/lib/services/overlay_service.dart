import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui';

class OverlayService {
  static bool _isRunning = false;
  
  static Future<void> requestPermission() async {
    debugPrint('Overlay permission requested');
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
    debugPrint('Overlay not supported in this version');
    _isRunning = false;
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
    debugPrint('Overlay update: $virtualTime');
  }
  
  static Future<void> hideOverlay() async {
    _isRunning = false;
    debugPrint('Overlay hidden');
  }
  
  static bool get isRunning => _isRunning;
}
