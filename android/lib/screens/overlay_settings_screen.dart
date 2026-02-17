import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/overlay_service.dart';

class OverlaySettingsScreen extends StatefulWidget {
  const OverlaySettingsScreen({super.key});
  @override
  State<OverlaySettingsScreen> createState() => _OverlaySettingsScreenState();
}

class _OverlaySettingsScreenState extends State<OverlaySettingsScreen> {
  double _opacity = 0.8;
  double _fontSize = 24;
  Color _bgColor = Colors.black;
  Color _textColor = Colors.white;
  String _position = 'topLeft';
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _opacity = prefs.getDouble('overlay_opacity') ?? 0.8;
      _fontSize = prefs.getDouble('overlay_fontSize') ?? 24;
      final bgHex = prefs.getString('overlay_bgColor') ?? '#000000';
      final textHex = prefs.getString('overlay_textColor') ?? '#FFFFFF';
      _bgColor = _parseColor(bgHex);
      _textColor = _parseColor(textHex);
      _position = prefs.getString('overlay_position') ?? 'topLeft';
    });
  }
  
  Color _parseColor(String hex) {
    try {
      hex = hex.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return Colors.black;
    }
  }
  
  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }
  
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('overlay_opacity', _opacity);
    await prefs.setDouble('overlay_fontSize', _fontSize);
    await prefs.setString('overlay_bgColor', _colorToHex(_bgColor));
    await prefs.setString('overlay_textColor', _colorToHex(_textColor));
    await prefs.setString('overlay_position', _position);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('设置已保存')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('悬浮窗设置')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: const Color(0xFF1A1A2E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('外观设置', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    Text('不透明度: ${(_opacity * 100).toInt()}%'),
                    Slider(
                      value: _opacity,
                      min: 0.1,
                      max: 1.0,
                      divisions: 9,
                      onChanged: (v) => setState(() => _opacity = v),
                    ),
                    const SizedBox(height: 8),
                    Text('字体大小: ${_fontSize.toInt()}'),
                    Slider(
                      value: _fontSize,
                      min: 12,
                      max: 48,
                      divisions: 12,
                      onChanged: (v) => setState(() => _fontSize = v),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: const Color(0xFF1A1A2E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('颜色设置', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('背景颜色: '),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () async {
                            final color = await showDialog<Color>(
                              context: context,
                              builder: (context) => _ColorPickerDialog(initialColor: _bgColor),
                            );
                            if (color != null) setState(() => _bgColor = color);
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _bgColor,
                              border: Border.all(color: Colors.white),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('文字颜色: '),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () async {
                            final color = await showDialog<Color>(
                              context: context,
                              builder: (context) => _ColorPickerDialog(initialColor: _textColor),
                            );
                            if (color != null) setState(() => _textColor = color);
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _textColor,
                              border: Border.all(color: Colors.white),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: const Color(0xFF1A1A2E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('预览', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _bgColor.withOpacity(_opacity),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '12:34',
                          style: TextStyle(
                            color: _textColor,
                            fontSize: _fontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('保存设置'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  const _ColorPickerDialog({required this.initialColor});
  
  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late Color _selectedColor;
  
  final List<Color> _presetColors = [
    Colors.black, Colors.white, Colors.red, Colors.pink,
    Colors.purple, Colors.deepPurple, Colors.indigo, Colors.blue,
    Colors.lightBlue, Colors.cyan, Colors.teal, Colors.green,
    Colors.lightGreen, Colors.lime, Colors.yellow, Colors.amber,
    Colors.orange, Colors.deepOrange, Colors.brown, Colors.grey,
  ];
  
  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择颜色'),
      content: SizedBox(
        width: 240,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _presetColors.map((color) {
            final isSelected = _selectedColor.value == color.value;
            return GestureDetector(
              onTap: () => setState(() => _selectedColor = color),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  border: Border.all(
                    color: isSelected ? const Color(0xFF667EEA) : Colors.grey,
                    width: isSelected ? 3 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        ElevatedButton(onPressed: () => Navigator.pop(context, _selectedColor), child: const Text('确定')),
      ],
    );
  }
}
