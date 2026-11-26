import 'package:flutter_test/flutter_test.dart';
import 'package:antidotes/features/junk_cleaner/data/models/junk_category.dart';
import 'package:antidotes/features/junk_cleaner/data/models/junk_pattern.dart';
import 'package:antidotes/features/junk_cleaner/data/models/cleaner_safety_options.dart';
import 'package:antidotes/features/junk_cleaner/data/services/junk_cleaner_service.dart';

void main() {
  group('JunkPattern Matching & Risk Tests', () {
    final patterns = JunkPattern.getStandardPatterns();

    bool matches(String filename, String patternStr) {
      final p = patterns.firstWhere((p) => p.pattern.contains(patternStr));
      return p.matches(filename);
    }

    test('matches temporary files as low risk', () {
      expect(matches('test.tmp', '*.tmp'), true);
      expect(matches('data.temp', '*.tmp'), true);
      final p = patterns.firstWhere((p) => p.pattern.contains('*.tmp'));
      expect(p.risk, PatternRisk.low);
      expect(p.defaultEnabled, true);
    });

    test('matches editor and office temp files', () {
      expect(matches('~test.docx', '~*.*'), true);
      expect(matches('file.~tmp', '~*.*'), true);
    });

    test('matches chkdsk fragments and Thumbs.db', () {
      expect(matches('file0001.chk', '*.chk'), true);
      expect(matches('Thumbs.db', 'Thumbs.db'), true);
    });

    test('matches *.log as medium risk and default disabled', () {
      final p = patterns.firstWhere((p) => p.pattern == '*.log');
      expect(p.matches('error.log'), true);
      expect(p.risk, PatternRisk.medium);
      expect(p.defaultEnabled, false);
    });

    test('matches *.old and *.bak as high risk and default disabled', () {
      final p = patterns.firstWhere((p) => p.pattern.contains('*.old'));
      expect(p.matches('document.old'), true);
      expect(p.matches('database.bak'), true);
      expect(p.risk, PatternRisk.high);
      expect(p.defaultEnabled, false);
    });
  });

  group('CleanerSafetyOptions Tests', () {
    test('default options maintain strict safety', () {
      final options = CleanerSafetyOptions();
      expect(options.ignoreRecent24Hours, true);
      expect(options.includeLogs, false);
      expect(options.includeBackups, false);
      expect(options.skipSymlinksAndJunctions, true);
    });
  });

  group('JunkCleanerService & Category Verification Tests', () {
    final service = JunkCleanerService();
    final categories = service.getCategories();

    test('contains all expected BleachBit-aligned categories', () {
      final types = categories.map((c) => c.type).toSet();
      expect(types.contains(JunkCategoryType.userTemp), true);
      expect(types.contains(JunkCategoryType.systemTemp), true);
      expect(types.contains(JunkCategoryType.inetCache), true);
      expect(types.contains(JunkCategoryType.recycleBin), true);
      expect(types.contains(JunkCategoryType.prefetch), true);
      expect(types.contains(JunkCategoryType.dnsCache), true);
      expect(types.contains(JunkCategoryType.clipboard), true);
      expect(types.contains(JunkCategoryType.muiCache), true);
      expect(types.contains(JunkCategoryType.crashDumps), true);
      expect(types.contains(JunkCategoryType.windowsLogs), true);
    });

    test('crash dumps include MEMORY.DMP and LiveKernelReports', () {
      final crashDumps =
          categories.firstWhere((c) => c.type == JunkCategoryType.crashDumps);
      expect(
          crashDumps.paths.any((p) => p.toLowerCase().endsWith('memory.dmp')),
          true);
      expect(
          crashDumps.paths
              .any((p) => p.toLowerCase().contains('livekernelreports')),
          true);
    });

    test('windows logs include Panther and setupapi', () {
      final logs =
          categories.firstWhere((c) => c.type == JunkCategoryType.windowsLogs);
      expect(logs.paths.any((p) => p.toLowerCase().contains('panther')), true);
      expect(
          logs.paths.any((p) => p.toLowerCase().contains('setupapi')), true);
    });

    test('special categories correctly identified', () {
      final dns =
          categories.firstWhere((c) => c.type == JunkCategoryType.dnsCache);
      final clip =
          categories.firstWhere((c) => c.type == JunkCategoryType.clipboard);
      final mui =
          categories.firstWhere((c) => c.type == JunkCategoryType.muiCache);
      final rb =
          categories.firstWhere((c) => c.type == JunkCategoryType.recycleBin);
      final temp =
          categories.firstWhere((c) => c.type == JunkCategoryType.userTemp);

      expect(dns.isSpecialCategory, true);
      expect(clip.isSpecialCategory, true);
      expect(mui.isSpecialCategory, true);
      expect(rb.isSpecialCategory, true);
      expect(temp.isSpecialCategory, false);
    });
  });
}
