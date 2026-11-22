import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../../../../core/services/win32_shell_service.dart';
import '../models/cleaner_safety_options.dart';
import '../models/deletion_log_entry.dart';
import '../models/junk_category.dart';
import '../models/junk_item.dart';
import '../models/junk_pattern.dart';

class CleanupResult {
  final int bytesFreed;
  final int filesDeleted;
  final int filesFailed;
  final Duration duration;
  final List<DeletionLogEntry> logEntries;

  const CleanupResult({
    required this.bytesFreed,
    required this.filesDeleted,
    required this.filesFailed,
    required this.duration,
    this.logEntries = const [],
  });
}

class JunkCleanerService {
  final List<JunkPattern> _patterns = JunkPattern.getStandardPatterns();

  /// Builds all safe and careful categories for Windows
  List<JunkCategory> getCategories() {
    final env = Platform.environment;
    final localAppData = env['LOCALAPPDATA'] ?? '';
    final programData = env['ProgramData'] ?? 'C:\\ProgramData';
    final winDir = env['WINDIR'] ?? env['SYSTEMROOT'] ?? 'C:\\Windows';

    final tempPaths = <String>{};
    if (env['TEMP'] != null && env['TEMP']!.isNotEmpty) tempPaths.add(env['TEMP']!);
    if (env['TMP'] != null && env['TMP']!.isNotEmpty) tempPaths.add(env['TMP']!);
    if (localAppData.isNotEmpty) tempPaths.add(p.join(localAppData, 'Temp'));

    final firefoxProfiles = <String>[];
    if (localAppData.isNotEmpty) {
      final ffLocal = Directory(p.join(localAppData, 'Mozilla', 'Firefox', 'Profiles'));
      if (ffLocal.existsSync()) {
        try {
          for (final dir in ffLocal.listSync()) {
            if (dir is Directory) {
              firefoxProfiles.add(p.join(dir.path, 'cache2'));
            }
          }
        } catch (_) {}
      }
    }

    return [
      // 1. Safe & Common Categories (Default: Selected)
      JunkCategory(
        type: JunkCategoryType.userTemp,
        id: 'user_temp',
        title: 'User Temporary Files (%TEMP%)',
        description: 'Temporary files created by apps and user sessions',
        icon: Icons.folder_delete_outlined,
        paths: tempPaths.toList(),
        isSelected: true,
      ),
      JunkCategory(
        type: JunkCategoryType.systemTemp,
        id: 'system_temp',
        title: 'Windows System Temp (C:\\Windows\\Temp)',
        description: 'System-wide temporary cache (requires admin rights for full clean)',
        icon: Icons.laptop_windows_outlined,
        paths: [p.join(winDir, 'Temp')],
        isSelected: true,
      ),
      JunkCategory(
        type: JunkCategoryType.inetCache,
        id: 'inet_cache',
        title: 'Windows INetCache',
        description: 'Windows Internet Temporary Cache & Web leftovers',
        icon: Icons.cloud_download_outlined,
        paths: [
          if (localAppData.isNotEmpty)
            p.join(localAppData, 'Microsoft', 'Windows', 'INetCache'),
        ],
        isSelected: true,
      ),
      JunkCategory(
        type: JunkCategoryType.crashDumps,
        id: 'crash_dumps',
        title: 'Crash Dumps & Error Reports (WER)',
        description: 'Memory dumps (*.dmp) and Windows Error Reporting archives',
        icon: Icons.bug_report_outlined,
        paths: [
          if (localAppData.isNotEmpty) ...[
            p.join(localAppData, 'CrashDumps'),
            p.join(localAppData, 'Microsoft', 'Windows', 'WER', 'ReportArchive'),
            p.join(localAppData, 'Microsoft', 'Windows', 'WER', 'ReportQueue'),
          ],
          p.join(programData, 'Microsoft', 'Windows', 'WER', 'ReportArchive'),
          p.join(winDir, 'Minidump'),
        ],
        isSelected: true,
      ),
      JunkCategory(
        type: JunkCategoryType.thumbnailCache,
        id: 'thumbnail_cache',
        title: 'Windows Explorer Thumbnail Cache',
        description: 'Windows Explorer thumbcache_*.db and icon caches',
        icon: Icons.photo_library_outlined,
        paths: [
          if (localAppData.isNotEmpty)
            p.join(localAppData, 'Microsoft', 'Windows', 'Explorer'),
        ],
        isSelected: true,
      ),
      JunkCategory(
        type: JunkCategoryType.shaderCache,
        id: 'shader_cache',
        title: 'DirectX Shader Cache (D3DSCache)',
        description: 'Precompiled graphics shader cache files',
        icon: Icons.videogame_asset_outlined,
        paths: [
          if (localAppData.isNotEmpty) p.join(localAppData, 'D3DSCache'),
        ],
        isSelected: true,
      ),
      JunkCategory(
        type: JunkCategoryType.browserCache,
        id: 'browser_cache',
        title: 'Browser Web Caches (Edge, Chrome, Firefox)',
        description: 'Web image & script caches (safe cache only, no passwords/cookies)',
        icon: Icons.public_outlined,
        paths: [
          if (localAppData.isNotEmpty) ...[
            p.join(localAppData, 'Microsoft', 'Edge', 'User Data', 'Default', 'Cache', 'Cache_Data'),
            p.join(localAppData, 'Microsoft', 'Edge', 'User Data', 'Default', 'Code Cache'),
            p.join(localAppData, 'Microsoft', 'Edge', 'User Data', 'Default', 'GPUCache'),
            p.join(localAppData, 'Google', 'Chrome', 'User Data', 'Default', 'Cache', 'Cache_Data'),
            p.join(localAppData, 'Google', 'Chrome', 'User Data', 'Default', 'Code Cache'),
            p.join(localAppData, 'Google', 'Chrome', 'User Data', 'Default', 'GPUCache'),
          ],
          ...firefoxProfiles,
        ],
        isSelected: true,
      ),
      JunkCategory(
        type: JunkCategoryType.recycleBin,
        id: 'recycle_bin',
        title: 'Windows Recycle Bin',
        description: 'Deleted files in Recycle Bin (Emptied via native Win32 SHEmptyRecycleBin API)',
        icon: Icons.delete_forever_outlined,
        paths: const [],
        isRecycleBin: true,
        isSelected: true,
      ),

      // 2. Careful Categories (Default: Unchecked for extra safety)
      JunkCategory(
        type: JunkCategoryType.windowsUpdate,
        id: 'windows_update',
        title: 'Windows Update Cache (SoftwareDistribution)',
        description: 'Leftovers from completed Windows updates (Careful: wuauserv lock)',
        icon: Icons.system_update_outlined,
        paths: [p.join(winDir, 'SoftwareDistribution', 'Download')],
        isCareful: true,
        isSelected: false,
      ),
      JunkCategory(
        type: JunkCategoryType.windowsLogs,
        id: 'windows_logs',
        title: 'Windows Event & CBS Logs',
        description: 'System event logs and CBS setup archives (Optional / Careful)',
        icon: Icons.description_outlined,
        paths: [
          p.join(winDir, 'Logs'),
          p.join(winDir, 'Logs', 'CBS'),
        ],
        isCareful: true,
        isSelected: false,
      ),
    ];
  }

  /// Scans a single category considering all safety rules and pattern risks
  Future<void> scanCategory(
    JunkCategory category,
    CleanerSafetyOptions options, {
    void Function(String currentPath)? onProgress,
  }) async {
    category.reset();
    category.isScanning = true;

    // Handle Recycle Bin via Win32 API
    if (category.isRecycleBin) {
      final rbInfo = await Win32ShellService.queryRecycleBin();
      if (rbInfo != null && rbInfo.totalItems > 0) {
        category.totalBytes = rbInfo.totalBytes;
        category.fileCount = rbInfo.totalItems;
        category.items.add(
          JunkItem(
            path: 'Windows Recycle Bin',
            name: 'Recycle Bin Contents (${rbInfo.totalItems} items)',
            sizeInBytes: rbInfo.totalBytes,
            categoryId: category.id,
            risk: PatternRisk.low,
          ),
        );
      }
      category.isScanning = false;
      return;
    }

    final now = DateTime.now();
    final recent24hThreshold = now.subtract(const Duration(hours: 24));

    for (final dirPath in category.paths) {
      final dir = Directory(dirPath);
      if (!dir.existsSync()) continue;

      try {
        await for (final entity in dir
            .list(recursive: true, followLinks: false)
            .handleError((_) {})) {
          // Rule: NEVER follow symlinks or junction points!
          if (entity is Link ||
              FileSystemEntity.isLinkSync(entity.path) ||
              entity is! File) {
            continue;
          }

          final filePath = entity.path;
          final fileName = p.basename(filePath);

          // Rule: Exclude folders check
          if (_isPathExcluded(filePath, options.excludeFolders)) {
            continue;
          }

          // Rule: Exclude filename patterns check
          if (_isFilenameExcluded(fileName, options.excludePatterns)) {
            continue;
          }

          // Rule: Thumbnail cache directory special filter
          if (category.type == JunkCategoryType.thumbnailCache) {
            final lower = fileName.toLowerCase();
            if (!lower.startsWith('thumbcache_') && !lower.startsWith('iconcache_')) {
              continue;
            }
          }

          try {
            onProgress?.call(filePath);
            final stat = await entity.stat();

            // Rule: Ignore files created/modified within last 24 hours
            if (options.ignoreRecent24Hours &&
                stat.modified.isAfter(recent24hThreshold)) {
              continue;
            }

            // Pattern & Risk verification
            final risk = _evaluateRisk(fileName);

            // Rule: *.log is default OFF
            if (fileName.toLowerCase().endsWith('.log') && !options.includeLogs) {
              continue;
            }

            // Rule: *.old and *.bak are default OFF
            if ((fileName.toLowerCase().endsWith('.old') ||
                    fileName.toLowerCase().endsWith('.bak')) &&
                !options.includeBackups) {
              continue;
            }

            final item = JunkItem(
              path: filePath,
              name: fileName,
              sizeInBytes: stat.size,
              categoryId: category.id,
              risk: risk,
              lastModified: stat.modified,
              isSelected: true,
            );

            category.items.add(item);
            category.totalBytes += stat.size;
            category.fileCount += 1;
          } catch (_) {
            // File inaccessible / locked
          }
        }
      } catch (_) {
        // Directory locked or permissions required
      }
    }

    category.isScanning = false;
  }

  /// Cleans selected categories with safe deletion and audit logging
  Future<CleanupResult> cleanCategories(
    List<JunkCategory> categories,
    CleanerSafetyOptions options, {
    void Function(String currentFile, int filesDeleted, int bytesFreed)? onProgress,
  }) async {
    final stopwatch = Stopwatch()..start();
    var bytesFreed = 0;
    var filesDeleted = 0;
    var filesFailed = 0;
    final logEntries = <DeletionLogEntry>[];

    for (final category in categories) {
      if (!category.isSelected) continue;

      // Handle Recycle Bin
      if (category.isRecycleBin) {
        onProgress?.call('Emptying Windows Recycle Bin...', filesDeleted, bytesFreed);
        final success = await Win32ShellService.emptyRecycleBin();
        if (success) {
          bytesFreed += category.totalBytes;
          filesDeleted += category.fileCount;
          logEntries.add(
            DeletionLogEntry(
              timestamp: DateTime.now(),
              filePath: 'Recycle Bin',
              sizeInBytes: category.totalBytes,
              status: DeletionStatus.deleted,
            ),
          );
          category.reset();
          category.isCleaned = true;
        } else {
          filesFailed += category.fileCount;
        }
        continue;
      }

      final remainingItems = <JunkItem>[];

      for (final item in category.items) {
        if (!item.isSelected) {
          remainingItems.add(item);
          continue;
        }

        onProgress?.call(item.path, filesDeleted, bytesFreed);

        try {
          final file = File(item.path);
          if (await file.exists()) {
            if (options.sendToRecycleBin) {
              // Move to Windows Recycle Bin via SHFileOperation
              final ok = await Win32ShellService.moveToRecycleBin(item.path);
              if (ok) {
                bytesFreed += item.sizeInBytes;
                filesDeleted += 1;
                logEntries.add(
                  DeletionLogEntry(
                    timestamp: DateTime.now(),
                    filePath: item.path,
                    sizeInBytes: item.sizeInBytes,
                    status: DeletionStatus.recycled,
                  ),
                );
              } else {
                // Fallback to permanent delete if moving to recycle bin fails
                await file.delete();
                bytesFreed += item.sizeInBytes;
                filesDeleted += 1;
                logEntries.add(
                  DeletionLogEntry(
                    timestamp: DateTime.now(),
                    filePath: item.path,
                    sizeInBytes: item.sizeInBytes,
                    status: DeletionStatus.deleted,
                  ),
                );
              }
            } else {
              // Permanent delete
              await file.delete();
              bytesFreed += item.sizeInBytes;
              filesDeleted += 1;
              logEntries.add(
                DeletionLogEntry(
                  timestamp: DateTime.now(),
                  filePath: item.path,
                  sizeInBytes: item.sizeInBytes,
                  status: DeletionStatus.deleted,
                ),
              );
            }
          }
        } catch (e) {
          filesFailed += 1;
          remainingItems.add(item);
          logEntries.add(
            DeletionLogEntry(
              timestamp: DateTime.now(),
              filePath: item.path,
              sizeInBytes: item.sizeInBytes,
              status: DeletionStatus.skippedLocked,
              errorMessage: e.toString(),
            ),
          );
        }
      }

      category.items = remainingItems;
      category.fileCount = remainingItems.length;
      category.totalBytes = remainingItems.fold(0, (sum, i) => sum + i.sizeInBytes);
      category.isCleaned = remainingItems.isEmpty;
    }

    stopwatch.stop();
    return CleanupResult(
      bytesFreed: bytesFreed,
      filesDeleted: filesDeleted,
      filesFailed: filesFailed,
      duration: stopwatch.elapsed,
      logEntries: logEntries,
    );
  }

  PatternRisk _evaluateRisk(String filename) {
    for (final pattern in _patterns) {
      if (pattern.matches(filename)) {
        return pattern.risk;
      }
    }
    return PatternRisk.low;
  }

  bool _isPathExcluded(String filePath, List<String> excludedFolders) {
    final lowerPath = filePath.toLowerCase();
    for (final folder in excludedFolders) {
      if (lowerPath.startsWith(folder.toLowerCase())) {
        return true;
      }
    }
    return false;
  }

  bool _isFilenameExcluded(String filename, List<String> excludedPatterns) {
    final lowerName = filename.toLowerCase();
    for (final pattern in excludedPatterns) {
      final glob = pattern.replaceAll('*', '.*').replaceAll('?', '.');
      if (RegExp('^$glob\$', caseSensitive: false).hasMatch(lowerName)) {
        return true;
      }
    }
    return false;
  }
}
