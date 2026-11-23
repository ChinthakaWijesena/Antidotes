import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/large_file_item.dart';

class LargeFileService {
  /// Scan [rootPath] recursively for files >= [minSizeMb] MB.
  /// Emits [LargeFileScanProgress] via [onProgress].
  /// Returns items sorted largest first.
  Future<List<LargeFileItem>> scan({
    required String rootPath,
    required int minSizeMb,
    void Function(LargeFileScanProgress)? onProgress,
    bool Function()? isCancelled,
  }) async {
    final minBytes = minSizeMb * 1024 * 1024;
    final results  = <LargeFileItem>[];
    int scanned    = 0;

    try {
      final dir = Directory(rootPath);
      if (!dir.existsSync()) return [];

      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (isCancelled?.call() == true) break;

        if (entity is File) {
          try {
            final stat = entity.statSync();
            if (stat.size >= minBytes) {
              results.add(LargeFileItem.fromFile(entity, stat));
            }
            scanned++;
            if (scanned % 200 == 0) {
              onProgress?.call(LargeFileScanProgress(
                currentPath: entity.path,
                filesScanned: scanned,
              ));
              // Yield to UI thread
              await Future.delayed(Duration.zero);
            }
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('LargeFileService.scan error: $e');
    }

    results.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
    return results;
  }

  /// Opens Windows Explorer highlighting [filePath].
  Future<void> openFileLocation(String filePath) async {
    try {
      await Process.run('explorer.exe', ['/select,', filePath]);
    } catch (_) {}
  }

  /// Deletes a file and returns true on success.
  Future<bool> deleteFile(String filePath) async {
    try {
      await File(filePath).delete();
      return true;
    } catch (e) {
      debugPrint('LargeFileService.deleteFile error: $e');
      return false;
    }
  }

  /// Shows a Windows folder picker dialog, returns the selected path or null.
  Future<String?> pickFolder() async {
    try {
      final r = await Process.run('powershell.exe', [
        '-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command',
        r'''
Add-Type -AssemblyName System.Windows.Forms
$dlg = New-Object System.Windows.Forms.FolderBrowserDialog
$dlg.Description = "Select folder to scan for large files"
$dlg.ShowNewFolderButton = $false
if ($dlg.ShowDialog() -eq "OK") { Write-Output $dlg.SelectedPath }
''',
      ]);
      final out = r.stdout.toString().trim();
      return out.isNotEmpty ? out : null;
    } catch (_) {
      return null;
    }
  }
}
