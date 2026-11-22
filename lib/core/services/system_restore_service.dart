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
  /// Tries direct PowerShell execution first. If Administrator privileges are needed,
  /// it elevates using Windows UAC (-Verb RunAs) so the user can easily approve it.
  Future<SystemRestoreResult> createRestorePoint(String description) async {
    if (!Platform.isWindows) {
      return SystemRestoreResult(
        status: SystemRestoreStatus.unsupported,
        message: 'System Restore is only supported on Windows operating systems.',
        description: description,
        timestamp: DateTime.now(),
      );
    }

    final sanitizedDesc = description.replaceAll("'", " ");

    // Step 1: Try direct execution (works if app is already running as Administrator)
    try {
      final directResult = await Process.run('powershell.exe', [
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-Command',
        "try { "
            "Enable-ComputerRestore -Drive 'C:\\' -ErrorAction SilentlyContinue; "
            "Checkpoint-Computer -Description '$sanitizedDesc' -RestorePointType 'MODIFY_SETTINGS' -ErrorAction Stop; "
            "Write-Output 'SUCCESS'; "
            "} catch { "
            "Write-Output ('ERROR:' + \$_.Exception.Message); "
            "}",
      ]);

      final stdout = directResult.stdout.toString().trim();
      if (stdout.contains('SUCCESS')) {
        return SystemRestoreResult(
          status: SystemRestoreStatus.success,
          message: 'System Restore Point created successfully.',
          description: description,
          timestamp: DateTime.now(),
        );
      }

      // If error is not a privilege error (e.g. system restore is disabled or frequency throttled)
      if (stdout.contains('ERROR:') &&
          !stdout.contains('privilege') &&
          !stdout.contains('Access is denied') &&
          !stdout.contains('administrator')) {
        final errText = stdout.replaceFirst('ERROR:', '').trim();
        return SystemRestoreResult(
          status: SystemRestoreStatus.failed,
          message: errText.isNotEmpty
              ? errText
              : 'Failed to create restore point.',
          description: description,
          timestamp: DateTime.now(),
        );
      }
    } catch (_) {}

    // Step 2: Elevate via Windows UAC (-Verb RunAs)
    final tempDir = Directory.systemTemp.path;
    final resultFile =
        '$tempDir\\antidotes_sr_${DateTime.now().millisecondsSinceEpoch}.txt';

    try {
      final script =
          "try { "
          "Enable-ComputerRestore -Drive 'C:\\' -ErrorAction SilentlyContinue; "
          "Checkpoint-Computer -Description '$sanitizedDesc' -RestorePointType 'MODIFY_SETTINGS' -ErrorAction Stop; "
          "[IO.File]::WriteAllText('$resultFile', 'SUCCESS'); "
          "} catch { "
          "[IO.File]::WriteAllText('$resultFile', 'ERROR:' + \$_.Exception.Message); "
          "}";

      final elevateRes = await Process.run('powershell.exe', [
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-Command',
        "Start-Process powershell.exe -Verb RunAs -Wait -WindowStyle Hidden -ArgumentList \"-NoProfile -ExecutionPolicy Bypass -Command `\"$script`\"\"",
      ]);

      final file = File(resultFile);
      if (await file.exists()) {
        final content = (await file.readAsString()).trim();
        try {
          await file.delete();
        } catch (_) {}

        if (content == 'SUCCESS') {
          return SystemRestoreResult(
            status: SystemRestoreStatus.success,
            message: 'System Restore Point created successfully.',
            description: description,
            timestamp: DateTime.now(),
          );
        } else if (content.startsWith('ERROR:')) {
          final err = content.replaceFirst('ERROR:', '').trim();
          return SystemRestoreResult(
            status: SystemRestoreStatus.failed,
            message: err,
            description: description,
            timestamp: DateTime.now(),
          );
        }
      }

      // If result file was not created, user likely declined UAC prompt
      if (elevateRes.exitCode != 0 || !await file.exists()) {
        return SystemRestoreResult(
          status: SystemRestoreStatus.cancelled,
          message:
              'Administrator permission (UAC) was cancelled or not granted.',
          description: description,
          timestamp: DateTime.now(),
        );
      }
    } catch (e) {
      debugPrint('Error creating restore point: $e');
    }

    return SystemRestoreResult(
      status: SystemRestoreStatus.failed,
      message:
          'Could not create System Restore Point. Make sure System Protection is enabled on drive C:.',
      description: description,
      timestamp: DateTime.now(),
    );
  }
}
