import 'dart:io';

/// Represents a single file found during a large-file scan.
class LargeFileItem {
  final String path;
  final String name;
  final int sizeBytes;
  final String extension;
  final DateTime modified;

  const LargeFileItem({
    required this.path,
    required this.name,
    required this.sizeBytes,
    required this.extension,
    required this.modified,
  });

  factory LargeFileItem.fromFile(File file, FileStat stat) {
    final name = file.uri.pathSegments.last;
    final ext  = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    return LargeFileItem(
      path:      file.path,
      name:      name,
      sizeBytes: stat.size,
      extension: ext,
      modified:  stat.modified,
    );
  }
}

/// Progress update emitted during a large-file scan.
class LargeFileScanProgress {
  final String currentPath;
  final int filesScanned;
  LargeFileScanProgress({required this.currentPath, required this.filesScanned});
}
