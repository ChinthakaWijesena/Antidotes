class FanInfo {
  final int cpuFanRpm;
  final int gpuFanRpm;
  final double speedPercent;
  final String mode; // 'Silent', 'Balanced', 'Performance', 'Turbo'
  final int fanCount;
  final bool isRunning;
  final double acousticsDba;
  final List<double> history;

  const FanInfo({
    required this.cpuFanRpm,
    required this.gpuFanRpm,
    required this.speedPercent,
    required this.mode,
    this.fanCount = 2,
    this.isRunning = true,
    this.acousticsDba = 19.8,
    this.history = const [],
  });

  int get averageRpm => ((cpuFanRpm + gpuFanRpm) / fanCount).round();

  FanInfo copyWith({
    int? cpuFanRpm,
    int? gpuFanRpm,
    double? speedPercent,
    String? mode,
    int? fanCount,
    bool? isRunning,
    double? acousticsDba,
    List<double>? history,
  }) {
    return FanInfo(
      cpuFanRpm: cpuFanRpm ?? this.cpuFanRpm,
      gpuFanRpm: gpuFanRpm ?? this.gpuFanRpm,
      speedPercent: speedPercent ?? this.speedPercent,
      mode: mode ?? this.mode,
      fanCount: fanCount ?? this.fanCount,
      isRunning: isRunning ?? this.isRunning,
      acousticsDba: acousticsDba ?? this.acousticsDba,
      history: history ?? this.history,
    );
  }
}
