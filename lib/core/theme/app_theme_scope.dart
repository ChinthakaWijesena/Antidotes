import 'package:flutter/material.dart';
import 'system_theme_controller.dart';

/// An InheritedWidget that provides the [SystemThemeController] down the widget tree.
/// Any widget calling [AppThemeScope.of(context)] will automatically rebuild whenever
/// the Windows system theme, dark/light mode, or accent color changes.
class AppThemeScope extends InheritedWidget {
  final SystemThemeController controller;

  const AppThemeScope({
    super.key,
    required this.controller,
    required super.child,
  });

  static SystemThemeController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppThemeScope>();
    assert(scope != null, 'No AppThemeScope found in context');
    return scope!.controller;
  }

  @override
  bool updateShouldNotify(AppThemeScope oldWidget) {
    return oldWidget.controller.isDarkMode != controller.isDarkMode ||
        oldWidget.controller.accentColor != controller.accentColor;
  }
}
