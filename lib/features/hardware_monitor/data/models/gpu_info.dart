class GpuInfo {
  final String name;
  final String driverVersion;
  final int totalVramBytes;
  final int usedVramBytes;
  final double usagePercent;
  final double temperatureCelsius;

  const GpuInfo({
    required this.name,
    required this.driverVersion,
    required this.totalVramBytes,
    required this.usedVramBytes,
    required this.usagePercent,
    required this.temperatureCelsius,
  });

  double get totalVramMb => totalVramBytes / (1024 * 1024);
  double get usedVramMb => usedVramBytes / (1024 * 1024);

  GpuInfo copyWith({
    String? name,
    String? driverVersion,
    int? totalVramBytes,
    int? usedVramBytes,
    double? usagePercent,
    double? temperatureCelsius,
  }) {
    return GpuInfo(
      name: name ?? this.name,
      driverVersion: driverVersion ?? this.driverVersion,
      totalVramBytes: totalVramBytes ?? this.totalVramBytes,
      usedVramBytes: usedVramBytes ?? this.usedVramBytes,
      usagePercent: usagePercent ?? this.usagePercent,
      temperatureCelsius: temperatureCelsius ?? this.temperatureCelsius,
    );
  }
}
