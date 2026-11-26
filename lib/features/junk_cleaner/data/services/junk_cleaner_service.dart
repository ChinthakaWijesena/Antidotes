import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

    final tempPathsMap = <String, String>{};
    for (final candidate in [
      env['TEMP'],
      env['TMP'],
      if (localAppData.isNotEmpty) p.join(localAppData, 'Temp'),
    ]) {
      if (candidate != null && candidate.isNotEmpty) {
        final key = p.canonicalize(candidate).toLowerCase();
        tempPathsMap.putIfAbsent(key, () => candidate);
      }
    }
    final tempPaths = tempPathsMap.values;

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
        description: 'Memory dumps (MEMORY.DMP, minidumps) and Windows Error Reporting archives',
        icon: Icons.bug_report_outlined,
        paths: [
          if (localAppData.isNotEmpty) ...[
            p.join(localAppData, 'CrashDumps'),
            p.join(localAppData, 'Microsoft', 'Windows', 'WER', 'ReportArchive'),
            p.join(localAppData, 'Microsoft', 'Windows', 'WER', 'ReportQueue'),
          ],
          p.join(programData, 'Microsoft', 'Windows', 'WER', 'ReportArchive'),
          p.join(winDir, 'Minidump'),
          p.join(winDir, 'LiveKernelReports'),
          p.join(winDir, 'MEMORY.DMP'),
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
        type: JunkCategoryType.prefetch,
        id: 'prefetch',
        title: 'Windows Prefetch Cache (C:\\Windows\\Prefetch)',
        description: 'Application launch prefetch cache files (*.pf) (Requires admin rights)',
        icon: Icons.flash_on_outlined,
        paths: [p.join(winDir, 'Prefetch')],
        isSelected: true,
      ),
      JunkCategory(
        type: JunkCategoryType.dnsCache,
        id: 'dns_cache',
        title: 'DNS Resolver Cache',
        description: 'Flushes Windows DNS client cache to resolve domain issues and clear lookups',
        icon: Icons.dns_outlined,
        paths: const [],
        isSelected: true,
      ),
      JunkCategory(
        type: JunkCategoryType.clipboard,
        id: 'clipboard',
        title: 'Windows Clipboard',
        description: 'Clears active desktop clipboard data (copied text, images, and file paths)',
        icon: Icons.content_paste_outlined,
        paths: const [],
        isSelected: true,
      ),
      JunkCategory(
        type: JunkCategoryType.muiCache,
        id: 'mui_cache',
        title: 'Windows MUICache',
        description: 'Multilingual User Interface cache entries for uninstalled and older apps',
        icon: Icons.history_outlined,
        paths: const [],
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
        title: 'Windows Event, Setup & CBS Logs',
        description: 'System event logs, Windows setup archives (Panther), and CBS logs',
        icon: Icons.description_outlined,
        paths: [
          p.join(winDir, 'Logs'),
          p.join(winDir, 'Panther'),
          p.join(winDir, 'Debug'),
          p.join(winDir, 'inf', 'setupapi.dev.log'),
        ],
        isCareful: true,
        isSelected: false,
      ),
    ];
  }

  /// Scans a single category in a background Isolate considering all safety rules and pattern risks.
  Future<void> scanCategory(
    JunkCategory category,
    CleanerSafetyOptions options, {
    void Function(String currentPath)? onProgress,
  }) async {
    category.reset();
    category.isScanning = true;

    // Handle Recycle Bin via Win32 API (offloaded to Isolate)
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

    // Handle DNS Cache
    if (category.type == JunkCategoryType.dnsCache) {
      var count = 0;
      try {
        final result = await Process.run('ipconfig', ['/displaydns']);
        if (result.exitCode == 0) {
          final stdout = result.stdout as String;
          count = RegExp(r'Record Name', caseSensitive: false).allMatches(stdout).length;
        }
      } catch (_) {}
      if (count > 0) {
        category.fileCount = count;
        category.totalBytes = count * 256;
        category.items.add(
          JunkItem(
            path: 'Windows DNS Cache',
            name: 'DNS Resolver Cache ($count active records)',
            sizeInBytes: category.totalBytes,
            categoryId: category.id,
            risk: PatternRisk.low,
          ),
        );
      }
      category.isScanning = false;
      return;
    }

    // Handle Clipboard
    if (category.type == JunkCategoryType.clipboard) {
      try {
        final hasStrings = await Clipboard.hasStrings();
        if (hasStrings) {
          final data = await Clipboard.getData(Clipboard.kTextPlain);
          final text = data?.text ?? '';
          final bytes = text.isNotEmpty ? text.length * 2 : 1024;
          category.fileCount = 1;
          category.totalBytes = bytes;
          category.items.add(
            JunkItem(
              path: 'Windows Clipboard',
              name: 'Clipboard Contents (${text.length} chars)',
              sizeInBytes: bytes,
              categoryId: category.id,
              risk: PatternRisk.low,
            ),
          );
        }
      } catch (_) {}
      category.isScanning = false;
      return;
    }

    // Handle MUICache
    if (category.type == JunkCategoryType.muiCache) {
      try {
        final result = await Process.run('reg', [
          'query',
          r'HKCU\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\MuiCache',
        ]);
        if (result.exitCode == 0) {
          final lines = (result.stdout as String).split('\n');
          var count = 0;
          var totalSize = 0;
          for (final line in lines) {
            final trimmed = line.trim();
            if (trimmed.contains('REG_SZ') || trimmed.contains('REG_BINARY')) {
              count++;
              totalSize += trimmed.length * 2;
            }
          }
          if (count > 0) {
            category.fileCount = count;
            category.totalBytes = totalSize;
            category.items.add(
              JunkItem(
                path: r'HKCU\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\MuiCache',
                name: 'MUICache Registry History ($count items)',
                sizeInBytes: totalSize,
                categoryId: category.id,
                risk: PatternRisk.low,
              ),
            );
          }
        }
      } catch (_) {}
      category.isScanning = false;
      return;
    }

    final receivePort = ReceivePort();
    final completer = Completer<void>();

    try {
      await Isolate.spawn(_scanCategoryIsolate, [
        receivePort.sendPort,
        category.paths,
        category.type,
        category.id,
        options,
        _patterns,
      ]);

      receivePort.listen((message) {
        if (message is Map<String, dynamic>) {
          final kind = message['type'] as String?;
          if (kind == 'progress') {
            onProgress?.call(message['path'] as String);
          } else if (kind == 'done') {
            final items = message['items'] as List<JunkItem>;
            final totalBytes = message['totalBytes'] as int;
            category.items = items;
            category.totalBytes = totalBytes;
            category.fileCount = items.length;
            receivePort.close();
            if (!completer.isCompleted) completer.complete();
          }
        }
      });

      await completer.future;
    } catch (_) {
      receivePort.close();
    } finally {
      category.isScanning = false;
    }
  }

  /// Cleans selected categories in a background Isolate with safe deletion, I/O pacing, and audit logging.
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

    // 1. Handle special non-file categories first (Recycle Bin, DNS, Clipboard, MUICache)
    for (final category in categories) {
      if (!category.isSelected) continue;

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
      } else if (category.type == JunkCategoryType.dnsCache) {
        onProgress?.call('Flushing Windows DNS Resolver Cache...', filesDeleted, bytesFreed);
        try {
          await Process.run('ipconfig', ['/flushdns']);
          await Process.run('powershell', ['-NoProfile', '-Command', 'Clear-DnsClientCache'], runInShell: true);
          bytesFreed += category.totalBytes;
          filesDeleted += category.fileCount;
          logEntries.add(
            DeletionLogEntry(
              timestamp: DateTime.now(),
              filePath: 'DNS Resolver Cache',
              sizeInBytes: category.totalBytes,
              status: DeletionStatus.deleted,
            ),
          );
          category.reset();
          category.isCleaned = true;
        } catch (_) {
          filesFailed += category.fileCount;
        }
      } else if (category.type == JunkCategoryType.clipboard) {
        onProgress?.call('Clearing Windows Desktop Clipboard...', filesDeleted, bytesFreed);
        try {
          await Clipboard.setData(const ClipboardData(text: ''));
          Win32ShellService.emptyClipboard();
          bytesFreed += category.totalBytes;
          filesDeleted += category.fileCount;
          logEntries.add(
            DeletionLogEntry(
              timestamp: DateTime.now(),
              filePath: 'Windows Clipboard',
              sizeInBytes: category.totalBytes,
              status: DeletionStatus.deleted,
            ),
          );
          category.reset();
          category.isCleaned = true;
        } catch (_) {
          filesFailed += category.fileCount;
        }
      } else if (category.type == JunkCategoryType.muiCache) {
        onProgress?.call('Purging MUICache registry entries...', filesDeleted, bytesFreed);
        try {
          final res = await Process.run('reg', [
            'delete',
            r'HKCU\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\MuiCache',
            '/va',
            '/f',
          ]);
          if (res.exitCode == 0) {
            bytesFreed += category.totalBytes;
            filesDeleted += category.fileCount;
            logEntries.add(
              DeletionLogEntry(
                timestamp: DateTime.now(),
                filePath: r'HKCU\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\MuiCache',
                sizeInBytes: category.totalBytes,
                status: DeletionStatus.deleted,
              ),
            );
            category.reset();
            category.isCleaned = true;
          } else {
            filesFailed += category.fileCount;
          }
        } catch (_) {
          filesFailed += category.fileCount;
        }
      }
    }

    // 2. Gather selected items for standard file categories
    final workList = <Map<String, dynamic>>[];
    for (final category in categories) {
      if (!category.isSelected || category.isSpecialCategory) continue;
      final selected = category.items.where((i) => i.isSelected).toList();
      if (selected.isEmpty) continue;
      workList.add({
        'categoryId': category.id,
        'items': selected,
      });
    }

    if (workList.isNotEmpty) {
      final receivePort = ReceivePort();
      final completer = Completer<void>();

      try {
        await Isolate.spawn(_cleanCategoriesIsolate, [
          receivePort.sendPort,
          workList,
          options.sendToRecycleBin,
        ]);

        receivePort.listen((message) {
          if (message is Map<String, dynamic>) {
            final kind = message['type'] as String?;
            if (kind == 'progress') {
              onProgress?.call(
                message['path'] as String,
                filesDeleted + (message['deleted'] as int),
                bytesFreed + (message['freed'] as int),
              );
            } else if (kind == 'done') {
              bytesFreed += message['bytesFreed'] as int;
              filesDeleted += message['filesDeleted'] as int;
              filesFailed += message['filesFailed'] as int;
              logEntries.addAll(message['logEntries'] as List<DeletionLogEntry>);
              final failedByCat =
                  message['failedByCategory'] as Map<String, Set<String>>;

              // Update category items on main Isolate
              for (final category in categories) {
                if (!category.isSelected || category.isSpecialCategory) continue;
                final failedPaths = failedByCat[category.id] ?? const <String>{};
                final remaining = category.items
                    .where((item) => !item.isSelected || failedPaths.contains(item.path))
                    .toList();
                category.items = remaining;
                category.fileCount = remaining.length;
                category.totalBytes =
                    remaining.fold(0, (sum, i) => sum + i.sizeInBytes);
                category.isCleaned = remaining.isEmpty;
              }

              receivePort.close();
              if (!completer.isCompleted) completer.complete();
            }
          }
        });

        await completer.future;
      } catch (_) {
        receivePort.close();
      }
    } else {
      // Mark empty selected file categories as cleaned
      for (final category in categories) {
        if (category.isSelected && !category.isSpecialCategory) {
          final remaining = category.items.where((i) => !i.isSelected).toList();
          category.items = remaining;
          category.fileCount = remaining.length;
          category.totalBytes = remaining.fold(0, (sum, i) => sum + i.sizeInBytes);
          category.isCleaned = remaining.isEmpty;
        }
      }
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
}

/// Top-level Isolate worker for scanning a category without blocking the UI or saturating disk I/O.
Future<void> _scanCategoryIsolate(List<dynamic> args) async {
  final sendPort = args[0] as SendPort;
  final paths = args[1] as List<String>;
  final type = args[2] as JunkCategoryType;
  final categoryId = args[3] as String;
  final options = args[4] as CleanerSafetyOptions;
  final patterns = args[5] as List<JunkPattern>;

  final items = <JunkItem>[];
  var totalBytes = 0;
  var processedCount = 0;

  final now = DateTime.now();
  final recent24hThreshold = now.subtract(const Duration(hours: 24));
  final progressThrottle = Stopwatch()..start();

  // Pre-compile exclude glob regexes once
  final excludedRegexes = options.excludePatterns.map((pattern) {
    final glob = pattern.replaceAll('*', '.*').replaceAll('?', '.');
    return RegExp('^$glob\$', caseSensitive: false);
  }).toList();
  final excludedFoldersLower =
      options.excludeFolders.map((f) => f.toLowerCase()).toList();

  for (final itemPath in paths) {
    // Check if itemPath is a single file (e.g. MEMORY.DMP or setupapi.dev.log)
    final file = File(itemPath);
    if (await file.exists()) {
      try {
        final stat = await file.stat();
        final fileName = p.basename(itemPath);
        items.add(
          JunkItem(
            path: itemPath,
            name: fileName,
            sizeInBytes: stat.size,
            categoryId: categoryId,
            risk: PatternRisk.low,
            lastModified: stat.modified,
            isSelected: true,
          ),
        );
        totalBytes += stat.size;
      } catch (_) {}
      continue;
    }

    final dir = Directory(itemPath);
    if (!await dir.exists()) continue;

    try {
      await for (final entity in dir
          .list(recursive: true, followLinks: false)
          .handleError((_) {})) {
        if (entity is! File) continue;

        final filePath = entity.path;
        final fileName = p.basename(filePath);
        final lowerPath = filePath.toLowerCase();
        final lowerName = fileName.toLowerCase();

        // Exclude folders check
        var excluded = false;
        for (final folder in excludedFoldersLower) {
          if (lowerPath.startsWith(folder)) {
            excluded = true;
            break;
          }
        }
        if (excluded) continue;

        // Exclude filename patterns check
        for (final rx in excludedRegexes) {
          if (rx.hasMatch(lowerName)) {
            excluded = true;
            break;
          }
        }
        if (excluded) continue;

        // Thumbnail cache special filter
        if (type == JunkCategoryType.thumbnailCache &&
            !lowerName.startsWith('thumbcache_') &&
            !lowerName.startsWith('iconcache_')) {
          continue;
        }

        // *.log is default OFF, unless this category is specifically windowsLogs
        if (type != JunkCategoryType.windowsLogs &&
            lowerName.endsWith('.log') &&
            !options.includeLogs) {
          continue;
        }

        // *.old and *.bak are default OFF
        if ((lowerName.endsWith('.old') || lowerName.endsWith('.bak')) &&
            !options.includeBackups) {
          continue;
        }

        try {
          if (progressThrottle.elapsedMilliseconds >= 100) {
            progressThrottle.reset();
            sendPort.send({'type': 'progress', 'path': filePath});
          }

          final stat = await entity.stat();

          if (type != JunkCategoryType.prefetch &&
              options.ignoreRecent24Hours &&
              stat.modified.isAfter(recent24hThreshold)) {
            continue;
          }

          var risk = PatternRisk.low;
          for (final pattern in patterns) {
            if (pattern.matches(fileName)) {
              risk = pattern.risk;
              break;
            }
          }

          items.add(
            JunkItem(
              path: filePath,
              name: fileName,
              sizeInBytes: stat.size,
              categoryId: categoryId,
              risk: risk,
              lastModified: stat.modified,
              isSelected: true,
            ),
          );
          totalBytes += stat.size;
        } catch (_) {
          // File inaccessible / locked
        }

        processedCount++;
        // Gentle I/O pacing so laptop CPU & disk remain responsive
        if (processedCount % 150 == 0) {
          await Future.delayed(const Duration(milliseconds: 2));
        }
      }
    } catch (_) {
      // Directory locked or permissions required
    }
  }

  sendPort.send({
    'type': 'done',
    'items': items,
    'totalBytes': totalBytes,
  });
}

/// Top-level Isolate worker for deleting junk files in the background with I/O pacing.
Future<void> _cleanCategoriesIsolate(List<dynamic> args) async {
  final sendPort = args[0] as SendPort;
  final workList = args[1] as List<Map<String, dynamic>>;
  final sendToRecycleBin = args[2] as bool;

  var bytesFreed = 0;
  var filesDeleted = 0;
  var filesFailed = 0;
  final logEntries = <DeletionLogEntry>[];
  final failedByCategory = <String, Set<String>>{};
  final progressThrottle = Stopwatch()..start();

  for (final work in workList) {
    final categoryId = work['categoryId'] as String;
    final items = work['items'] as List<JunkItem>;
    final failedPaths = <String>{};

    for (final item in items) {
      if (progressThrottle.elapsedMilliseconds >= 100) {
        progressThrottle.reset();
        sendPort.send({
          'type': 'progress',
          'path': item.path,
          'deleted': filesDeleted,
          'freed': bytesFreed,
        });
      }

      try {
        final file = File(item.path);
        if (await file.exists()) {
          if (sendToRecycleBin) {
            final ok = Win32ShellService.moveToRecycleBinSync(item.path);
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
        failedPaths.add(item.path);
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

      // Pace disk deletions every 100 files so Windows Explorer & Defender never saturate disk I/O
      if ((filesDeleted + filesFailed) % 100 == 0) {
        await Future.delayed(const Duration(milliseconds: 2));
      }
    }

    if (failedPaths.isNotEmpty) {
      failedByCategory[categoryId] = failedPaths;
    }
  }

  sendPort.send({
    'type': 'done',
    'bytesFreed': bytesFreed,
    'filesDeleted': filesDeleted,
    'filesFailed': filesFailed,
    'logEntries': logEntries,
    'failedByCategory': failedByCategory,
  });
}
