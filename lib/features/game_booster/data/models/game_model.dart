import '../../core/platform/process_platform_service.dart';

/// Represents a registered Game in the Game Booster library.
class Game {
  final String id;
  final String name;
  final String exePath;
  final String? iconCachePath;
  final bool autoBoost;
  final bool switchPowerPlan;
  final bool closeBackgroundApps;
  final bool raisePriority;
  final bool cleanTemp;
  final ProcessPriority targetPriority;
  final List<String> appsToClose;

  const Game({
    required this.id,
    required this.name,
    required this.exePath,
    this.iconCachePath,
    this.autoBoost = true,
    this.switchPowerPlan = true,
    this.closeBackgroundApps = true,
    this.raisePriority = true,
    this.cleanTemp = false,
    this.targetPriority = ProcessPriority.aboveNormal,
    this.appsToClose = const [],
  });

  /// The executable filename without path (e.g. `gta5.exe`).
  String get exeFileName {
    final slash = exePath.lastIndexOf(r'\');
    final altSlash = exePath.lastIndexOf('/');
    final index = slash > altSlash ? slash : altSlash;
    if (index != -1 && index + 1 < exePath.length) {
      return exePath.substring(index + 1);
    }
    return exePath;
  }

  Game copyWith({
    String? id,
    String? name,
    String? exePath,
    String? iconCachePath,
    bool? autoBoost,
    bool? switchPowerPlan,
    bool? closeBackgroundApps,
    bool? raisePriority,
    bool? cleanTemp,
    ProcessPriority? targetPriority,
    List<String>? appsToClose,
  }) {
    return Game(
      id: id ?? this.id,
      name: name ?? this.name,
      exePath: exePath ?? this.exePath,
      iconCachePath: iconCachePath ?? this.iconCachePath,
      autoBoost: autoBoost ?? this.autoBoost,
      switchPowerPlan: switchPowerPlan ?? this.switchPowerPlan,
      closeBackgroundApps: closeBackgroundApps ?? this.closeBackgroundApps,
      raisePriority: raisePriority ?? this.raisePriority,
      cleanTemp: cleanTemp ?? this.cleanTemp,
      targetPriority: targetPriority ?? this.targetPriority,
      appsToClose: appsToClose ?? this.appsToClose,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'exePath': exePath,
      'iconCachePath': iconCachePath,
      'autoBoost': autoBoost,
      'switchPowerPlan': switchPowerPlan,
      'closeBackgroundApps': closeBackgroundApps,
      'raisePriority': raisePriority,
      'cleanTemp': cleanTemp,
      'targetPriority': targetPriority.name,
      'appsToClose': appsToClose,
    };
  }

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] as String? ?? 'Unnamed Game',
      exePath: json['exePath'] as String? ?? '',
      iconCachePath: json['iconCachePath'] as String?,
      autoBoost: json['autoBoost'] as bool? ?? true,
      switchPowerPlan: json['switchPowerPlan'] as bool? ?? true,
      closeBackgroundApps: json['closeBackgroundApps'] as bool? ?? true,
      raisePriority: json['raisePriority'] as bool? ?? true,
      cleanTemp: json['cleanTemp'] as bool? ?? false,
      targetPriority: ProcessPriority.values.firstWhere(
        (p) => p.name == json['targetPriority'],
        orElse: () => ProcessPriority.aboveNormal,
      ),
      appsToClose: (json['appsToClose'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}
