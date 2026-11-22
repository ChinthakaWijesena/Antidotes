import 'package:flutter_test/flutter_test.dart';
import 'package:antidotes/features/startup_manager/data/models/startup_app_item.dart';
import 'package:antidotes/features/startup_manager/data/services/startup_manager_service.dart';

void main() {
  group('StartupManager Tests', () {
    test('creates StartupAppItem correctly', () {
      final item = StartupAppItem(
        id: 'test_app',
        name: 'TestApp',
        publisher: 'Test Publisher',
        command: 'C:\\Test\\app.exe',
        executablePath: 'C:\\Test\\app.exe',
        location: 'Registry (Current User)',
        locationType: 'UserRegistry',
        packageFamilyName: '',
        taskId: '',
        isEnabled: true,
        impact: StartupImpact.high,
      );

      expect(item.name, 'TestApp');
      expect(item.isEnabled, true);
      expect(item.impact, StartupImpact.high);
      expect(item.impactLabel, 'High');
    });

    test('parses fromJson accurately', () {
      final json = {
        'Id': 'uwp_test',
        'Name': 'PC Manager',
        'Publisher': 'Microsoft Corporation',
        'Command': 'Microsoft.MicrosoftPCManager_8wekyb3d8bbwe',
        'Location': 'Windows App Package',
        'LocationType': 'UWP',
        'Enabled': true,
        'PackageFamilyName': 'Microsoft.MicrosoftPCManager_8wekyb3d8bbwe',
        'TaskId': 'WindowsMasterUI_Store',
      };

      final item = StartupAppItem.fromJson(json);
      expect(item.name, 'PC Manager');
      expect(item.publisher, 'Microsoft Corporation');
      expect(item.isEnabled, true);
      expect(item.locationType, 'UWP');
    });

    test('StartupManagerService initializes and fetches apps', () async {
      final service = StartupManagerService();
      final data = await service.getStartupData();
      expect(data.apps, isNotNull);
      expect(data.biosTime, isNotEmpty);
    });
  });
}
