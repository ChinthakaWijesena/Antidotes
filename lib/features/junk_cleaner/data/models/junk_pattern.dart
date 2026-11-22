enum PatternRisk {
  low,
  medium,
  high,
}

class JunkPattern {
  final String pattern;
  final String description;
  final PatternRisk risk;
  final bool defaultEnabled;
  final RegExp regex;

  const JunkPattern({
    required this.pattern,
    required this.description,
    required this.risk,
    required this.defaultEnabled,
    required this.regex,
  });

  bool matches(String filename) {
    return regex.hasMatch(filename);
  }

  static List<JunkPattern> getStandardPatterns() {
    return [
      // Low Risk
      JunkPattern(
        pattern: '*.tmp, *.temp',
        description: 'Standard temporary files',
        risk: PatternRisk.low,
        defaultEnabled: true,
        regex: RegExp(r'\.(tmp|temp)$', caseSensitive: false),
      ),
      JunkPattern(
        pattern: '~*.*, *.~*',
        description: 'Editor and Microsoft Office temporary work files',
        risk: PatternRisk.low,
        defaultEnabled: true,
        regex: RegExp(r'(^~.*|\.~.*)$', caseSensitive: false),
      ),
      JunkPattern(
        pattern: '*.chk',
        description: 'CHKDSK recovered lost file fragments',
        risk: PatternRisk.low,
        defaultEnabled: true,
        regex: RegExp(r'\.chk$', caseSensitive: false),
      ),
      JunkPattern(
        pattern: '*.gid, *.fts, *.ftg, *.prv',
        description: 'Legacy Windows Help index and cache files',
        risk: PatternRisk.low,
        defaultEnabled: true,
        regex: RegExp(r'\.(gid|fts|ftg|prv)$', caseSensitive: false),
      ),
      JunkPattern(
        pattern: r'*.$$$, *._mp, *.---',
        description: 'Installer and uninstaller temporary leftovers',
        risk: PatternRisk.low,
        defaultEnabled: true,
        regex: RegExp(r'\.(\${3}|_mp|\-\-\-)$', caseSensitive: false),
      ),
      JunkPattern(
        pattern: '*.dmp',
        description: 'Application and process crash dumps',
        risk: PatternRisk.low,
        defaultEnabled: true,
        regex: RegExp(r'\.dmp$', caseSensitive: false),
      ),
      JunkPattern(
        pattern: 'Thumbs.db',
        description: 'Legacy Windows Explorer thumbnail database cache',
        risk: PatternRisk.low,
        defaultEnabled: true,
        regex: RegExp(r'^thumbs\.db$', caseSensitive: false),
      ),

      // Medium Risk (Default OFF)
      JunkPattern(
        pattern: '*.log',
        description: 'Application activity log files (some apps write to these)',
        risk: PatternRisk.medium,
        defaultEnabled: false,
        regex: RegExp(r'\.log$', caseSensitive: false),
      ),

      // High Risk (Default OFF)
      JunkPattern(
        pattern: '*.old, *.bak',
        description: 'Backup files (may contain user document revisions)',
        risk: PatternRisk.high,
        defaultEnabled: false,
        regex: RegExp(r'\.(old|bak)$', caseSensitive: false),
      ),
    ];
  }
}
