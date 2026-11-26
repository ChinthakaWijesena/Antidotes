/// Represents a running Windows process available for inspection and selective closing.
class RunningProcess {
  final int pid;
  final String name;
  final int memoryMb;
  final bool isProtected;
  final String? iconCachePath;

  const RunningProcess({
    required this.pid,
    required this.name,
    required this.memoryMb,
    required this.isProtected,
    this.iconCachePath,
  });

  /// Process name without `.exe` for clean display.
  String get displayName {
    if (name.toLowerCase().endsWith('.exe')) {
      return name.substring(0, name.length - 4);
    }
    return name;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RunningProcess && runtimeType == other.runtimeType && pid == other.pid;

  @override
  int get hashCode => pid.hashCode;
}
