class CpuInfo {
  final String modelName;
  final int physicalCores;
  final int logicalProcessors;
  final double maxClockGhz;
  final double currentUsagePercent;
  final double temperatureCelsius;
  final List<double> usageHistory;

  const CpuInfo({
    required this.modelName,
    required this.physicalCores,
    required this.logicalProcessors,
    required this.maxClockGhz,
    required this.currentUsagePercent,
    required this.temperatureCelsius,
    this.usageHistory = const [],
  });

  CpuInfo copyWith({
    String? modelName,
    int? physicalCores,
    int? logicalProcessors,
    double? maxClockGhz,
    double? currentUsagePercent,
    double? temperatureCelsius,
    List<double>? usageHistory,
  }) {
    return CpuInfo(
      modelName: modelName ?? this.modelName,
      physicalCores: physicalCores ?? this.physicalCores,
      logicalProcessors: logicalProcessors ?? this.logicalProcessors,
      maxClockGhz: maxClockGhz ?? this.maxClockGhz,
      currentUsagePercent: currentUsagePercent ?? this.currentUsagePercent,
      temperatureCelsius: temperatureCelsius ?? this.temperatureCelsius,
      usageHistory: usageHistory ?? this.usageHistory,
    );
  }
}
