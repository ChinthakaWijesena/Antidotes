class CleanerSafetyOptions {
  /// Ignore files modified or accessed within the last 24 hours
  bool ignoreRecent24Hours;

  /// Send files to Windows Recycle Bin instead of permanent deletion
  bool sendToRecycleBin;

  /// Do not follow symlinks or directory junctions (always true for safety)
  final bool skipSymlinksAndJunctions;

  /// User-specified folder paths to exclude from scanning and cleaning
  List<String> excludeFolders;

  /// User-specified filename patterns to exclude (e.g., *.keep, *.db)
  List<String> excludePatterns;

  /// Include medium-risk *.log files (Default false)
  bool includeLogs;

  /// Include high-risk *.old and *.bak files (Default false)
  bool includeBackups;

  /// Clean Windows Update cache (SoftwareDistribution\Download)
  bool cleanWindowsUpdateCache;

  CleanerSafetyOptions({
    this.ignoreRecent24Hours = true,
    this.sendToRecycleBin = false,
    this.skipSymlinksAndJunctions = true,
    List<String>? excludeFolders,
    List<String>? excludePatterns,
    this.includeLogs = false,
    this.includeBackups = false,
    this.cleanWindowsUpdateCache = false,
  })  : excludeFolders = excludeFolders ?? [],
        excludePatterns = excludePatterns ?? [];

  CleanerSafetyOptions clone() {
    return CleanerSafetyOptions(
      ignoreRecent24Hours: ignoreRecent24Hours,
      sendToRecycleBin: sendToRecycleBin,
      skipSymlinksAndJunctions: skipSymlinksAndJunctions,
      excludeFolders: List.from(excludeFolders),
      excludePatterns: List.from(excludePatterns),
      includeLogs: includeLogs,
      includeBackups: includeBackups,
      cleanWindowsUpdateCache: cleanWindowsUpdateCache,
    );
  }
}
