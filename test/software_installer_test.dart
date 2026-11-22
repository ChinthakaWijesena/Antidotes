import 'package:flutter_test/flutter_test.dart';
import 'package:antidotes/features/software_installer/data/models/software_app_item.dart';
import 'package:antidotes/features/software_installer/data/models/software_category.dart';
import 'package:antidotes/features/software_installer/data/services/software_installer_service.dart';
import 'package:antidotes/features/software_installer/presentation/controllers/software_installer_controller.dart';

class FakeSoftwareInstallerService extends SoftwareInstallerService {
  @override
  Future<List<SoftwareAppItem>> scanInstalledStatus(
      List<SoftwareAppItem> catalog) async {
    // Return catalog without system winget inspection for fast, deterministic testing
    return catalog.map((a) => a.copyWith(isInstalled: false)).toList();
  }
}

void main() {
  group('Software Installer Models & Catalog Tests', () {
    test('SoftwareCategory provides proper display names', () {
      expect(SoftwareCategory.all.displayName, 'All Apps');
      expect(SoftwareCategory.browsers.displayName, 'Browsers');
      expect(SoftwareCategory.devTools.displayName, 'Developer Tools');
      expect(SoftwareCategory.utilities.displayName, 'Utilities');
      expect(SoftwareCategory.media.displayName, 'Media & Audio');
      expect(SoftwareCategory.social.displayName, 'Social & Chat');
      expect(SoftwareCategory.gaming.displayName, 'Gaming');
    });

    test('getCatalog contains all major requested popular software', () {
      final service = SoftwareInstallerService();
      final catalog = service.getCatalog();

      expect(catalog.length, greaterThanOrEqualTo(20));

      final names = catalog.map((a) => a.name).toList();
      expect(names, contains('Google Chrome'));
      expect(names, contains('Mozilla Firefox'));
      expect(names, contains('Brave Browser'));
      expect(names, contains('Visual Studio Code'));
      expect(names, contains('Git for Windows'));
      expect(names, contains('7-Zip'));
      expect(names, contains('VLC Media Player'));
      expect(names, contains('Discord'));
      expect(names, contains('Spotify'));
      expect(names, contains('Steam'));
    });

    test('SoftwareAppItem copyWith updates properties accurately', () {
      final service = SoftwareInstallerService();
      final chrome = service.getCatalog().firstWhere((a) => a.id == 'chrome');

      expect(chrome.isInstalled, isFalse);
      expect(chrome.status, InstallStatus.notInstalled);

      final installed = chrome.copyWith(
        isInstalled: true,
        status: InstallStatus.installed,
        statusMessage: 'Ready',
      );

      expect(installed.isInstalled, isTrue);
      expect(installed.status, InstallStatus.installed);
      expect(installed.statusMessage, 'Ready');
    });
  });

  group('SoftwareInstallerController Tests', () {
    test('filters apps by category accurately', () async {
      final controller = SoftwareInstallerController(service: FakeSoftwareInstallerService());
      await controller.loadCatalog();

      expect(controller.apps.isNotEmpty, isTrue);

      controller.selectCategory(SoftwareCategory.browsers);
      final browserApps = controller.filteredApps;
      expect(browserApps.every((a) => a.category == SoftwareCategory.browsers), isTrue);
      expect(browserApps.map((a) => a.name), contains('Google Chrome'));

      controller.selectCategory(SoftwareCategory.devTools);
      final devApps = controller.filteredApps;
      expect(devApps.every((a) => a.category == SoftwareCategory.devTools), isTrue);
      expect(devApps.map((a) => a.name), contains('Visual Studio Code'));
    });

    test('filters apps by search query', () async {
      final controller = SoftwareInstallerController(service: FakeSoftwareInstallerService());
      await controller.loadCatalog();

      controller.setSearchQuery('Google Chrome');
      expect(controller.filteredApps.length, 1);
      expect(controller.filteredApps.first.name, 'Google Chrome');

      controller.setSearchQuery('code');
      expect(controller.filteredApps.map((a) => a.name), contains('Visual Studio Code'));
    });

    test('toggles selection and select all uninstalled', () async {
      final controller = SoftwareInstallerController(service: FakeSoftwareInstallerService());
      await controller.loadCatalog();

      controller.selectAllUninstalled(false);
      expect(controller.selectedCount, 0);

      controller.toggleSelectApp('chrome');
      expect(controller.selectedCount, 1);

      controller.selectAllUninstalled(true);
      expect(controller.selectedCount, greaterThan(1));

      controller.selectAllUninstalled(false);
      expect(controller.selectedCount, 0);
    });
  });
}
