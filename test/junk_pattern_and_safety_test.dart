import 'package:flutter_test/flutter_test.dart';
import 'package:antidotes/features/junk_cleaner/data/models/junk_pattern.dart';
import 'package:antidotes/features/junk_cleaner/data/models/cleaner_safety_options.dart';

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
}
