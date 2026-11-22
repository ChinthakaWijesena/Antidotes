import 'browser_clean_item.dart';
import 'browser_type.dart';

class BrowserProfileGroup {
  final BrowserType type;
  final String name;
  final bool isInstalled;
  final bool isRunning;
  final String profilePath;
  final List<BrowserCleanItem> items;

  BrowserProfileGroup({
    required this.type,
    required this.name,
    required this.isInstalled,
    required this.isRunning,
    required this.profilePath,
    required this.items,
  });

  int get totalSizeBytes => items.fold(0, (sum, i) => sum + i.sizeBytes);
  int get selectedSizeBytes =>
      items.where((i) => i.isSelected).fold(0, (sum, i) => sum + i.sizeBytes);

  int get totalFiles => items.fold(0, (sum, i) => sum + i.fileCount);
  int get selectedFiles =>
      items.where((i) => i.isSelected).fold(0, (sum, i) => sum + i.fileCount);

  bool get isAnySelected => items.any((i) => i.isSelected);
  bool get isAllSelected => items.isNotEmpty && items.every((i) => i.isSelected);

  BrowserProfileGroup copyWith({
    bool? isInstalled,
    bool? isRunning,
    String? profilePath,
    List<BrowserCleanItem>? items,
  }) {
    return BrowserProfileGroup(
      type: type,
      name: name,
      isInstalled: isInstalled ?? this.isInstalled,
      isRunning: isRunning ?? this.isRunning,
      profilePath: profilePath ?? this.profilePath,
      items: items ?? this.items,
    );
  }
}
