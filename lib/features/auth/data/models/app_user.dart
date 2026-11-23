class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final bool isEmailVerified;
  final bool isAnonymous;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;

  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.isEmailVerified = false,
    this.isAnonymous = false,
    this.createdAt,
    this.lastLoginAt,
  });

  String get initials {
    if (displayName.trim().isEmpty) {
      if (email.isNotEmpty) return email.substring(0, 1).toUpperCase();
      return 'U';
    }
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? isEmailVerified,
    bool? isAnonymous,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'isEmailVerified': isEmailVerified,
        'isAnonymous': isAnonymous,
        'createdAt': createdAt?.toIso8601String(),
        'lastLoginAt': lastLoginAt?.toIso8601String(),
      };

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
        uid: map['uid'] as String? ?? '',
        email: map['email'] as String? ?? '',
        displayName: map['displayName'] as String? ?? 'Antidotes User',
        photoUrl: map['photoUrl'] as String?,
        isEmailVerified: map['isEmailVerified'] as bool? ?? false,
        isAnonymous: map['isAnonymous'] as bool? ?? false,
        createdAt: map['createdAt'] != null
            ? DateTime.tryParse(map['createdAt'].toString())
            : null,
        lastLoginAt: map['lastLoginAt'] != null
            ? DateTime.tryParse(map['lastLoginAt'].toString())
            : null,
      );
}
