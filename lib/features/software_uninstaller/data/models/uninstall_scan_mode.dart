enum UninstallScanMode {
  safe,
  moderate,
  advanced;

  String get displayName {
    switch (this) {
      case UninstallScanMode.safe:
        return 'Safe';
      case UninstallScanMode.moderate:
        return 'Moderate';
      case UninstallScanMode.advanced:
        return 'Advanced';
    }
  }

  String get description {
    switch (this) {
      case UninstallScanMode.safe:
        return 'Performs the fastest scan, checking standard registry and application locations safely.';
      case UninstallScanMode.moderate:
        return 'Includes extended scanning in common application paths, user profiles, and registry hives.';
      case UninstallScanMode.advanced:
        return 'Deep thorough scan of all registry keys, traces, shell extensions, AppData, and leftover files.';
    }
  }
}
