enum BatteryPowerState {
  charging,
  discharging,
  full,
  unknown,
  noBattery,
}

class BatteryInfo {
  final bool hasBattery;
  final int chargePercent;
  final BatteryPowerState state;
  final bool isAcConnected;
  final int estimatedRemainingSeconds;
  final double healthPercent;
  final double temperatureCelsius;
  final int designCapacityMWh;
  final int fullChargeCapacityMWh;

  const BatteryInfo({
    required this.hasBattery,
    required this.chargePercent,
    required this.state,
    required this.isAcConnected,
    required this.estimatedRemainingSeconds,
    required this.healthPercent,
    required this.temperatureCelsius,
    required this.designCapacityMWh,
    required this.fullChargeCapacityMWh,
  });

  String get stateLabel {
    if (!hasBattery) return 'Desktop PC (AC Power)';
    switch (state) {
      case BatteryPowerState.charging:
        return 'Charging';
      case BatteryPowerState.discharging:
        return 'On Battery';
      case BatteryPowerState.full:
        return 'Fully Charged';
      case BatteryPowerState.unknown:
        return isAcConnected ? 'Plugged In' : 'Discharging';
      case BatteryPowerState.noBattery:
        return 'No Battery';
    }
  }

  String get remainingTimeFormatted {
    if (estimatedRemainingSeconds <= 0 ||
        estimatedRemainingSeconds > 86400 ||
        state == BatteryPowerState.charging) {
      return isAcConnected ? 'Calculating...' : 'Estimated runtime unavailable';
    }
    final hours = estimatedRemainingSeconds ~/ 3600;
    final mins = (estimatedRemainingSeconds % 3600) ~/ 60;
    return '${hours}h ${mins}m remaining';
  }
}
