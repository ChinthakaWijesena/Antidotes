/// Real-time snapshot of system performance metrics for the Game Booster dashboard.
class BoostStats {
  final double cpuUsagePercent;
  final double ramUsagePercent;
  final double ramUsedGb;
  final double ramTotalGb;
  final String gpuUsageDisplay;

  const BoostStats({
    required this.cpuUsagePercent,
    required this.ramUsagePercent,
    required this.ramUsedGb,
    required this.ramTotalGb,
    required this.gpuUsageDisplay,
  });

  factory BoostStats.empty() {
    return const BoostStats(
      cpuUsagePercent: 0.0,
      ramUsagePercent: 0.0,
      ramUsedGb: 0.0,
      ramTotalGb: 0.0,
      gpuUsageDisplay: 'N/A',
    );
  }
}
