import 'package:flutter/material.dart';

/// The five memory-cleaning operations available in the RAM Optimizer,
/// mirroring the operations of Sordum Reduce Memory v1.8.
enum RamOperation {
  /// Trim working-set pages held by running user applications.
  /// Works without Administrator.
  processWorkingSets,

  /// Reset the Windows file-system cache (SetSystemFileCacheSize).
  /// Works without Administrator.
  systemCache,

  /// Trim working sets of Windows Services and background programs.
  /// Requires Administrator (UAC).
  serviceWorkingSets,

  /// Flush the Modified Page List to disk (NtSetSystemInformation / command 3).
  /// Requires Administrator (UAC).
  modifiedPageList,

  /// Purge the Standby List (NtSetSystemInformation / command 4).
  /// Requires Administrator (UAC).
  standbyList,
}

extension RamOperationExt on RamOperation {
  String get displayName => switch (this) {
        RamOperation.processWorkingSets => 'Process Working Sets',
        RamOperation.systemCache        => 'System Memory Cache',
        RamOperation.serviceWorkingSets => 'Services & Background',
        RamOperation.modifiedPageList   => 'Modified Page List',
        RamOperation.standbyList        => 'Standby List',
      };

  String get description => switch (this) {
        RamOperation.processWorkingSets =>
            'Trim memory held by running applications',
        RamOperation.systemCache =>
            'Clear Windows file-system & memory cache',
        RamOperation.serviceWorkingSets =>
            'Free RAM from Windows services and background programs',
        RamOperation.modifiedPageList =>
            'Flush modified pages to disk before freeing',
        RamOperation.standbyList =>
            'Purge the standby cache (most RAM freed)',
      };

  bool get requiresAdmin => switch (this) {
        RamOperation.processWorkingSets => false,
        RamOperation.systemCache        => false,
        RamOperation.serviceWorkingSets => true,
        RamOperation.modifiedPageList   => true,
        RamOperation.standbyList        => true,
      };

  IconData get icon => switch (this) {
        RamOperation.processWorkingSets => Icons.apps_rounded,
        RamOperation.systemCache        => Icons.storage_rounded,
        RamOperation.serviceWorkingSets => Icons.settings_rounded,
        RamOperation.modifiedPageList   => Icons.save_rounded,
        RamOperation.standbyList        => Icons.layers_clear_rounded,
      };
}

/// Holds which operations the user wants to run.
class RamOptimizeOptions {
  final Set<RamOperation> selected;

  const RamOptimizeOptions({required this.selected});

  /// Default: all five operations enabled.
  factory RamOptimizeOptions.allEnabled() => RamOptimizeOptions(
        selected: Set.of(RamOperation.values),
      );

  /// True when at least one admin operation is selected.
  bool get requiresAdmin =>
      selected.any((op) => op.requiresAdmin);

  RamOptimizeOptions copyWithToggled(RamOperation op) {
    final next = Set<RamOperation>.of(selected);
    if (next.contains(op)) {
      next.remove(op);
    } else {
      next.add(op);
    }
    return RamOptimizeOptions(selected: next);
  }

  bool isSelected(RamOperation op) => selected.contains(op);
}
