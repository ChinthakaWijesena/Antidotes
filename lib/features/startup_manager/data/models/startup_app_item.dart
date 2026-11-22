enum StartupImpact {
  high,
  medium,
  low,
  none,
  notMeasured,
}

class StartupAppItem {
  final String id;
  final String name;
  final String publisher;
  final String command;
  final String executablePath;
  final String location;
  final String locationType; // 'UserRegistry', 'MachineRegistry', 'MachineRegistry32', 'StartupFolder', 'UWP'
  final String packageFamilyName;
  final String taskId;
  bool isEnabled;
  final StartupImpact impact;

  StartupAppItem({
    required this.id,
    required this.name,
    required this.publisher,
    required this.command,
    required this.executablePath,
    required this.location,
    required this.locationType,
    required this.packageFamilyName,
    required this.taskId,
    required this.isEnabled,
    this.impact = StartupImpact.none,
  });

  String get impactLabel {
    switch (impact) {
      case StartupImpact.high:
        return 'High';
      case StartupImpact.medium:
        return 'Medium';
      case StartupImpact.low:
        return 'Low';
      case StartupImpact.none:
        return 'None';
      case StartupImpact.notMeasured:
        return 'Not measured';
    }
  }

  factory StartupAppItem.fromJson(Map<String, dynamic> json) {
    final name = json['Name']?.toString() ?? 'Unknown';
    final cmd = json['Command']?.toString() ?? '';
    final pub = json['Publisher']?.toString() ?? 'Unknown';
    final locType = json['LocationType']?.toString() ?? 'UserRegistry';
    final loc = json['Location']?.toString() ?? 'Registry';
    final enabled = json['Enabled'] == true;
    final pfn = json['PackageFamilyName']?.toString() ?? '';
    final tId = json['TaskId']?.toString() ?? '';
    final id = json['Id']?.toString() ?? '${locType}_$name';

    return StartupAppItem(
      id: id,
      name: name,
      publisher: pub.isEmpty ? 'Unknown' : pub,
      command: cmd,
      executablePath: cmd,
      location: loc,
      locationType: locType,
      packageFamilyName: pfn,
      taskId: tId,
      isEnabled: enabled,
      impact: _determineImpact(name, cmd, pub, enabled),
    );
  }

  static StartupImpact _determineImpact(
      String name, String command, String publisher, bool isEnabled) {
    if (!isEnabled) return StartupImpact.none;

    final lower = '$name $command $publisher'.toLowerCase();
    if (lower.contains('updater') ||
        lower.contains('google drive') ||
        lower.contains('discord') ||
        lower.contains('steam')) {
      return StartupImpact.high;
    }
    if (lower.contains('chrome') ||
        lower.contains('edge') ||
        lower.contains('firefox') ||
        lower.contains('lively') ||
        lower.contains('whatsapp')) {
      return StartupImpact.medium;
    }
    if (lower.contains('pc manager') || lower.contains('security')) {
      return StartupImpact.notMeasured;
    }
    return StartupImpact.low;
  }
}
