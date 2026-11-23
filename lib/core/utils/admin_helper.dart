import 'dart:io';

/// Helper utility for Windows Administrator privilege checking and process elevation.
class AdminHelper {
  AdminHelper._();

  static bool? _cachedIsAdmin;

  /// Returns whether the application is running with elevated Administrator privileges.
  static Future<bool> isRunningAsAdmin() async {
    if (_cachedIsAdmin != null) return _cachedIsAdmin!;
    if (!Platform.isWindows) {
      _cachedIsAdmin = false;
      return false;
    }

    try {
      final result = await Process.run(
        'powershell.exe',
        [
          '-NoProfile',
          '-NonInteractive',
          '-Command',
          '([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)'
        ],
        runInShell: false,
      );
      final out = result.stdout.toString().trim().toLowerCase();
      _cachedIsAdmin = (out == 'true');
      return _cachedIsAdmin!;
    } catch (_) {
      _cachedIsAdmin = false;
      return false;
    }
  }

  /// Restarts the current application with elevated Administrator privileges (UAC prompt).
  static Future<void> restartAsAdmin() async {
    if (!Platform.isWindows) return;
    try {
      final exePath = Platform.resolvedExecutable;
      await Process.start(
        'powershell.exe',
        [
          '-NoProfile',
          '-NonInteractive',
          '-Command',
          'Start-Process "$exePath" -Verb runAs',
        ],
        runInShell: false,
      );
      exit(0);
    } catch (_) {}
  }
}
