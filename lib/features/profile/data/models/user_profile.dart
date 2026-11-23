class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String tier; // "Free Standard", "Pro Optimizer", "Admin"
  final DateTime createdAt;
  final DateTime lastActiveAt;
  final int totalCleanedBytes;
  final int totalRamOptimizations;
  final int totalDnsSwitches;
  final Map<String, dynamic> preferences;

  const UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.tier = 'Free Standard',
    required this.createdAt,
    required this.lastActiveAt,
    this.totalCleanedBytes = 0,
    this.totalRamOptimizations = 0,
    this.totalDnsSwitches = 0,
    this.preferences = const {},
  });

  String get formattedCleanedStorage {
    if (totalCleanedBytes <= 0) return '0 MB';
    final mb = totalCleanedBytes / (1024 * 1024);
    if (mb < 1024) {
      return '${mb.toStringAsFixed(1)} MB';
    }
    final gb = mb / 1024;
    return '${gb.toStringAsFixed(2)} GB';
  }

  UserProfile copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    String? tier,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    int? totalCleanedBytes,
    int? totalRamOptimizations,
    int? totalDnsSwitches,
    Map<String, dynamic>? preferences,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      tier: tier ?? this.tier,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      totalCleanedBytes: totalCleanedBytes ?? this.totalCleanedBytes,
      totalRamOptimizations:
          totalRamOptimizations ?? this.totalRamOptimizations,
      totalDnsSwitches: totalDnsSwitches ?? this.totalDnsSwitches,
      preferences: preferences ?? this.preferences,
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'tier': tier,
        'createdAt': createdAt.toIso8601String(),
        'lastActiveAt': lastActiveAt.toIso8601String(),
        'totalCleanedBytes': totalCleanedBytes,
        'totalRamOptimizations': totalRamOptimizations,
        'totalDnsSwitches': totalDnsSwitches,
        'preferences': preferences,
      };

  factory UserProfile.fromMap(Map<String, dynamic> map, {String? defaultUid}) {
    return UserProfile(
      uid: (map['uid'] as String?) ?? defaultUid ?? '',
      email: (map['email'] as String?) ?? '',
      displayName: (map['displayName'] as String?) ?? 'Antidotes User',
      photoUrl: map['photoUrl'] as String?,
      tier: (map['tier'] as String?) ?? 'Free Standard',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      lastActiveAt: map['lastActiveAt'] != null
          ? DateTime.tryParse(map['lastActiveAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      totalCleanedBytes: (map['totalCleanedBytes'] as num?)?.toInt() ?? 0,
      totalRamOptimizations:
          (map['totalRamOptimizations'] as num?)?.toInt() ?? 0,
      totalDnsSwitches: (map['totalDnsSwitches'] as num?)?.toInt() ?? 0,
      preferences: (map['preferences'] as Map<String, dynamic>?) ?? {},
    );
  }
}
