/// Represents current phase of the internet speed test.
enum SpeedTestPhase {
  idle,
  fetchingMeta,
  pinging,
  downloading,
  uploading,
  completed,
  error,
}

/// Metadata about the user's active internet connection & provider.
class NetworkMetaInfo {
  final String ip;
  final String isp;
  final String city;
  final String country;
  final String countryCode;

  const NetworkMetaInfo({
    this.ip = 'Detecting...',
    this.isp = 'Unknown Provider',
    this.city = 'Local',
    this.country = 'Sri Lanka',
    this.countryCode = 'LK',
  });

  factory NetworkMetaInfo.fromJson(Map<String, dynamic> json) {
    return NetworkMetaInfo(
      ip: json['query'] as String? ?? 'Unknown IP',
      isp: json['isp'] as String? ?? 'Local ISP',
      city: json['city'] as String? ?? 'Local',
      country: json['country'] as String? ?? 'Sri Lanka',
      countryCode: json['countryCode'] as String? ?? 'LK',
    );
  }

  NetworkMetaInfo copyWith({
    String? ip,
    String? isp,
    String? city,
    String? country,
    String? countryCode,
  }) {
    return NetworkMetaInfo(
      ip: ip ?? this.ip,
      isp: isp ?? this.isp,
      city: city ?? this.city,
      country: country ?? this.country,
      countryCode: countryCode ?? this.countryCode,
    );
  }
}

/// Snapshot result of a completed or in-progress internet speed test.
class SpeedTestResult {
  final double downloadMbps;
  final double uploadMbps;
  final int pingMs;
  final int jitterMs;
  final DateTime timestamp;

  const SpeedTestResult({
    required this.downloadMbps,
    required this.uploadMbps,
    required this.pingMs,
    required this.jitterMs,
    required this.timestamp,
  });

  /// Gaming latency quality assessment
  String get gamingQuality {
    if (pingMs <= 25 && jitterMs <= 4) return 'Ultra Low Latency (Pro)';
    if (pingMs <= 50 && jitterMs <= 10) return 'Smooth & Responsive';
    if (pingMs <= 90) return 'Moderate Gaming';
    return 'High Latency / Ping Spikes';
  }

  /// Video streaming capability assessment
  String get streamingQuality {
    if (downloadMbps >= 40.0) return '4K Ultra HD (Seamless)';
    if (downloadMbps >= 15.0) return '1080p Full HD';
    if (downloadMbps >= 5.0) return '720p HD';
    return 'Standard Definition (480p)';
  }

  /// Video conferencing / call quality assessment
  String get callQuality {
    if (uploadMbps >= 10.0 && pingMs <= 40) return 'Studio HD Video Calls';
    if (uploadMbps >= 3.0) return 'Clear Video Calls';
    return 'Audio Calls Recommended';
  }

  SpeedTestResult copyWith({
    double? downloadMbps,
    double? uploadMbps,
    int? pingMs,
    int? jitterMs,
    DateTime? timestamp,
  }) {
    return SpeedTestResult(
      downloadMbps: downloadMbps ?? this.downloadMbps,
      uploadMbps: uploadMbps ?? this.uploadMbps,
      pingMs: pingMs ?? this.pingMs,
      jitterMs: jitterMs ?? this.jitterMs,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
