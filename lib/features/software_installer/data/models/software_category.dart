enum SoftwareCategory {
  all,
  browsers,
  utilities,
  devTools,
  media,
  social,
  gaming,
}

extension SoftwareCategoryExtension on SoftwareCategory {
  String get displayName {
    switch (this) {
      case SoftwareCategory.all:
        return 'All Apps';
      case SoftwareCategory.browsers:
        return 'Browsers';
      case SoftwareCategory.utilities:
        return 'Utilities';
      case SoftwareCategory.devTools:
        return 'Developer Tools';
      case SoftwareCategory.media:
        return 'Media & Audio';
      case SoftwareCategory.social:
        return 'Social & Chat';
      case SoftwareCategory.gaming:
        return 'Gaming';
    }
  }
}
