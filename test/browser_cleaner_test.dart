import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:antidotes/features/browser_cleaner/data/models/browser_type.dart';
import 'package:antidotes/features/browser_cleaner/data/models/browser_clean_item.dart';
import 'package:antidotes/features/browser_cleaner/data/services/browser_cleaner_service.dart';
import 'package:antidotes/features/browser_cleaner/presentation/controllers/browser_cleaner_controller.dart';

void main() {
  group('Browser Cleaner Models & Definitions', () {
    test('BrowserType returns correct display names and processes', () {
      expect(BrowserType.chrome.displayName, 'Google Chrome');
      expect(BrowserType.chrome.processName, 'chrome.exe');

      expect(BrowserType.edge.displayName, 'Microsoft Edge');
      expect(BrowserType.edge.processName, 'msedge.exe');

      expect(BrowserType.firefox.displayName, 'Mozilla Firefox');
      expect(BrowserType.firefox.processName, 'firefox.exe');

      expect(BrowserType.opera.displayName, 'Opera');
      expect(BrowserType.opera.processName, 'opera.exe');

      expect(BrowserType.brave.displayName, 'Brave Browser');
      expect(BrowserType.brave.processName, 'brave.exe');
    });

    test('BrowserCleanerService initializes all major browser groups', () {
      final service = BrowserCleanerService(
        localAppData: r'C:\Mock\LocalAppData',
        appData: r'C:\Mock\AppData',
      );

      final groups = service.getDefaultBrowserGroups();
      expect(groups.length, 7);

      final names = groups.map((g) => g.name).toList();
      expect(names, contains('Google Chrome'));
      expect(names, contains('Microsoft Edge'));
      expect(names, contains('Mozilla Firefox'));
      expect(names, contains('Opera'));
      expect(names, contains('Opera GX'));
      expect(names, contains('Brave Browser'));
      expect(names, contains('Internet Explorer & Windows Web Cache'));
    });

    test('Temporary internet files (cache) are default selected, cookies/history are not', () {
      final service = BrowserCleanerService();
      final groups = service.getDefaultBrowserGroups();

      for (final group in groups) {
        final cacheItem = group.items.firstWhere(
            (i) => i.category == BrowserCleanCategory.cache);
        expect(cacheItem.isSelected, isTrue,
            reason: '${group.name} cache should be selected by default');

        final historyItem = group.items.where(
            (i) => i.category == BrowserCleanCategory.history);
        if (historyItem.isNotEmpty) {
          expect(historyItem.first.isDefaultSelected, isFalse,
              reason: '${group.name} history should not be selected by default');
        }

        final cookiesItem = group.items.where(
            (i) => i.category == BrowserCleanCategory.cookies);
        if (cookiesItem.isNotEmpty) {
          expect(cookiesItem.first.isDefaultSelected, isFalse,
              reason: '${group.name} cookies should not be selected by default');
        }
      }
    });
  });

  group('BrowserCleanerController Tests', () {
    late BrowserCleanerService service;
    late BrowserCleanerController controller;
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('antidotes_browser_test_');
      final mockLocal = Directory('${tempDir.path}\\Local')..createSync(recursive: true);
      final mockRoaming = Directory('${tempDir.path}\\Roaming')..createSync(recursive: true);

      // Create simulated Chrome cache folder with test files
      final chromeCache = Directory('${mockLocal.path}\\Google\\Chrome\\User Data\\Default\\Cache')
        ..createSync(recursive: true);
      File('${chromeCache.path}\\cache_data_1.tmp')
          .writeAsBytesSync(List.filled(1024, 0x41));
      File('${chromeCache.path}\\cache_data_2.tmp')
          .writeAsBytesSync(List.filled(2048, 0x42));

      service = BrowserCleanerService(
        localAppData: mockLocal.path,
        appData: mockRoaming.path,
      );
      controller = BrowserCleanerController(service: service);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('scans simulated installed browser and detects files', () async {
      await controller.scan();

      final chrome = controller.browserGroups
          .firstWhere((g) => g.type == BrowserType.chrome);
      expect(chrome.isInstalled, isTrue);

      final cacheItem = chrome.items
          .firstWhere((i) => i.category == BrowserCleanCategory.cache);
      expect(cacheItem.fileCount, 2);
      expect(cacheItem.sizeBytes, 3072); // 1024 + 2048
      expect(controller.totalJunkBytes, 3072);
    });

    test('toggles items and groups correctly', () async {
      await controller.scan();

      expect(controller.selectedJunkBytes, 3072);

      // Toggle chrome cache off
      controller.toggleItem('chrome_cache');
      expect(controller.selectedJunkBytes, 0);

      // Toggle group back on
      controller.toggleGroup(BrowserType.chrome, true);
      expect(controller.selectedJunkBytes, 3072);

      // Deselect all
      controller.selectAll(false);
      expect(controller.selectedJunkBytes, 0);

      // Select all
      controller.selectAll(true);
      expect(controller.selectedJunkBytes, 3072);
    });

    test('cleans selected browser files safely', () async {
      await controller.scan();
      expect(controller.selectedJunkBytes, 3072);

      final result = await controller.startClean();
      expect(result, isNotNull);
      expect(result!.totalFilesDeleted, 2);
      expect(result.totalBytesFreed, 3072);
      expect(result.skippedLockedFiles, 0);
      expect(result.cleanedBrowserNames, contains('Google Chrome'));

      // After clean and rescan, junk should be 0
      expect(controller.totalJunkBytes, 0);
    });
  });
}
