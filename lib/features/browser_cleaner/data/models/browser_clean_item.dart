import 'browser_type.dart';

enum BrowserCleanCategory {
  cache,
  history,
  cookies,
  downloads,
  forms,
  sessions,
}

class BrowserCleanItem {
  final String id;
  final BrowserType browserType;
  final BrowserCleanCategory category;
  final String title;
  final String description;
  final List<String> relativePaths;
  final bool isDefaultSelected;
  final String warning;
  
  bool isSelected;
  int sizeBytes;
  int fileCount;
  List<String> detectedFiles;

  BrowserCleanItem({
    required this.id,
    required this.browserType,
    required this.category,
    required this.title,
    required this.description,
    required this.relativePaths,
    this.isDefaultSelected = false,
    this.warning = '',
    this.isSelected = false,
    this.sizeBytes = 0,
    this.fileCount = 0,
    List<String>? detectedFiles,
  }) : detectedFiles = detectedFiles ?? [];

  BrowserCleanItem copyWith({
    bool? isSelected,
    int? sizeBytes,
    int? fileCount,
    List<String>? detectedFiles,
  }) {
    return BrowserCleanItem(
      id: id,
      browserType: browserType,
      category: category,
      title: title,
      description: description,
      relativePaths: relativePaths,
      isDefaultSelected: isDefaultSelected,
      warning: warning,
      isSelected: isSelected ?? this.isSelected,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      fileCount: fileCount ?? this.fileCount,
      detectedFiles: detectedFiles ?? List.from(this.detectedFiles),
    );
  }
}
