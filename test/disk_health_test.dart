import 'package:flutter_test/flutter_test.dart';
import 'package:antidotes/features/disk_health/data/models/disk_health_model.dart';
import 'package:antidotes/features/disk_health/presentation/controllers/disk_health_controller.dart';

void main() {
  group('DiskHealth Models & Parsing Tests', () {
    test('DiskHealthStatus parses correctly from string', () {
      expect(DiskHealthStatus.fromString('Healthy'), DiskHealthStatus.healthy);
      expect(DiskHealthStatus.fromString('healthy'), DiskHealthStatus.healthy);
      expect(DiskHealthStatus.fromString('Warning'), DiskHealthStatus.warning);
      expect(DiskHealthStatus.fromString('Unhealthy'), DiskHealthStatus.unhealthy);
      expect(DiskHealthStatus.fromString('Unknown'), DiskHealthStatus.unknown);
      expect(DiskHealthStatus.fromString(null), DiskHealthStatus.unknown);
      expect(DiskHealthStatus.fromString('other'), DiskHealthStatus.unknown);

      expect(DiskHealthStatus.healthy.label, 'Healthy');
      expect(DiskHealthStatus.warning.label, 'Warning');
      expect(DiskHealthStatus.unhealthy.label, 'Unhealthy');
      expect(DiskHealthStatus.unknown.label, 'Unknown');
    });

    test('DiskMediaType parses various types correctly', () {
      expect(DiskMediaType.fromString('SSD'), DiskMediaType.ssd);
      expect(DiskMediaType.fromString('NVMe SSD'), DiskMediaType.ssd);
      expect(DiskMediaType.fromString('HDD'), DiskMediaType.hdd);
      expect(DiskMediaType.fromString('3'), DiskMediaType.hdd);
      expect(DiskMediaType.fromString('4'), DiskMediaType.ssd);
      expect(DiskMediaType.fromString('Unspecified'), DiskMediaType.unspecified);

      expect(DiskMediaType.ssd.label, 'SSD');
      expect(DiskMediaType.hdd.label, 'HDD');
      expect(DiskMediaType.nvme.label, 'NVMe SSD');
    });

    test('SmartAttribute parses and detects failing state accurately', () {
      final normal = SmartAttribute.fromJson({
        'Id': 5,
        'Name': 'Reallocated Sectors',
        'Value': 100,
        'Worst': 100,
        'Threshold': 36,
        'RawValue': 0,
      });

      expect(normal.id, 5);
      expect(normal.name, 'Reallocated Sectors');
      expect(normal.value, 100);
      expect(normal.isFailing, isFalse);

      final failing = SmartAttribute.fromJson({
        'Id': 5,
        'Name': 'Reallocated Sectors',
        'Value': 20,
        'Worst': 20,
        'Threshold': 36,
        'RawValue': 500,
      });

      expect(failing.isFailing, isTrue);
    });

    test('DiskDrive parses JSON with SMART attributes and calculates metrics', () {
      final json = {
        'Name': 'Samsung SSD 980 1TB',
        'Model': 'Samsung SSD 980',
        'MediaType': 'SSD',
        'HealthStatus': 'Healthy',
        'OperationalStatus': 'OK',
        'SizeBytes': 1000204886016, // ~1TB
        'UsedBytes': 400081954406,  // ~400GB
        'PredictFailure': false,
        'Temperature': 38,
        'PowerOnHours': 2400,
        'SmartAttributes': [
          {
            'Id': 231,
            'Name': 'SSD Life Left',
            'Value': 98,
            'Worst': 98,
            'Threshold': 0,
            'RawValue': 98,
          },
          {
            'Id': 194,
            'Name': 'Temperature',
            'Value': 62,
            'Worst': 62,
            'Threshold': 0,
            'RawValue': 38,
          },
        ],
      };

      final drive = DiskDrive.fromJson(json);

      expect(drive.name, 'Samsung SSD 980 1TB');
      expect(drive.mediaType, DiskMediaType.ssd);
      expect(drive.healthStatus, DiskHealthStatus.healthy);
      expect(drive.temperature, 38);
      expect(drive.temperatureLabel, '38°C');
      expect(drive.temperatureState, 'cool');
      expect(drive.lifeRemaining, 98);
      expect(drive.lifeLabel, '98%');
      expect(drive.powerOnHours, 2400);
      expect(drive.powerOnLabel, '100d');
      expect(drive.usedPercent, 40);
      expect(drive.smartAttributes.length, 2);
    });
  });

  group('DiskHealthController Tests', () {
    test('Initial state getters calculate correct counts', () {
      final ctrl = DiskHealthController();

      expect(ctrl.errorMessage, isEmpty);
      expect(ctrl.healthyCount, 0);
      expect(ctrl.warningCount, 0);
      expect(ctrl.criticalCount, 0);
    });
  });
}
