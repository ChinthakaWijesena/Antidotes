import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:antidotes/features/auto_updater/data/models/update_info.dart';
import 'package:antidotes/features/auto_updater/data/services/auto_updater_service.dart';
import 'package:antidotes/features/auto_updater/presentation/controllers/auto_updater_controller.dart';
import 'package:antidotes/features/auto_updater/presentation/widgets/update_available_dialog.dart';
import 'package:antidotes/features/auto_updater/presentation/widgets/app_update_card.dart';

class FakeAutoUpdaterService extends AutoUpdaterService {
  final UpdateInfo? mockInfo;
  final bool shouldThrow;

  FakeAutoUpdaterService({this.mockInfo, this.shouldThrow = false})
      : super(currentAppVersion: '1.0.0');

  @override
  Future<UpdateInfo?> checkForUpdate({String? customUrl}) async {
    if (shouldThrow) {
      throw const SocketException('Connection failed');
    }
    return mockInfo;
  }

  @override
  Stream<double> downloadInstaller({
    required String downloadUrl,
    required File destinationFile,
  }) async* {
    yield 0.25;
    yield 0.75;
    yield 1.0;
  }

  @override
  Future<void> launchInstallerAndExit(File installerFile) async {
    // no-op in tests
  }
}

void main() {
  group('UpdateInfo Model Tests', () {
    test('compareVersions accurately compares semantic versions', () {
      expect(UpdateInfo.compareVersions('1.1.0', '1.0.0'), greaterThan(0));
      expect(UpdateInfo.compareVersions('1.0.1', '1.0.0'), greaterThan(0));
      expect(UpdateInfo.compareVersions('2.0.0', '1.9.9'), greaterThan(0));
      expect(UpdateInfo.compareVersions('1.0.0', '1.0.0'), equals(0));
      expect(UpdateInfo.compareVersions('0.9.9', '1.0.0'), lessThan(0));
      expect(UpdateInfo.compareVersions('1.0.0.1', '1.0.0'), greaterThan(0));
    });

    test('fromJson parses valid payload and detects hasUpdate correctly', () {
      final json = {
        'latest_version': '1.2.0',
        'release_date': '2026.11.25',
        'download_url': 'https://example.com/setup.exe',
        'mandatory': false,
        'changelog': ['Feature A', 'Bugfix B'],
      };

      final info = UpdateInfo.fromJson(json, currentVersion: '1.0.0');

      expect(info.latestVersion, equals('1.2.0'));
      expect(info.releaseDate, equals('2026.11.25'));
      expect(info.downloadUrl, equals('https://example.com/setup.exe'));
      expect(info.changelog.length, equals(2));
      expect(info.hasUpdate, isTrue);
    });

    test('hasUpdate is false when versions match', () {
      final json = {
        'latest_version': '1.0.0',
        'download_url': 'https://example.com/setup.exe',
        'changelog': [],
      };

      final info = UpdateInfo.fromJson(json, currentVersion: '1.0.0');
      expect(info.hasUpdate, isFalse);
    });
  });

  group('AutoUpdaterController Tests', () {
    test('checkForUpdates sets updateAvailable when update exists', () async {
      const info = UpdateInfo(
        currentVersion: '1.0.0',
        latestVersion: '1.1.0',
        releaseDate: '2026.11.25',
        downloadUrl: 'https://example.com/setup.exe',
        changelog: ['Changelog item 1'],
      );

      final ctrl = AutoUpdaterController(
        service: FakeAutoUpdaterService(mockInfo: info),
      );

      expect(ctrl.status, equals(UpdateStatus.idle));
      final hasUpdate = await ctrl.checkForUpdates();

      expect(hasUpdate, isTrue);
      expect(ctrl.status, equals(UpdateStatus.updateAvailable));
      expect(ctrl.updateInfo, isNotNull);
      expect(ctrl.hasUpdate, isTrue);
    });

    test('checkForUpdates sets upToDate when no update exists', () async {
      const info = UpdateInfo(
        currentVersion: '1.0.0',
        latestVersion: '1.0.0',
        releaseDate: '2026.11.25',
        downloadUrl: '',
        changelog: [],
      );

      final ctrl = AutoUpdaterController(
        service: FakeAutoUpdaterService(mockInfo: info),
      );

      final hasUpdate = await ctrl.checkForUpdates(silent: false);

      expect(hasUpdate, isFalse);
      expect(ctrl.status, equals(UpdateStatus.upToDate));
    });

    test('checkForUpdates handles network exception safely', () async {
      final ctrl = AutoUpdaterController(
        service: FakeAutoUpdaterService(shouldThrow: true),
      );

      final hasUpdate = await ctrl.checkForUpdates(silent: false);

      expect(hasUpdate, isFalse);
      expect(ctrl.status, equals(UpdateStatus.error));
    });
  });

  group('UpdateAvailableDialog Widget Tests', () {
    testWidgets('renders dialog with version and changelog', (tester) async {
      const info = UpdateInfo(
        currentVersion: '1.0.0',
        latestVersion: '1.1.0',
        releaseDate: '2026.11.25',
        downloadUrl: 'https://example.com/setup.exe',
        changelog: ['Updated game drivers', 'Added Windows 11 support'],
      );

      final ctrl = AutoUpdaterController(
        service: FakeAutoUpdaterService(mockInfo: info),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateAvailableDialog(
              updateInfo: info,
              controller: ctrl,
            ),
          ),
        ),
      );

      expect(find.text('Antidotes Updater'), findsOneWidget);
      expect(find.text('A new version is available!'), findsOneWidget);
      expect(find.textContaining('1.1.0 is now available'), findsOneWidget);
      expect(find.text("What's New"), findsOneWidget);
      expect(find.text('Updated game drivers'), findsOneWidget);
      expect(find.text('Added Windows 11 support'), findsOneWidget);
      expect(find.text('Decide later'), findsOneWidget);
      expect(find.text('Update Now'), findsOneWidget);
    });
  });

  group('AppUpdateCard Widget Tests', () {
    testWidgets('renders AppUpdateCard with version badge and button', (tester) async {
      final ctrl = AutoUpdaterController(
        service: FakeAutoUpdaterService(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppUpdateCard(controller: ctrl),
          ),
        ),
      );

      expect(find.text('Antidotes Updates'), findsOneWidget);
      expect(find.text('v1.0.5'), findsOneWidget);
      expect(find.text('Check for Updates'), findsOneWidget);
    });
  });
}
