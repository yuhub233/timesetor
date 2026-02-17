import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'dart:ui';

class OverlayService {
  static bool _isRunning = false;
  
  static Future<void> requestPermission() async {
    await FlutterOverlayWindow.requestPermission();
  }
  
  static Future<bool> hasPermission() async {
    return await FlutterOverlayWindow.isPermissionGranted();
  }
  
  static Future<void> showOverlay({
    String virtualTime = '--:--',
    double speed = 1.0,
    String bgColor = '#000000',
    String textColor = '#FFFFFF',
    double fontSize = 24,
    double opacity = 1.0,
  }) async {
    if (!await hasPermission()) {
      debugPrint('Overlay permission not granted');
      return;
    }
    
    await FlutterOverlayWindow.showOverlay(
      height: 60,
      width: 120,
      alignment: OverlayAlignment.topLeft,
      enableDrag: true,
      positionGravity: PositionGravity.left,
    );
    
    await FlutterOverlayWindow.shareData({
      'virtualTime': virtualTime,
      'speed': speed,
      'bgColor': bgColor,
      'textColor': textColor,
      'fontSize': fontSize,
      'opacity': opacity,
    });
    
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
    
    await FlutterOverlayWindow.shareData({
      'virtualTime': virtualTime,
      'speed': speed,
      'bgColor': bgColor,
      'textColor': textColor,
      'fontSize': fontSize,
      'opacity': opacity,
    });
  }
  
  static Future<void> hideOverlay() async {
    await FlutterOverlayWindow.closeOverlay();
    _isRunning = false;
  }
  
  static bool get isRunning => _isRunning;
}

@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Material(
        color: Colors.transparent,
        child: OverlayWidget(),
      ),
    ),
  );
}

class OverlayWidget extends StatefulWidget {
  const OverlayWidget({super.key});

  @override
  State<OverlayWidget> createState() => _OverlayWidgetState();
}

class _OverlayWidgetState extends State<OverlayWidget> {
  String _virtualTime = '--:--';
  double _speed = 1.0;
  String _bgColor = '#000000';
  String _textColor = '#FFFFFF';
  double _fontSize = 24;
  double _opacity = 1.0;
  
  @override
  void initState() {
    super.initState();
    FlutterOverlayWindow.overlayListener.listen((data) {
      setState(() {
        _virtualTime = data?['virtualTime'] ?? '--:--';
        _speed = data?['speed'] ?? 1.0;
        _bgColor = data?['bgColor'] ?? '#000000';
        _textColor = data?['textColor'] ?? '#FFFFFF';
        _fontSize = data?['fontSize'] ?? 24.0;
        _opacity = data?['opacity'] ?? 1.0;
      });
    });
  }
  
  Color _parseColor(String hexColor) {
    try {
      hexColor = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hexColor', radix: 16));
    } catch (_) {
      return Colors.black;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _parseColor(_bgColor).withOpacity(_opacity),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _virtualTime,
        style: TextStyle(
          color: _parseColor(_textColor),
          fontSize: _fontSize,
          fontWeight: FontWeight.bold,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
