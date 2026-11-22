class EnvVariableItem {
  final String name;
  final String value;
  final bool isSystem;

  const EnvVariableItem({
    required this.name,
    required this.value,
    this.isSystem = false,
  });

  EnvVariableItem copyWith({
    String? name,
    String? value,
    bool? isSystem,
  }) {
    return EnvVariableItem(
      name: name ?? this.name,
      value: value ?? this.value,
      isSystem: isSystem ?? this.isSystem,
    );
  }
}
