// S.M.A.R.T. disk health model — represents one physical drive and its health metrics.

enum DiskHealthStatus {
  healthy,
  warning,
  unhealthy,
  unknown;

  static DiskHealthStatus fromString(String? s) {
    switch (s?.toLowerCase()) {
      case 'healthy':
        return DiskHealthStatus.healthy;
      case 'warning':
        return DiskHealthStatus.warning;
      case 'unhealthy':
        return DiskHealthStatus.unhealthy;
      default:
        return DiskHealthStatus.unknown;
    }
  }

  String get label {
    switch (this) {
      case DiskHealthStatus.healthy:
        return 'Healthy';
      case DiskHealthStatus.warning:
        return 'Warning';
      case DiskHealthStatus.unhealthy:
        return 'Unhealthy';
      case DiskHealthStatus.unknown:
        return 'Unknown';
    }
  }
}

enum DiskMediaType {
  ssd,
  hdd,
  nvme,
  unspecified;

  static DiskMediaType fromString(String? s) {
    final v = s?.toLowerCase() ?? '';
    if (v.contains('ssd') || v == 'ssd') return DiskMediaType.ssd;
    if (v.contains('nvme') || v.contains('nvm')) return DiskMediaType.nvme;
    if (v == 'hdd' || v.contains('hdd') || v == '3' || v == 'hdd') {
      return DiskMediaType.hdd;
    }
    if (v == '4' || v.contains('solid')) return DiskMediaType.ssd;
    if (v == '5') return DiskMediaType.nvme;
    if (v == '3') return DiskMediaType.hdd;
    return DiskMediaType.unspecified;
  }

  String get label {
    switch (this) {
      case DiskMediaType.ssd:
        return 'SSD';
      case DiskMediaType.hdd:
        return 'HDD';
      case DiskMediaType.nvme:
        return 'NVMe SSD';
      case DiskMediaType.unspecified:
        return 'Drive';
    }
  }

  String get icon {
    switch (this) {
      case DiskMediaType.ssd:
      case DiskMediaType.nvme:
        return '💾';
      case DiskMediaType.hdd:
        return '🖴';
      case DiskMediaType.unspecified:
        return '💿';
    }
  }
}

/// A single S.M.A.R.T. attribute (e.g. Reallocated Sectors, Power-On Hours).
class SmartAttribute {
  final int id;
  final String name;
  final int value;   // Normalized 0–255 (higher = better for most)
  final int worst;
  final int threshold;
  final int rawValue;

  const SmartAttribute({
    required this.id,
    required this.name,
    required this.value,
    required this.worst,
    required this.threshold,
    required this.rawValue,
  });

  bool get isFailing => value <= threshold && threshold > 0;

  factory SmartAttribute.fromJson(Map<String, dynamic> json) {
    return SmartAttribute(
      id: _parseInt(json['Id']),
      name: json['Name']?.toString() ?? 'Unknown',
      value: _parseInt(json['Value']),
      worst: _parseInt(json['Worst']),
      threshold: _parseInt(json['Threshold']),
      rawValue: _parseInt(json['RawValue']),
    );
  }

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }
}

/// Represents one physical disk drive and its full health picture.
class DiskDrive {
  final String name;
  final String model;
  final DiskMediaType mediaType;
  final DiskHealthStatus healthStatus;
  final String operationalStatus;
  final int sizeBytes;
  final int usedBytes;
  final int? temperature; // °C, null if not available
  final bool predictFailure;
  final int? powerOnHours;    // null if unavailable
  final int? lifeRemaining;   // 0–100 %, null if unavailable
  final List<SmartAttribute> smartAttributes;

  const DiskDrive({
    required this.name,
    required this.model,
    required this.mediaType,
    required this.healthStatus,
    required this.operationalStatus,
    required this.sizeBytes,
    required this.usedBytes,
    this.temperature,
    required this.predictFailure,
    this.powerOnHours,
    this.lifeRemaining,
    this.smartAttributes = const [],
  });

  // ── Computed helpers ──────────────────────────────────────────────────────

  String get sizeFormatted => _formatBytes(sizeBytes);
  String get usedFormatted => _formatBytes(usedBytes);
  String get freeFormatted => _formatBytes(sizeBytes - usedBytes);

  int get usedPercent {
    if (sizeBytes <= 0) return 0;
    return ((usedBytes / sizeBytes) * 100).round().clamp(0, 100);
  }

  String get temperatureLabel {
    if (temperature == null) return 'N/A';
    return '$temperature°C';
  }

  String get temperatureState {
    if (temperature == null) return 'unknown';
    if (temperature! < 40) return 'cool';
    if (temperature! < 55) return 'warm';
    return 'hot';
  }

  String get lifeLabel {
    if (lifeRemaining == null) return 'N/A';
    return '$lifeRemaining%';
  }

  String get powerOnLabel {
    if (powerOnHours == null) return 'N/A';
    final h = powerOnHours!;
    if (h < 24) return '${h}h';
    final days = h ~/ 24;
    if (days < 365) return '${days}d';
    return '${(days / 365).toStringAsFixed(1)}y';
  }

  static String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return i == 0 ? '$bytes B' : '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }

  factory DiskDrive.fromJson(Map<String, dynamic> json) {
    final attrs = <SmartAttribute>[];
    final rawAttrs = json['SmartAttributes'];
    if (rawAttrs is List) {
      for (final a in rawAttrs) {
        if (a is Map<String, dynamic>) {
          attrs.add(SmartAttribute.fromJson(a));
        }
      }
    }

    // Derive life remaining from SMART attribute 231 (SSD Life Left) or 177 (Wear Leveling)
    int? lifeRemaining;
    final lifeAttr = attrs.where((a) => a.id == 231 || a.id == 177).firstOrNull;
    if (lifeAttr != null) {
      lifeRemaining = lifeAttr.value.clamp(0, 100);
    }

    // Power-On Hours from attribute 9
    int? powerOnHours;
    final pohAttr = attrs.where((a) => a.id == 9).firstOrNull;
    if (pohAttr != null) {
      powerOnHours = pohAttr.rawValue;
    }
    // Also try JSON direct field
    if (powerOnHours == null && json['PowerOnHours'] != null) {
      powerOnHours = int.tryParse(json['PowerOnHours'].toString());
    }

    // Temperature from SMART attr 194 or 190, or direct field
    int? temp = json['Temperature'] != null
        ? int.tryParse(json['Temperature'].toString())
        : null;
    if (temp == null) {
      final tempAttr = attrs.where((a) => a.id == 194 || a.id == 190).firstOrNull;
      if (tempAttr != null) temp = tempAttr.rawValue & 0xFF;
    }
    if (temp != null && (temp < 1 || temp > 100)) temp = null; // sanity check

    return DiskDrive(
      name: json['Name']?.toString() ?? 'Unknown Drive',
      model: json['Model']?.toString() ?? json['Name']?.toString() ?? 'Unknown',
      mediaType: DiskMediaType.fromString(json['MediaType']?.toString()),
      healthStatus: DiskHealthStatus.fromString(json['HealthStatus']?.toString()),
      operationalStatus: json['OperationalStatus']?.toString() ?? 'Unknown',
      sizeBytes: int.tryParse(json['SizeBytes']?.toString() ?? '0') ?? 0,
      usedBytes: int.tryParse(json['UsedBytes']?.toString() ?? '0') ?? 0,
      temperature: temp,
      predictFailure: json['PredictFailure']?.toString().toLowerCase() == 'true',
      powerOnHours: powerOnHours,
      lifeRemaining: lifeRemaining,
      smartAttributes: attrs,
    );
  }
}
