import 'package:flutter_test/flutter_test.dart';
import 'package:antidotes/core/utils/admin_helper.dart';

void main() {
  group('AdminHelper Tests', () {
    test('isRunningAsAdmin returns a boolean', () async {
      final isAdmin = await AdminHelper.isRunningAsAdmin();
      expect(isAdmin, isA<bool>());
    });
  });
}
