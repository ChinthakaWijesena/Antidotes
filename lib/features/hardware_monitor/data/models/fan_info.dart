class FanInfo {
  final int cpuFanRpm;
  final int gpuFanRpm;
  final double speedPercent;
  final String mode; // 'Silent', 'Quiet', 'Balanced', 'Performance', 'Turbo', 'Live'
  final int fanCount;
  final bool isRunning;
  final double acousticsDba;
  final List<double> history;

  /// Data source: 'LHM', 'OHM', 'ASUS', 'MSI', 'HP', 'Lenovo', 'Dell', 'Acer',
  /// 'Samsung', 'Razer', 'Est.' (temperature estimate)
  final String source;

  /// True when fan RPM is read from real hardware / manufacturer API.
  /// False when value is estimated from temperature curve.
  final bool isReal;

  const FanInfo({
    required this.cpuFanRpm,
    required this.gpuFanRpm,
    required this.speedPercent,
    required this.mode,
    this.fanCount = 2,
    this.isRunning = true,
    this.acousticsDba = 19.8,
    this.history = const [],
    this.source = 'Est.',
    this.isReal = false,
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
    String? source,
    bool? isReal,
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
      source: source ?? this.source,
      isReal: isReal ?? this.isReal,
    );
  }
}
