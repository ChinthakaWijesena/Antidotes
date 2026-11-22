enum LeftoverType {
  registryKey,
  registryValue,
  file,
  folder;

  bool get isRegistry =>
      this == LeftoverType.registryKey || this == LeftoverType.registryValue;
}

class LeftoverItem {
  final String id;
  final LeftoverType type;
  final String rootKey; // e.g. "HKEY_CURRENT_USER" or "File System"
  final String path; // e.g. "HKEY_CURRENT_USER\Software\Microsoft\Windows\Shell\MuiCache"
  final String name; // e.g. "C:\Program Files\VideoLAN\VLC\vlc.exe.FriendlyAppName - VLC media player"
  final String valueData;
  final int sizeInBytes;
  bool isSelected;
  bool isDeleted;

  LeftoverItem({
    required this.id,
    required this.type,
    required this.rootKey,
    required this.path,
    required this.name,
    this.valueData = '',
    this.sizeInBytes = 0,
    this.isSelected = true,
    this.isDeleted = false,
  });

  bool get isRegistry => type.isRegistry;

  String get fullDisplayPath {
    if (path.isEmpty) return rootKey;
    return path;
  }

  LeftoverItem copyWith({
    String? id,
    LeftoverType? type,
    String? rootKey,
    String? path,
    String? name,
    String? valueData,
    int? sizeInBytes,
    bool? isSelected,
    bool? isDeleted,
  }) {
    return LeftoverItem(
      id: id ?? this.id,
      type: type ?? this.type,
      rootKey: rootKey ?? this.rootKey,
      path: path ?? this.path,
      name: name ?? this.name,
      valueData: valueData ?? this.valueData,
      sizeInBytes: sizeInBytes ?? this.sizeInBytes,
      isSelected: isSelected ?? this.isSelected,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
