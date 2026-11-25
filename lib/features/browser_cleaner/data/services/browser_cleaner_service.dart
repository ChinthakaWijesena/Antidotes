import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:path/path.dart' as p;
import '../models/browser_clean_item.dart';
import '../models/browser_profile_group.dart';
import '../models/browser_type.dart';

class BrowserCleanResult {
  final int totalFilesDeleted;
  final int totalBytesFreed;
  final int skippedLockedFiles;
  final List<String> cleanedBrowserNames;

  const BrowserCleanResult({
    required this.totalFilesDeleted,
    required this.totalBytesFreed,
    required this.skippedLockedFiles,
    required this.cleanedBrowserNames,
  });
}

class BrowserCleanerService {
  final String _localAppData;
  final String _appData;

  BrowserCleanerService({String? localAppData, String? appData})
      : _localAppData = localAppData ??
            Platform.environment['LOCALAPPDATA'] ??
            r'C:\Users\Default\AppData\Local',
        _appData = appData ??
            Platform.environment['APPDATA'] ??
            r'C:\Users\Default\AppData\Roaming';

  /// Generates the standard profile groups for all supported browsers
  List<BrowserProfileGroup> getDefaultBrowserGroups() {
    return [
      _buildChromeGroup(),
      _buildEdgeGroup(),
      _buildFirefoxGroup(),
      _buildOperaGroup(),
      _buildOperaGxGroup(),
      _buildBraveGroup(),
      _buildInternetExplorerGroup(),
    ];
  }

  /// Checks which browsers are installed by verifying their root folders
  Future<List<BrowserProfileGroup>> scanInstalledBrowsers() async {
    final groups = getDefaultBrowserGroups();
    final List<BrowserProfileGroup> scanned = [];

    // Check running processes once for fast lookups
    final runningProcesses = await _getRunningBrowserProcesses();

    for (final group in groups) {
      final isInstalled = await _isBrowserInstalled(group);
      final isRunning =
          runningProcesses.contains(group.type.processName.toLowerCase());

      final updatedItems = <BrowserCleanItem>[];

      for (final item in group.items) {
        if (!isInstalled) {
          updatedItems.add(item);
          continue;
        }

        final scanRes = await _scanItem(group, item);
        updatedItems.add(item.copyWith(
          sizeBytes: scanRes.size,
          fileCount: scanRes.count,
          detectedFiles: scanRes.files,
        ));
      }

      scanned.add(group.copyWith(
        isInstalled: isInstalled,
        isRunning: isRunning,
        items: updatedItems,
      ));
    }

    return scanned;
  }

  Future<Set<String>> _getRunningBrowserProcesses() async {
    final running = <String>{};
    if (!Platform.isWindows) return running;

    try {
      final res = await Process.run('tasklist', ['/FO', 'CSV', '/NH']);
      if (res.exitCode == 0) {
        final out = (res.stdout as String).toLowerCase();
        for (final type in BrowserType.values) {
          if (out.contains(type.processName.toLowerCase())) {
            running.add(type.processName.toLowerCase());
          }
        }
      }
    } catch (_) {}
    return running;
  }

  Future<bool> _isBrowserInstalled(BrowserProfileGroup group) async {
    if (group.profilePath.isEmpty) return false;
    final dir = Directory(group.profilePath);
    return dir.exists();
  }

  Future<({int size, int count, List<String> files})> _scanItem(
      BrowserProfileGroup group, BrowserCleanItem item) async {
    int totalSize = 0;
    int totalCount = 0;
    final detectedFiles = <String>[];

    // For Firefox, profiles are dynamic (e.g. Profiles/*.default-release)
    if (group.type == BrowserType.firefox) {
      final profiles = await _findFirefoxProfiles();
      for (final profileDir in profiles) {
        for (final rel in item.relativePaths) {
          final target = p.join(profileDir, rel);
          final res = await _calculatePathStats(target);
          totalSize += res.size;
          totalCount += res.count;
          detectedFiles.addAll(res.files);
        }
      }
      return (size: totalSize, count: totalCount, files: detectedFiles);
    }

    for (final rel in item.relativePaths) {
      final target = p.join(group.profilePath, rel);
      final res = await _calculatePathStats(target);
      totalSize += res.size;
      totalCount += res.count;
      detectedFiles.addAll(res.files);
    }

    return (size: totalSize, count: totalCount, files: detectedFiles);
  }

  Future<List<String>> _findFirefoxProfiles() async {
    final results = <String>[];
    final parent = Directory(p.join(_appData, r'Mozilla\Firefox\Profiles'));
    if (!await parent.exists()) return results;

    try {
      await for (final entity in parent.list(followLinks: false)) {
        if (entity is Directory) {
          results.add(entity.path);
        }
      }
    } catch (_) {}
    return results;
  }

  Future<({int size, int count, List<String> files})> _calculatePathStats(
      String fullPath) async {
    return Isolate.run(() async {
      int size = 0;
      int count = 0;
      final files = <String>[];

      final type = await FileSystemEntity.type(fullPath, followLinks: false);
      if (type == FileSystemEntityType.file) {
        try {
          final f = File(fullPath);
          final len = await f.length();
          size += len;
          count++;
          files.add(fullPath);
        } catch (_) {}
      } else if (type == FileSystemEntityType.directory) {
        final dir = Directory(fullPath);
        try {
          await for (final entity
              in dir.list(recursive: true, followLinks: false)) {
            if (entity is File) {
              try {
                final len = await entity.length();
                size += len;
                count++;
                files.add(entity.path);
              } catch (_) {}
              if (count % 200 == 0) {
                await Future.delayed(const Duration(milliseconds: 2));
              }
            }
          }
        } catch (_) {}
      }

      return (size: size, count: count, files: files);
    });
  }

  /// Cleans the selected items across all specified browser groups in a background Isolate.
  Future<BrowserCleanResult> cleanSelected(
    List<BrowserProfileGroup> groups, {
    void Function(String currentPath)? onProgress,
  }) async {
    final cleanedBrowsers = <String>{};
    final filesToDelete = <String>[];

    for (final group in groups) {
      for (final item in group.items) {
        if (!item.isSelected || item.detectedFiles.isEmpty) continue;
        cleanedBrowsers.add(group.name);
        filesToDelete.addAll(item.detectedFiles);
      }
    }

    if (filesToDelete.isEmpty) {
      return const BrowserCleanResult(
        totalFilesDeleted: 0,
        totalBytesFreed: 0,
        skippedLockedFiles: 0,
        cleanedBrowserNames: [],
      );
    }

    final receivePort = ReceivePort();
    final completer = Completer<({int deleted, int freed, int skipped})>();

    try {
      await Isolate.spawn(_cleanBrowserFilesIsolate, [
        receivePort.sendPort,
        filesToDelete,
      ]);

      receivePort.listen((message) {
        if (message is Map<String, dynamic>) {
          final kind = message['type'] as String?;
          if (kind == 'progress') {
            onProgress?.call(message['path'] as String);
          } else if (kind == 'done') {
            final res = (
              deleted: message['deleted'] as int,
              freed: message['freed'] as int,
              skipped: message['skipped'] as int,
            );
            receivePort.close();
            if (!completer.isCompleted) completer.complete(res);
          }
        }
      });

      final res = await completer.future;
      return BrowserCleanResult(
        totalFilesDeleted: res.deleted,
        totalBytesFreed: res.freed,
        skippedLockedFiles: res.skipped,
        cleanedBrowserNames: cleanedBrowsers.toList(),
      );
    } catch (_) {
      receivePort.close();
      return BrowserCleanResult(
        totalFilesDeleted: 0,
        totalBytesFreed: 0,
        skippedLockedFiles: filesToDelete.length,
        cleanedBrowserNames: cleanedBrowsers.toList(),
      );
    }
  }

  // --- Browser Profile Definitions ---

  BrowserProfileGroup _buildChromeGroup() {
    final root = p.join(_localAppData, r'Google\Chrome\User Data\Default');
    return BrowserProfileGroup(
      type: BrowserType.chrome,
      name: 'Google Chrome',
      isInstalled: false,
      isRunning: false,
      profilePath: root,
      items: [
        BrowserCleanItem(
          id: 'chrome_cache',
          browserType: BrowserType.chrome,
          category: BrowserCleanCategory.cache,
          title: 'Delete Temporary Internet Files (Cache)',
          description: 'Web images, scripts, stylesheets and code caches',
          relativePaths: ['Cache', 'Code Cache', 'GPUCache', r'Service Worker\CacheStorage'],
          isDefaultSelected: true,
          isSelected: true,
        ),
        BrowserCleanItem(
          id: 'chrome_history',
          browserType: BrowserType.chrome,
          category: BrowserCleanCategory.history,
          title: 'Clear History of Visited Internet Web Pages',
          description: 'URL history and visited page timestamps',
          relativePaths: ['History', 'History-journal'],
          warning: 'Will delete your browser history list',
        ),
        BrowserCleanItem(
          id: 'chrome_cookies',
          browserType: BrowserType.chrome,
          category: BrowserCleanCategory.cookies,
          title: 'Delete Cookies',
          description: 'Website cookies and persistent site data',
          relativePaths: [r'Network\Cookies', 'Cookies'],
          warning: 'Will sign you out of most active websites',
        ),
        BrowserCleanItem(
          id: 'chrome_downloads',
          browserType: BrowserType.chrome,
          category: BrowserCleanCategory.downloads,
          title: 'Delete Download History',
          description: 'List of completed and canceled browser downloads',
          relativePaths: ['Download Service'],
        ),
        BrowserCleanItem(
          id: 'chrome_forms',
          browserType: BrowserType.chrome,
          category: BrowserCleanCategory.forms,
          title: 'Delete Form History',
          description: 'Autofill form data, saved inputs, and search terms',
          relativePaths: ['Web Data', 'Web Data-journal'],
        ),
        BrowserCleanItem(
          id: 'chrome_sessions',
          browserType: BrowserType.chrome,
          category: BrowserCleanCategory.sessions,
          title: 'Delete Session History',
          description: 'Currently saved and previous open browser tabs',
          relativePaths: ['Sessions', 'Current Session', 'Current Tabs', 'Last Session', 'Last Tabs'],
          warning: 'Will close any saved tab restore states',
        ),
      ],
    );
  }

  BrowserProfileGroup _buildEdgeGroup() {
    final root = p.join(_localAppData, r'Microsoft\Edge\User Data\Default');
    return BrowserProfileGroup(
      type: BrowserType.edge,
      name: 'Microsoft Edge',
      isInstalled: false,
      isRunning: false,
      profilePath: root,
      items: [
        BrowserCleanItem(
          id: 'edge_cache',
          browserType: BrowserType.edge,
          category: BrowserCleanCategory.cache,
          title: 'Delete Temporary Internet Files (Cache)',
          description: 'Edge web cache, GPU cache and code caches',
          relativePaths: ['Cache', 'Code Cache', 'GPUCache', r'Service Worker\CacheStorage'],
          isDefaultSelected: true,
          isSelected: true,
        ),
        BrowserCleanItem(
          id: 'edge_history',
          browserType: BrowserType.edge,
          category: BrowserCleanCategory.history,
          title: 'Clear History of Visited Internet Web Pages',
          description: 'Browsing history and visited URLs',
          relativePaths: ['History', 'History-journal'],
          warning: 'Will delete your Edge browsing history',
        ),
        BrowserCleanItem(
          id: 'edge_cookies',
          browserType: BrowserType.edge,
          category: BrowserCleanCategory.cookies,
          title: 'Delete Cookies',
          description: 'Cookies and site data',
          relativePaths: [r'Network\Cookies', 'Cookies'],
          warning: 'Will sign you out of websites in Edge',
        ),
        BrowserCleanItem(
          id: 'edge_downloads',
          browserType: BrowserType.edge,
          category: BrowserCleanCategory.downloads,
          title: 'Delete Download History',
          description: 'Edge download activity records',
          relativePaths: ['Download Service'],
        ),
        BrowserCleanItem(
          id: 'edge_forms',
          browserType: BrowserType.edge,
          category: BrowserCleanCategory.forms,
          title: 'Delete Form History',
          description: 'Saved autofill and form inputs',
          relativePaths: ['Web Data', 'Web Data-journal'],
        ),
        BrowserCleanItem(
          id: 'edge_sessions',
          browserType: BrowserType.edge,
          category: BrowserCleanCategory.sessions,
          title: 'Delete Session History',
          description: 'Active and recently closed tabs',
          relativePaths: ['Sessions', 'Current Session', 'Current Tabs', 'Last Session', 'Last Tabs'],
          warning: 'Will discard open Edge tabs on next start',
        ),
      ],
    );
  }

  BrowserProfileGroup _buildFirefoxGroup() {
    final root = p.join(_appData, r'Mozilla\Firefox\Profiles');
    return BrowserProfileGroup(
      type: BrowserType.firefox,
      name: 'Mozilla Firefox',
      isInstalled: false,
      isRunning: false,
      profilePath: root,
      items: [
        BrowserCleanItem(
          id: 'firefox_cache',
          browserType: BrowserType.firefox,
          category: BrowserCleanCategory.cache,
          title: 'Delete Temporary Internet Files (Cache)',
          description: 'Firefox disk cache (cache2) and startup cache',
          relativePaths: [r'cache2\entries', r'cache2\doomed', 'startupCache'],
          isDefaultSelected: true,
          isSelected: true,
        ),
        BrowserCleanItem(
          id: 'firefox_history',
          browserType: BrowserType.firefox,
          category: BrowserCleanCategory.history,
          title: 'Clear History of Visited Internet Web Pages',
          description: 'Visited pages database and search records',
          relativePaths: ['places.sqlite-wal', 'places.sqlite-shm'],
          warning: 'Removes cached history records',
        ),
        BrowserCleanItem(
          id: 'firefox_cookies',
          browserType: BrowserType.firefox,
          category: BrowserCleanCategory.cookies,
          title: 'Delete Cookies',
          description: 'Firefox cookies database',
          relativePaths: ['cookies.sqlite', 'cookies.sqlite-wal'],
          warning: 'Will sign you out of active Firefox sessions',
        ),
        BrowserCleanItem(
          id: 'firefox_forms',
          browserType: BrowserType.firefox,
          category: BrowserCleanCategory.forms,
          title: 'Delete Form History',
          description: 'Autofill input database',
          relativePaths: ['formhistory.sqlite'],
        ),
        BrowserCleanItem(
          id: 'firefox_sessions',
          browserType: BrowserType.firefox,
          category: BrowserCleanCategory.sessions,
          title: 'Delete Session History',
          description: 'Firefox session restore backup files',
          relativePaths: ['sessionstore.jsonlz4', 'sessionstore-backups'],
          warning: 'Will remove previous open tab snapshots',
        ),
      ],
    );
  }

  BrowserProfileGroup _buildOperaGroup() {
    final root = p.join(_appData, r'Opera Software\Opera Stable');
    return BrowserProfileGroup(
      type: BrowserType.opera,
      name: 'Opera',
      isInstalled: false,
      isRunning: false,
      profilePath: root,
      items: [
        BrowserCleanItem(
          id: 'opera_cache',
          browserType: BrowserType.opera,
          category: BrowserCleanCategory.cache,
          title: 'Delete Temporary Internet Files (Cache)',
          description: 'Opera web cache, GPU cache and site scripts',
          relativePaths: ['Cache', 'GPUCache'],
          isDefaultSelected: true,
          isSelected: true,
        ),
        BrowserCleanItem(
          id: 'opera_history',
          browserType: BrowserType.opera,
          category: BrowserCleanCategory.history,
          title: 'Clear History of Visited Internet Web Pages',
          description: 'Opera URL and browsing history',
          relativePaths: ['History', 'History-journal'],
          warning: 'Will clear browsing logs',
        ),
        BrowserCleanItem(
          id: 'opera_cookies',
          browserType: BrowserType.opera,
          category: BrowserCleanCategory.cookies,
          title: 'Delete Cookies',
          description: 'Opera persistent cookies',
          relativePaths: [r'Network\Cookies'],
          warning: 'Will sign you out of website logins',
        ),
        BrowserCleanItem(
          id: 'opera_downloads',
          browserType: BrowserType.opera,
          category: BrowserCleanCategory.downloads,
          title: 'Delete Download History',
          description: 'Opera download list',
          relativePaths: ['Download Service'],
        ),
        BrowserCleanItem(
          id: 'opera_sessions',
          browserType: BrowserType.opera,
          category: BrowserCleanCategory.sessions,
          title: 'Delete Session History',
          description: 'Opera tab restore state',
          relativePaths: ['Sessions'],
        ),
      ],
    );
  }

  BrowserProfileGroup _buildOperaGxGroup() {
    final root = p.join(_appData, r'Opera Software\Opera GX Stable');
    return BrowserProfileGroup(
      type: BrowserType.operaGx,
      name: 'Opera GX',
      isInstalled: false,
      isRunning: false,
      profilePath: root,
      items: [
        BrowserCleanItem(
          id: 'operagx_cache',
          browserType: BrowserType.operaGx,
          category: BrowserCleanCategory.cache,
          title: 'Delete Temporary Internet Files (Cache)',
          description: 'Opera GX gaming browser cache and assets',
          relativePaths: ['Cache', 'GPUCache'],
          isDefaultSelected: true,
          isSelected: true,
        ),
        BrowserCleanItem(
          id: 'operagx_history',
          browserType: BrowserType.operaGx,
          category: BrowserCleanCategory.history,
          title: 'Clear History of Visited Internet Web Pages',
          description: 'Browsing records',
          relativePaths: ['History', 'History-journal'],
        ),
        BrowserCleanItem(
          id: 'operagx_cookies',
          browserType: BrowserType.operaGx,
          category: BrowserCleanCategory.cookies,
          title: 'Delete Cookies',
          description: 'Saved login cookies',
          relativePaths: [r'Network\Cookies'],
          warning: 'Will sign you out of accounts in Opera GX',
        ),
        BrowserCleanItem(
          id: 'operagx_sessions',
          browserType: BrowserType.operaGx,
          category: BrowserCleanCategory.sessions,
          title: 'Delete Session History',
          description: 'Restorable gaming tab sessions',
          relativePaths: ['Sessions'],
        ),
      ],
    );
  }

  BrowserProfileGroup _buildBraveGroup() {
    final root = p.join(_localAppData, r'BraveSoftware\Brave-Browser\User Data\Default');
    return BrowserProfileGroup(
      type: BrowserType.brave,
      name: 'Brave Browser',
      isInstalled: false,
      isRunning: false,
      profilePath: root,
      items: [
        BrowserCleanItem(
          id: 'brave_cache',
          browserType: BrowserType.brave,
          category: BrowserCleanCategory.cache,
          title: 'Delete Temporary Internet Files (Cache)',
          description: 'Shields and web assets cache',
          relativePaths: ['Cache', 'Code Cache', 'GPUCache'],
          isDefaultSelected: true,
          isSelected: true,
        ),
        BrowserCleanItem(
          id: 'brave_history',
          browserType: BrowserType.brave,
          category: BrowserCleanCategory.history,
          title: 'Clear History of Visited Internet Web Pages',
          description: 'Brave browsing history',
          relativePaths: ['History', 'History-journal'],
        ),
        BrowserCleanItem(
          id: 'brave_cookies',
          browserType: BrowserType.brave,
          category: BrowserCleanCategory.cookies,
          title: 'Delete Cookies',
          description: 'Cookies and site data',
          relativePaths: [r'Network\Cookies'],
          warning: 'Will sign you out of sites in Brave',
        ),
        BrowserCleanItem(
          id: 'brave_sessions',
          browserType: BrowserType.brave,
          category: BrowserCleanCategory.sessions,
          title: 'Delete Session History',
          description: 'Saved tabs and window sessions',
          relativePaths: ['Sessions'],
        ),
      ],
    );
  }

  BrowserProfileGroup _buildInternetExplorerGroup() {
    final root = p.join(_localAppData, r'Microsoft\Windows\INetCache');
    return BrowserProfileGroup(
      type: BrowserType.internetExplorer,
      name: 'Internet Explorer & Windows Web Cache',
      isInstalled: false,
      isRunning: false,
      profilePath: root,
      items: [
        BrowserCleanItem(
          id: 'ie_cache',
          browserType: BrowserType.internetExplorer,
          category: BrowserCleanCategory.cache,
          title: 'Delete Temporary Internet Files',
          description: 'Legacy web cache and Internet Explorer temporary files',
          relativePaths: ['IE', r'Low\IE'],
          isDefaultSelected: true,
          isSelected: true,
        ),
        BrowserCleanItem(
          id: 'ie_history',
          browserType: BrowserType.internetExplorer,
          category: BrowserCleanCategory.history,
          title: 'Clear History of Visited Internet Web Pages',
          description: 'History logs of legacy visited web pages',
          relativePaths: [p.join(_localAppData, r'Microsoft\Windows\History')],
        ),
        BrowserCleanItem(
          id: 'ie_cookies',
          browserType: BrowserType.internetExplorer,
          category: BrowserCleanCategory.cookies,
          title: 'Delete Cookies',
          description: 'Legacy cookies and wininet cookies',
          relativePaths: [p.join(_localAppData, r'Microsoft\Windows\INetCookies')],
        ),
      ],
    );
  }
}

/// Top-level Isolate worker for deleting browser cache/history files with I/O pacing.
Future<void> _cleanBrowserFilesIsolate(List<dynamic> args) async {
  final sendPort = args[0] as SendPort;
  final filesToDelete = args[1] as List<String>;

  var deleted = 0;
  var freed = 0;
  var skipped = 0;
  final progressThrottle = Stopwatch()..start();

  for (final filePath in filesToDelete) {
    if (progressThrottle.elapsedMilliseconds >= 100) {
      progressThrottle.reset();
      sendPort.send({'type': 'progress', 'path': filePath});
    }

    try {
      final f = File(filePath);
      if (await f.exists()) {
        final len = await f.length();
        await f.delete();
        freed += len;
        deleted++;
      }
    } catch (_) {
      skipped++;
    }

    if ((deleted + skipped) % 100 == 0) {
      await Future.delayed(const Duration(milliseconds: 2));
    }
  }

  sendPort.send({
    'type': 'done',
    'deleted': deleted,
    'freed': freed,
    'skipped': skipped,
  });
}
