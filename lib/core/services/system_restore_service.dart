import 'dart:io';
import 'package:flutter/foundation.dart';

enum SystemRestoreStatus {
  success,
  cancelled,
  disabled,
  failed,
  unsupported,
}

class SystemRestoreResult {
  final SystemRestoreStatus status;
  final String message;
  final String description;
  final DateTime timestamp;

  const SystemRestoreResult({
    required this.status,
    required this.message,
    required this.description,
    required this.timestamp,
  });

  bool get isSuccess => status == SystemRestoreStatus.success;
}

class SystemRestoreService {
  /// Checks if System Restore is supported on the current platform (Windows only)
  bool isSupported() {
    return Platform.isWindows;
  }

  /// Creates a Windows System Restore Point with the given [description].
  ///
  /// Strategy:
  /// 1. Try direct PowerShell (works if app is already elevated / admin).
  /// 2. If access denied, write a temporary .ps1 script and launch it
  ///    via  Start-Process -Verb RunAs  (UAC prompt appears for the user).
  ///    Result is communicated via a small temp text file.
  Future<SystemRestoreResult> createRestorePoint(String description) async {
    if (!Platform.isWindows) {
      return SystemRestoreResult(
        status: SystemRestoreStatus.unsupported,
        message: 'System Restore is only supported on Windows operating systems.',
        description: description,
        timestamp: DateTime.now(),
      );
    }

    // Sanitise – strip single-quotes so the description can't break PS strings
    final sanitizedDesc = description.replaceAll("'", ' ').replaceAll('"', ' ');

    // ── Step 1: direct execution (succeeds when app is running as admin) ──────
    final directResult = await _tryDirect(sanitizedDesc);
    if (directResult != null) return directResult;

    // ── Step 2: elevated execution via UAC ────────────────────────────────────
    return _tryElevated(sanitizedDesc, description);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Private helpers
  // ─────────────────────────────────────────────────────────────────────────────

  /// Attempt to call Checkpoint-Computer without elevation.
  /// Returns null when we should try elevation instead (access denied / privilege).
  Future<SystemRestoreResult?> _tryDirect(String sanitizedDesc) async {
    try {
      final result = await Process.run(
        'powershell.exe',
        [
          '-NoProfile',
          '-ExecutionPolicy',
          'Bypass',
          '-Command',
          _buildCheckpointCommand(sanitizedDesc, outputMode: 'stdout'),
        ],
        runInShell: false,
      );

      final out = result.stdout.toString().trim();
      final err = result.stderr.toString().trim();

      if (out.contains('SUCCESS')) {
        return SystemRestoreResult(
          status: SystemRestoreStatus.success,
          message: 'System Restore Point created successfully.',
          description: sanitizedDesc,
          timestamp: DateTime.now(),
        );
      }

      // If the error is NOT a privilege/access error, return failure immediately
      final combined = '$out $err'.toLowerCase();
      final isPrivilegeError = combined.contains('access is denied') ||
          combined.contains('access denied') ||
          combined.contains('privilege') ||
          combined.contains('administrator') ||
          combined.contains('elevation') ||
          combined.contains('0x80070005');

      if (!isPrivilegeError && (out.contains('ERROR:') || result.exitCode != 0)) {
        final errText = out.replaceFirst('ERROR:', '').trim();
        return SystemRestoreResult(
          status: SystemRestoreStatus.failed,
          message: errText.isNotEmpty ? errText : 'Failed to create restore point.',
          description: sanitizedDesc,
          timestamp: DateTime.now(),
        );
      }

      // Privilege error → fall through to Step 2
      return null;
    } catch (_) {
      return null; // fall through to Step 2
    }
  }

  /// Launch an elevated PowerShell process via UAC.
  /// We write a temporary .ps1 file to avoid all escaping problems.
  Future<SystemRestoreResult> _tryElevated(
      String sanitizedDesc, String originalDesc) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final tempDir = Directory.systemTemp.path;
    final scriptPath = '$tempDir\\antidotes_sr_$ts.ps1';
    final resultPath = '$tempDir\\antidotes_sr_${ts}_result.txt';

    // Write the PowerShell script to a temp file – no escaping needed
    final scriptContent = '''
\$ErrorActionPreference = "Stop"
try {
    Enable-ComputerRestore -Drive "C:\\" -ErrorAction SilentlyContinue
    # Remove the 24-hour throttle so we can create multiple points per day
    Set-ItemProperty -Path "HKLM:\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\SystemRestore" `
        -Name SystemRestorePointCreationFrequency -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Checkpoint-Computer -Description "$sanitizedDesc" -RestorePointType MODIFY_SETTINGS
    [IO.File]::WriteAllText("$resultPath", "SUCCESS")
} catch {
    [IO.File]::WriteAllText("$resultPath", "ERROR:" + \$_.Exception.Message)
}
''';

    try {
      await File(scriptPath).writeAsString(scriptContent);
    } catch (e) {
      return SystemRestoreResult(
        status: SystemRestoreStatus.failed,
        message: 'Could not write temporary script: $e',
        description: originalDesc,
        timestamp: DateTime.now(),
      );
    }

    try {
      // Launch the script with admin rights
      final elevateResult = await Process.run(
        'powershell.exe',
        [
          '-NoProfile',
          '-ExecutionPolicy',
          'Bypass',
          '-Command',
          'Start-Process powershell.exe -Verb RunAs -Wait -WindowStyle Hidden '
              '-ArgumentList \'-NoProfile -ExecutionPolicy Bypass -File "$scriptPath"\'',
        ],
        runInShell: false,
      );

      // Clean up script file
      try { await File(scriptPath).delete(); } catch (_) {}

      final resultFile = File(resultPath);
      if (await resultFile.exists()) {
        final content = (await resultFile.readAsString()).trim();
        try { await resultFile.delete(); } catch (_) {}

        if (content == 'SUCCESS') {
          return SystemRestoreResult(
            status: SystemRestoreStatus.success,
            message: 'System Restore Point created successfully.',
            description: originalDesc,
            timestamp: DateTime.now(),
          );
        }

        if (content.startsWith('ERROR:')) {
          final errMsg = content.replaceFirst('ERROR:', '').trim();
          return SystemRestoreResult(
            status: SystemRestoreStatus.failed,
            message: errMsg.isNotEmpty
                ? errMsg
                : 'Could not create restore point. Ensure System Protection is enabled on C:.',
            description: originalDesc,
            timestamp: DateTime.now(),
          );
        }
      }

      // No result file → user cancelled the UAC prompt
      if (elevateResult.exitCode != 0) {
        return SystemRestoreResult(
          status: SystemRestoreStatus.cancelled,
          message: 'Administrator permission was not granted (UAC cancelled).',
          description: originalDesc,
          timestamp: DateTime.now(),
        );
      }

      // UAC was accepted but result file missing (edge case)
      return SystemRestoreResult(
        status: SystemRestoreStatus.cancelled,
        message: 'Administrator permission was not granted (UAC cancelled).',
        description: originalDesc,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('SystemRestoreService elevated error: $e');
      try { await File(scriptPath).delete(); } catch (_) {}
      try { await File(resultPath).delete(); } catch (_) {}

      return SystemRestoreResult(
        status: SystemRestoreStatus.failed,
        message: 'Could not create System Restore Point. Make sure System Protection is enabled on drive C:.',
        description: originalDesc,
        timestamp: DateTime.now(),
      );
    }
  }

  /// Build the inline PowerShell command string for direct (non-elevated) mode.
  String _buildCheckpointCommand(String desc, {required String outputMode}) {
    return "\$ErrorActionPreference = 'Stop'; "
        "try { "
        "Enable-ComputerRestore -Drive 'C:\\' -ErrorAction SilentlyContinue; "
        "Set-ItemProperty -Path 'HKLM:\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\SystemRestore' "
        "-Name SystemRestorePointCreationFrequency -Value 0 -Type DWord -ErrorAction SilentlyContinue; "
        "Checkpoint-Computer -Description '$desc' -RestorePointType MODIFY_SETTINGS -ErrorAction Stop; "
        "Write-Output 'SUCCESS'; "
        "} catch { "
        "Write-Output ('ERROR:' + \$_.Exception.Message); "
        "}";
  }
}
