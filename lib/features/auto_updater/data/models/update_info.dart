class UpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final String releaseDate;
  final String downloadUrl;
  final List<String> changelog;
  final bool isMandatory;
  final int? fileSizeBytes;

  const UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseDate,
    required this.downloadUrl,
    required this.changelog,
    this.isMandatory = false,
    this.fileSizeBytes,
  });

  /// Compares semantic versions (e.g. "1.1.0" > "1.0.0")
  bool get hasUpdate => compareVersions(latestVersion, currentVersion) > 0;

  factory UpdateInfo.fromJson(Map<String, dynamic> json, {required String currentVersion}) {
    final rawChangelog = json['changelog'];
    final List<String> changelogList = rawChangelog is List
        ? rawChangelog.map((e) => e.toString()).toList()
        : <String>[];

    return UpdateInfo(
      currentVersion: currentVersion,
      latestVersion: json['latest_version']?.toString() ?? currentVersion,
      releaseDate: json['release_date']?.toString() ?? '',
      downloadUrl: json['download_url']?.toString() ?? '',
      changelog: changelogList,
      isMandatory: json['mandatory'] == true,
      fileSizeBytes: json['file_size_bytes'] is int ? json['file_size_bytes'] as int : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latest_version': latestVersion,
      'release_date': releaseDate,
      'download_url': downloadUrl,
      'mandatory': isMandatory,
      'changelog': changelog,
      if (fileSizeBytes != null) 'file_size_bytes': fileSizeBytes,
    };
  }

  /// Returns:
  /// > 0 if v1 > v2
  /// < 0 if v1 < v2
  /// 0 if v1 == v2
  static int compareVersions(String v1, String v2) {
    try {
      final cleanV1 = v1.replaceAll(RegExp(r'[^0-9.]'), '');
      final cleanV2 = v2.replaceAll(RegExp(r'[^0-9.]'), '');

      final parts1 = cleanV1.split('.').map((p) => int.tryParse(p) ?? 0).toList();
      final parts2 = cleanV2.split('.').map((p) => int.tryParse(p) ?? 0).toList();

      final maxLen = parts1.length > parts2.length ? parts1.length : parts2.length;
      for (int i = 0; i < maxLen; i++) {
        final p1 = i < parts1.length ? parts1[i] : 0;
        final p2 = i < parts2.length ? parts2[i] : 0;
        if (p1 != p2) {
          return p1.compareTo(p2);
        }
      }
      return 0;
    } catch (_) {
      return v1.compareTo(v2);
    }
  }
}
