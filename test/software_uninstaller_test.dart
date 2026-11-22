import 'package:flutter_test/flutter_test.dart';
import 'package:antidotes/features/software_uninstaller/data/models/installed_app_item.dart';
import 'package:antidotes/features/software_uninstaller/data/models/leftover_item.dart';
import 'package:antidotes/features/software_uninstaller/data/models/uninstall_scan_mode.dart';
import 'package:antidotes/features/software_uninstaller/data/services/software_uninstaller_service.dart';
import 'package:antidotes/features/software_uninstaller/presentation/controllers/software_uninstaller_controller.dart';

class FakeSoftwareUninstallerService extends SoftwareUninstallerService {
  @override
  Future<List<InstalledAppItem>> getInstalledApps() async {
    return [
      const InstalledAppItem(
        id: 'vlc',
        name: 'VLC media player - 64-bit',
        publisher: 'VideoLAN',
        version: '3.0.24',
        installDate: '10/18/2026',
        sizeInBytes: 197342000, // 188.2 MB
        uninstallString: r'"C:\Program Files\VideoLAN\VLC\uninstall.exe"',
        installLocation: r'C:\Program Files\VideoLAN\VLC',
      ),
      const InstalledAppItem(
        id: 'vscode',
        name: 'Microsoft Visual Studio Code',
        publisher: 'Microsoft Corporation',
        version: '1.92.2',
        installDate: '11/04/2026',
        sizeInBytes: 373711872,
        uninstallString: r'"C:\Program Files\Microsoft VS Code\unins000.exe"',
      ),
      const InstalledAppItem(
        id: 'discord',
        name: 'Discord',
        publisher: 'Discord Inc.',
        version: '1.0.9168',
        installDate: '09/12/2026',
        sizeInBytes: 254803968,
        uninstallString: r'"C:\Users\User\AppData\Local\Discord\Update.exe" --uninstall',
      ),
    ];
  }
}

void main() {
  group('Software Uninstaller Models & Scan Mode Tests', () {
    test('UninstallScanMode provides correct labels and descriptions', () {
      expect(UninstallScanMode.safe.displayName, 'Safe');
      expect(UninstallScanMode.moderate.displayName, 'Moderate');
      expect(UninstallScanMode.advanced.displayName, 'Advanced');
      expect(UninstallScanMode.advanced.description, contains('Deep thorough scan'));
    });

    test('InstalledAppItem formats size and dates accurately', () {
      const app = InstalledAppItem(
        id: 'vlc',
        name: 'VLC media player - 64-bit',
        publisher: 'VideoLAN',
        version: '3.0.24',
        installDate: '20261018',
        sizeInBytes: 197342000,
        uninstallString: r'"C:\Program Files\VideoLAN\VLC\uninstall.exe"',
      );

      expect(app.formattedSize, '188.2 MB');
      expect(app.displayDate, '10/18/2026');
      expect(app.displayPublisher, 'VideoLAN');
      expect(app.displayVersion, '3.0.24');
    });

    test('LeftoverItem correctly identifies registry vs file types', () {
      final regItem = LeftoverItem(
        id: 'reg1',
        type: LeftoverType.registryValue,
        rootKey: 'HKEY_CURRENT_USER',
        path: r'HKEY_CURRENT_USER\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\MuiCache',
        name: r'C:\Program Files\VideoLAN\VLC\vlc.exe.FriendlyAppName - VLC media player',
      );

      final fileItem = LeftoverItem(
        id: 'file1',
        type: LeftoverType.folder,
        rootKey: 'File System',
        path: r'C:\ProgramData\VideoLAN',
        name: r'C:\ProgramData\VideoLAN',
      );

      expect(regItem.isRegistry, isTrue);
      expect(fileItem.isRegistry, isFalse);
      expect(regItem.isSelected, isTrue);
    });
  });

  group('SoftwareUninstallerService Tests', () {
    test('scanForLeftovers discovers MuiCache and registry leftover entries', () async {
      final service = SoftwareUninstallerService();
      const app = InstalledAppItem(
        id: 'vlc',
        name: 'VLC media player - 64-bit',
        publisher: 'VideoLAN',
        version: '3.0.24',
        sizeInBytes: 197342000,
        uninstallString: r'"C:\Program Files\VideoLAN\VLC\uninstall.exe"',
      );

      final leftovers = await service.scanForLeftovers(app, UninstallScanMode.advanced);

      expect(leftovers.isNotEmpty, isTrue);
      expect(leftovers.any((i) => i.name.contains('FriendlyAppName')), isTrue);
      expect(leftovers.any((i) => i.path.contains('MuiCache')), isTrue);
      expect(leftovers.any((i) => i.type == LeftoverType.folder), isTrue);
    });

    test('deleteLeftoverItems deletes selected items', () async {
      final service = SoftwareUninstallerService();
      final items = [
        LeftoverItem(
          id: 'item1',
          type: LeftoverType.registryValue,
          rootKey: 'HKEY_CURRENT_USER',
          path: r'HKEY_CURRENT_USER\Software\TestKey',
          name: 'TestValue',
          isSelected: true,
        ),
        LeftoverItem(
          id: 'item2',
          type: LeftoverType.folder,
          rootKey: 'File System',
          path: r'C:\NonExistent\TestFolder',
          name: r'C:\NonExistent\TestFolder',
          isSelected: false,
        ),
      ];

      final deleted = await service.deleteLeftoverItems(items);
      expect(deleted, 1);
      expect(items[0].isDeleted, isTrue);
      expect(items[1].isDeleted, isFalse);
    });
  });

  group('SoftwareUninstallerController Tests', () {
    test('loads apps and calculates totals accurately', () async {
      final controller = SoftwareUninstallerController(
        service: FakeSoftwareUninstallerService(),
      );

      await controller.loadApps();

      expect(controller.totalCount, 3);
      expect(controller.apps.first.name, 'VLC media player - 64-bit');
      expect(controller.totalSizeFormatted, isNotEmpty);
    });

    test('filters installed apps with search query', () async {
      final controller = SoftwareUninstallerController(
        service: FakeSoftwareUninstallerService(),
      );
      await controller.loadApps();

      controller.setSearchQuery('vlc');
      expect(controller.filteredApps.length, 1);
      expect(controller.filteredApps.first.name, 'VLC media player - 64-bit');

      controller.setSearchQuery('microsoft');
      expect(controller.filteredApps.length, 1);
      expect(controller.filteredApps.first.name, 'Microsoft Visual Studio Code');

      controller.setSearchQuery('nonexistent');
      expect(controller.filteredApps.isEmpty, isTrue);
    });

    test('sorts apps by size and name', () async {
      final controller = SoftwareUninstallerController(
        service: FakeSoftwareUninstallerService(),
      );
      await controller.loadApps();

      // Sort by size ascending
      controller.sortBy('size');
      expect(controller.filteredApps.first.id, 'vlc'); // 197 MB is smallest
      expect(controller.filteredApps.last.id, 'vscode'); // 373 MB is largest

      // Sort by size descending
      controller.sortBy('size');
      expect(controller.filteredApps.first.id, 'vscode');
      expect(controller.filteredApps.last.id, 'vlc');
    });

    test('removes app from list after uninstall', () async {
      final controller = SoftwareUninstallerController(
        service: FakeSoftwareUninstallerService(),
      );
      await controller.loadApps();

      expect(controller.totalCount, 3);
      controller.removeApp('vlc');
      expect(controller.totalCount, 2);
      expect(controller.apps.any((a) => a.id == 'vlc'), isFalse);
    });
  });
}
