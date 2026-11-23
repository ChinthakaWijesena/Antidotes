import 'dart:io';

/// Service to manage Antidotes autostart with Windows.
/// Manages both HKCU and HKLM Run registry entries.
class AppStartupService {
  static const String hkcuPath =
      r'HKCU\Software\Microsoft\Windows\CurrentVersion\Run';
  static const String hklmPath =
      r'HKLM\Software\Microsoft\Windows\CurrentVersion\Run';
  static const String valueName = 'Antidotes';

  /// Returns whether Antidotes is currently registered to start with Windows.
  static Future<bool> isStartupEnabled() async {
    if (!Platform.isWindows) return false;
    try {
      final resCu = await Process.run('reg.exe', [
        'query',
        hkcuPath,
        '/v',
        valueName,
      ]);
      if (resCu.exitCode == 0) return true;

      final resLm = await Process.run('reg.exe', [
        'query',
        hklmPath,
        '/v',
        valueName,
      ]);
      return resLm.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// Enables or disables Antidotes on Windows startup.
  /// When enabled, Antidotes launches with `--minimized` so it starts silently
  /// in the System Tray Overflow Menu.
  static Future<bool> setStartupEnabled(bool enable) async {
    if (!Platform.isWindows) return false;
    try {
      if (enable) {
        final exePath = Platform.resolvedExecutable;
        final res = await Process.run('reg.exe', [
          'add',
          hkcuPath,
          '/v',
          valueName,
          '/t',
          'REG_SZ',
          '/d',
          '"$exePath" --minimized',
          '/f',
        ]);
        return res.exitCode == 0;
      } else {
        await Process.run('reg.exe', [
          'delete',
          hkcuPath,
          '/v',
          valueName,
          '/f',
        ]);
        await Process.run('reg.exe', [
          'delete',
          hklmPath,
          '/v',
          valueName,
          '/f',
        ]);
        return true;
      }
    } catch (_) {
      return false;
    }
  }
}
