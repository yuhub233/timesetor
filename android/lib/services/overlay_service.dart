import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui';

class OverlayService {
  static bool _isRunning = false;
  static OverlayEntry? _overlayEntry;
  static String _virtualTime = '--:--';
  static double _speed = 1.0;
  static Offset _position = const Offset(10, 50);
  
  static Future<void> requestPermission() async {
    debugPrint('In-app overlay does not require permission');
  }
  
  static Future<bool> hasPermission() async {
    return true;
  }
  
  static void showOverlayGlobal(BuildContext context, {
    String virtualTime = '--:--',
    double speed = 1.0,
  }) {
    _virtualTime = virtualTime;
    _speed = speed;
    
    if (_isRunning) {
      updateOverlayGlobal(virtualTime: virtualTime, speed: speed);
      return;
    }
    
    _overlayEntry = OverlayEntry(
      builder: (context) => _FloatingTimeWidget(
        initialPosition: _position,
        virtualTime: _virtualTime,
        speed: _speed,
        onPositionChanged: (newPosition) {
          _position = newPosition;
        },
        onUpdateTime: (newTime, newSpeed) {
          _virtualTime = newTime;
          _speed = newSpeed;
        },
      ),
    );
    
    Overlay.of(context).insert(_overlayEntry!);
    _isRunning = true;
  }
  
  static void updateOverlayGlobal({
    String? virtualTime,
    double? speed,
  }) {
    if (!_isRunning || _overlayEntry == null) return;
    
    if (virtualTime != null) _virtualTime = virtualTime;
    if (speed != null) _speed = speed;
    
    _overlayEntry!.markNeedsBuild();
  }
  
  static void hideOverlayGlobal() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
    _isRunning = false;
  }
  
  static Future<void> showOverlay({
    String virtualTime = '--:--',
    double speed = 1.0,
    String bgColor = '#000000',
    String textColor = '#FFFFFF',
    double fontSize = 24,
    double opacity = 1.0,
  }) async {
    _virtualTime = virtualTime;
    _speed = speed;
    _isRunning = true;
    debugPrint('Overlay ready: $virtualTime');
  }
  
  static Future<void> updateOverlay({
    String? virtualTime,
    double? speed,
    String? bgColor,
    String? textColor,
    double? fontSize,
    double? opacity,
  }) async {
    if (virtualTime != null) _virtualTime = virtualTime;
    if (speed != null) _speed = speed;
  }
  
  static Future<void> hideOverlay() async {
    _isRunning = false;
  }
  
  static bool get isRunning => _isRunning;
  static String get virtualTime => _virtualTime;
  static double get speed => _speed;
}

class _FloatingTimeWidget extends StatefulWidget {
  final Offset initialPosition;
  final String virtualTime;
  final double speed;
  final Function(Offset) onPositionChanged;
  final Function(String, double) onUpdateTime;
  
  const _FloatingTimeWidget({
    required this.initialPosition,
    required this.virtualTime,
    required this.speed,
    required this.onPositionChanged,
    required this.onUpdateTime,
  });
  
  @override
  State<_FloatingTimeWidget> createState() => _FloatingTimeWidgetState();
}

class _FloatingTimeWidgetState extends State<_FloatingTimeWidget> {
  late Offset _position;
  String _virtualTime = '--:--';
  double _speed = 1.0;
  
  @override
  void initState() {
    super.initState();
    _position = widget.initialPosition;
    _virtualTime = widget.virtualTime;
    _speed = widget.speed;
  }
  
  @override
  void didUpdateWidget(_FloatingTimeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _virtualTime = widget.virtualTime;
    _speed = widget.speed;
  }
  
  Color _getSpeedColor() {
    if (_speed > 1.5) {
      return const Color(0xFF667EEA);
    } else if (_speed < 0.8) {
      return const Color(0xFFF5576C);
    }
    return Colors.grey;
  }
  
  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _position = Offset(
              _position.dx + details.delta.dx,
              _position.dy + details.delta.dy,
            );
            widget.onPositionChanged(_position);
          });
        },
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.85),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getSpeedColor(),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _virtualTime,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getSpeedColor().withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_speed.toStringAsFixed(1)}x',
                    style: TextStyle(
                      color: _getSpeedColor(),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TimeOverlayWrapper extends StatefulWidget {
  final Widget child;
  
  const TimeOverlayWrapper({super.key, required this.child});
  
  @override
  State<TimeOverlayWrapper> createState() => _TimeOverlayWrapperState();
}

class _TimeOverlayWrapperState extends State<TimeOverlayWrapper> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (OverlayService.isRunning)
          ListenableBuilder(
            listenable: _OverlayNotifier.instance,
            builder: (context, child) {
              return _FloatingTimeWidget(
                initialPosition: const Offset(10, 80),
                virtualTime: OverlayService.virtualTime,
                speed: OverlayService.speed,
                onPositionChanged: (_) {},
                onUpdateTime: (_, __) {},
              );
            },
          ),
      ],
    );
  }
}

class _OverlayNotifier extends ChangeNotifier {
  static final _OverlayNotifier instance = _OverlayNotifier._();
  _OverlayNotifier._();
  
  void notify() => notifyListeners();
}
