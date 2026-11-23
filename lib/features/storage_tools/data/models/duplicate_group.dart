/// A group of files that have identical content.
class DuplicateGroup {
  /// All file paths in this group (identical content).
  final List<String> paths;

  /// Size of each file in bytes (all identical).
  final int sizeBytes;

  const DuplicateGroup({required this.paths, required this.sizeBytes});

  /// Space wasted by keeping all duplicates (count - 1) × size.
  int get wastedBytes => (paths.length - 1) * sizeBytes;

  /// Total number of duplicate copies (excluding the "original").
  int get duplicateCount => paths.length - 1;
}

/// Progress update emitted during a duplicate scan.
class DuplicateScanProgress {
  final String currentPath;
  final int filesHashed;
  final int totalFiles;
  DuplicateScanProgress({
    required this.currentPath,
    required this.filesHashed,
    required this.totalFiles,
  });
}
