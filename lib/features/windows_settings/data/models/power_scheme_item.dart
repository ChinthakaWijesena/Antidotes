class PowerSchemeItem {
  final String guid;
  final String name;
  final bool isActive;

  const PowerSchemeItem({
    required this.guid,
    required this.name,
    this.isActive = false,
  });

  PowerSchemeItem copyWith({
    String? guid,
    String? name,
    bool? isActive,
  }) {
    return PowerSchemeItem(
      guid: guid ?? this.guid,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
    );
  }
}

