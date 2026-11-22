import 'dart:io';
import 'package:flutter/material.dart';
import 'package:system_theme/system_theme.dart';
import '../constants/app_colors.dart';

class SystemThemeController extends ChangeNotifier with WidgetsBindingObserver {
  Color _accentColor = const Color(0xFF00D2C4);
  bool _isDarkMode = true;

  Color get accentColor => _accentColor;
  bool get isDarkMode => _isDarkMode;

  Future<void> initialize() async {
    WidgetsBinding.instance.addObserver(this);
    _updateBrightness();

    if (Platform.isWindows) {
      try {
        SystemTheme.fallbackColor = const Color(0xFF00D2C4);
        await SystemTheme.accentColor.load();
        _accentColor = SystemTheme.accentColor.accent;

        // Listen for live Windows system theme & accent color changes
        SystemTheme.onChange.listen((color) {
          _accentColor = color.accent;
          AppColors.updateTheme(_isDarkMode, _accentColor);
          notifyListeners();
        });
      } catch (_) {
        // Fallback: Read directly from Windows Registry
        _accentColor = await _getAccentColorFromRegistry() ?? const Color(0xFF00D2C4);
      }
    }

    AppColors.updateTheme(_isDarkMode, _accentColor);
    notifyListeners();
  }

  @override
  void didChangePlatformBrightness() {
    _updateBrightness();
    AppColors.updateTheme(_isDarkMode, _accentColor);
    notifyListeners();
  }

  void _updateBrightness() {
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    _isDarkMode = brightness == Brightness.dark;
  }

  Future<Color?> _getAccentColorFromRegistry() async {
    try {
      final res = await Process.run('reg.exe', [
        'query',
        r'HKCU\Software\Microsoft\Windows\DWM',
        '/v',
        'AccentColor',
      ]);
      if (res.exitCode == 0) {
        final out = res.stdout as String;
        final match = RegExp(r'0x([0-9a-fA-F]+)').firstMatch(out);
        if (match != null) {
          final hexVal = int.parse(match.group(1)!, radix: 16);
          // Windows DWM AccentColor is stored in ABGR format: 0xAABBGGRR
          final a = (hexVal >> 24) & 0xFF;
          final b = (hexVal >> 16) & 0xFF;
          final g = (hexVal >> 8) & 0xFF;
          final r = hexVal & 0xFF;
          return Color.fromARGB(a == 0 ? 0xFF : a, r, g, b);
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
