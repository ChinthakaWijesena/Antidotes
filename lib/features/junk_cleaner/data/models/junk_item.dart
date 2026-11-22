import 'junk_pattern.dart';

class JunkItem {
  final String path;
  final String name;
  final int sizeInBytes;
  final DateTime? lastModified;
  final String categoryId;
  final PatternRisk risk;
  bool isSelected;

  JunkItem({
    required this.path,
    required this.name,
    required this.sizeInBytes,
    required this.categoryId,
    this.risk = PatternRisk.low,
    this.lastModified,
    this.isSelected = true,
  });
}
