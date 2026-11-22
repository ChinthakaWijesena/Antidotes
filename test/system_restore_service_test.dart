import 'package:flutter_test/flutter_test.dart';
import 'package:antidotes/core/services/system_restore_service.dart';
import 'package:antidotes/features/junk_cleaner/data/models/cleaner_safety_options.dart';

void main() {
  group('SystemRestoreService Tests', () {
    test('SystemRestoreService initializes and checks platform support', () {
      final service = SystemRestoreService();
      expect(service.isSupported(), isTrue);
    });

    test('SystemRestoreResult accurately reports success status', () {
      final successResult = SystemRestoreResult(
        status: SystemRestoreStatus.success,
        message: 'Point created',
        description: 'Test point',
        timestamp: DateTime.now(),
      );
      expect(successResult.isSuccess, isTrue);

      final failedResult = SystemRestoreResult(
        status: SystemRestoreStatus.failed,
        message: 'Access denied',
        description: 'Test point',
        timestamp: DateTime.now(),
      );
      expect(failedResult.isSuccess, isFalse);

      final cancelledResult = SystemRestoreResult(
        status: SystemRestoreStatus.cancelled,
        message: 'UAC declined',
        description: 'Test point',
        timestamp: DateTime.now(),
      );
      expect(cancelledResult.isSuccess, isFalse);
    });

    test('CleanerSafetyOptions includes askCreateRestorePoint with true default', () {
      final options = CleanerSafetyOptions();
      expect(options.askCreateRestorePoint, isTrue);

      final cloned = options.clone();
      expect(cloned.askCreateRestorePoint, isTrue);

      options.askCreateRestorePoint = false;
      final clonedFalse = options.clone();
      expect(clonedFalse.askCreateRestorePoint, isFalse);
    });
  });
}
