/// A point-in-time snapshot of Windows RAM usage.
class RamSnapshot {
  /// Total physical RAM in MB.
  final int totalMb;

  /// Currently in-use RAM in MB (Working Set + Modified pages).
  final int usedMb;

  /// Standby (cached) memory in MB – prime target for reclaiming.
  final int standbyMb;

  /// Free (immediately available) RAM in MB.
  final int freeMb;

  final DateTime timestamp;

  const RamSnapshot({
    required this.totalMb,
    required this.usedMb,
    required this.standbyMb,
    required this.freeMb,
    required this.timestamp,
  });

  /// Used percentage as 0-100 double.
  double get usedPercent =>
      totalMb > 0 ? (usedMb / totalMb * 100).clamp(0, 100) : 0;

  int get availableMb => freeMb + standbyMb;
}
