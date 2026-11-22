class RamInfo {
  final int totalBytes;
  final int usedBytes;
  final int freeBytes;
  final double usagePercent;
  final List<double> usageHistory;

  const RamInfo({
    required this.totalBytes,
    required this.usedBytes,
    required this.freeBytes,
    required this.usagePercent,
    this.usageHistory = const [],
  });

  double get totalGb => totalBytes / (1024 * 1024 * 1024);
  double get usedGb => usedBytes / (1024 * 1024 * 1024);
  double get freeGb => freeBytes / (1024 * 1024 * 1024);

  RamInfo copyWith({
    int? totalBytes,
    int? usedBytes,
    int? freeBytes,
    double? usagePercent,
    List<double>? usageHistory,
  }) {
    return RamInfo(
      totalBytes: totalBytes ?? this.totalBytes,
      usedBytes: usedBytes ?? this.usedBytes,
      freeBytes: freeBytes ?? this.freeBytes,
      usagePercent: usagePercent ?? this.usagePercent,
      usageHistory: usageHistory ?? this.usageHistory,
    );
  }
}
