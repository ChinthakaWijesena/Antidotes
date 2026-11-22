class DriveInfo {
  final String letter;
  final String label;
  final String fileSystem;
  final int totalBytes;
  final int freeBytes;

  const DriveInfo({
    required this.letter,
    required this.label,
    required this.fileSystem,
    required this.totalBytes,
    required this.freeBytes,
  });

  int get usedBytes => totalBytes - freeBytes;
  double get usagePercent =>
      totalBytes > 0 ? (usedBytes / totalBytes) * 100 : 0.0;

  double get totalGb => totalBytes / (1024 * 1024 * 1024);
  double get freeGb => freeBytes / (1024 * 1024 * 1024);
  double get usedGb => usedBytes / (1024 * 1024 * 1024);
}

class StorageInfo {
  final List<DriveInfo> drives;

  const StorageInfo({required this.drives});

  int get totalCapacityBytes => drives.fold(0, (s, d) => s + d.totalBytes);
  int get totalFreeCapacityBytes => drives.fold(0, (s, d) => s + d.freeBytes);
  int get totalUsedCapacityBytes =>
      totalCapacityBytes - totalFreeCapacityBytes;
  double get overallUsagePercent => totalCapacityBytes > 0
      ? (totalUsedCapacityBytes / totalCapacityBytes) * 100
      : 0.0;
}
