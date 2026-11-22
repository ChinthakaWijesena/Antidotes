import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:system_theme/system_theme.dart';
import '../constants/app_colors.dart';

class SystemThemeController extends ChangeNotifier with WidgetsBindingObserver {
  Color _accentColor = const Color(0xFF00D2C4);
  bool _isDarkMode = true;
  Timer? _pollingTimer;

  Color get accentColor => _accentColor;
  bool get isDarkMode => _isDarkMode;

  Future<void> initialize() async {
    WidgetsBinding.instance.addObserver(this);

    // Initial detection from Windows Registry & Platform
    await _updateThemeFromSystem();

    if (Platform.isWindows) {
      try {
        SystemTheme.fallbackColor = const Color(0xFF00D2C4);
        await SystemTheme.accentColor.load();
        if (SystemTheme.accentColor.accent != Colors.transparent) {
          _accentColor = SystemTheme.accentColor.accent;
        }

        // Listen for live Windows system theme & accent color changes
        SystemTheme.onChange.listen((color) {
          if (color.accent != Colors.transparent) {
            _accentColor = color.accent;
            AppColors.updateTheme(_isDarkMode, _accentColor);
            notifyListeners();
          }
        });
      } catch (_) {
        final regAccent = await _getAccentColorFromRegistry();
        if (regAccent != null) _accentColor = regAccent;
      }

      // Check registry periodically to detect Windows Settings Dark/Light switches live
      _pollingTimer?.cancel();
      _pollingTimer = Timer.periodic(
        const Duration(milliseconds: 800),
        (_) => _updateThemeFromSystem(),
      );
    }

    AppColors.updateTheme(_isDarkMode, _accentColor);
    notifyListeners();
  }

  void setDarkMode(bool isDark) {
    if (_isDarkMode != isDark) {
      _isDarkMode = isDark;
      AppColors.updateTheme(_isDarkMode, _accentColor);
      notifyListeners();
    }
  }

  @override
  void didChangePlatformBrightness() {
    _updateThemeFromSystem();
  }

  Future<void> _updateThemeFromSystem() async {
    bool changed = false;

    if (Platform.isWindows) {
      final regIsDark = await _getIsDarkFromRegistry();
      if (regIsDark != null) {
        if (regIsDark != _isDarkMode) {
          _isDarkMode = regIsDark;
          changed = true;
        }
      } else {
        final brightness =
            WidgetsBinding.instance.platformDispatcher.platformBrightness;
        final isDark = brightness == Brightness.dark;
        if (isDark != _isDarkMode) {
          _isDarkMode = isDark;
          changed = true;
        }
      }

      final regAccent = await _getAccentColorFromRegistry();
      if (regAccent != null && regAccent != _accentColor) {
        _accentColor = regAccent;
        changed = true;
      }
    } else {
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      final isDark = brightness == Brightness.dark;
      if (isDark != _isDarkMode) {
        _isDarkMode = isDark;
        changed = true;
      }
    }

    if (changed) {
      AppColors.updateTheme(_isDarkMode, _accentColor);
      notifyListeners();
    }
  }

  Future<bool?> _getIsDarkFromRegistry() async {
    try {
      final res = await Process.run('reg.exe', [
        'query',
        r'HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize',
        '/v',
        'AppsUseLightTheme',
      ]);
      if (res.exitCode == 0) {
        final out = res.stdout as String;
        final match = RegExp(r'0x([0-9a-fA-F]+)').firstMatch(out);
        if (match != null) {
          final val = int.parse(match.group(1)!, radix: 16);
          // 0 = Dark Mode, 1 = Light Mode
          return val == 0;
        }
      }
    } catch (_) {}
    return null;
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
    _pollingTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
