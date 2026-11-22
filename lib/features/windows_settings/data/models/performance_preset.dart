enum PerformancePreset {
  letWindowsChoose,
  bestAppearance,
  bestPerformance,
  custom;

  String get displayName {
    switch (this) {
      case PerformancePreset.letWindowsChoose:
        return 'Let Windows choose what\'s best';
      case PerformancePreset.bestAppearance:
        return 'Adjust for best appearance';
      case PerformancePreset.bestPerformance:
        return 'Adjust for best performance';
      case PerformancePreset.custom:
        return 'Custom';
    }
  }

  String get description {
    switch (this) {
      case PerformancePreset.letWindowsChoose:
        return 'Balanced default settings recommended by Microsoft Windows.';
      case PerformancePreset.bestAppearance:
        return 'Enables all animations, drop shadows, and visual effects.';
      case PerformancePreset.bestPerformance:
        return 'Turns off unnecessary animations and effects for max FPS, speed & responsiveness.';
      case PerformancePreset.custom:
        return 'Individually customized visual effects list.';
    }
  }

  int get regValue {
    switch (this) {
      case PerformancePreset.letWindowsChoose:
        return 0;
      case PerformancePreset.bestAppearance:
        return 1;
      case PerformancePreset.bestPerformance:
        return 2;
      case PerformancePreset.custom:
        return 3;
    }
  }
}

