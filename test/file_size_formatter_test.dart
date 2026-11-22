import 'package:flutter_test/flutter_test.dart';
import 'package:antidotes/core/utils/file_size_formatter.dart';
import 'package:antidotes/features/junk_cleaner/data/services/junk_cleaner_service.dart';

void main() {
  group('FileSizeFormatter Tests', () {
    test('formats 0 bytes correctly', () {
      expect(FileSizeFormatter.format(0), '0 B');
    });

    test('formats bytes correctly', () {
      expect(FileSizeFormatter.format(500), '500 B');
    });

    test('formats kilobytes correctly', () {
      expect(FileSizeFormatter.format(1024), '1.0 KB');
      expect(FileSizeFormatter.format(2048), '2.0 KB');
    });

    test('formats megabytes correctly', () {
      expect(FileSizeFormatter.format(1024 * 1024), '1.0 MB');
      expect(FileSizeFormatter.format((1024 * 1024 * 2.5).toInt()), '2.5 MB');
    });

    test('formats gigabytes correctly', () {
      expect(FileSizeFormatter.format(1024 * 1024 * 1024), '1.0 GB');
    });
  });

  group('JunkCleanerService Tests', () {
    test('initializes default categories', () {
      final service = JunkCleanerService();
      final categories = service.getCategories();
      expect(categories.isNotEmpty, true);
      expect(categories.any((c) => c.id == 'user_temp'), true);
      expect(categories.any((c) => c.id == 'system_temp'), true);
    });
  });
}
