import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:system_theme/system_theme.dart';
import 'package:antidotes/core/theme/app_theme_scope.dart';
import 'package:antidotes/core/theme/system_theme_controller.dart';
import 'package:antidotes/core/constants/app_colors.dart';

void main() {
  test('SystemTheme fallback is available', () {
    SystemTheme.fallbackColor = const Color(0xFF00D2C4);
    expect(SystemTheme.fallbackColor, const Color(0xFF00D2C4));
  });

  test('SystemThemeController setDarkMode updates isDarkMode and AppColors', () async {
    final controller = SystemThemeController();
    await controller.setDarkMode(false);
    expect(controller.isDarkMode, false);
    expect(AppColors.background, const Color(0xFFF1F5F9));

    await controller.setDarkMode(true);
    expect(controller.isDarkMode, true);
    expect(AppColors.background, const Color(0xFF0B0F19));
  });

  test('AppThemeScope updateShouldNotify detects theme changes accurately', () async {
    final controller = SystemThemeController();
    await controller.setDarkMode(true);

    final scopeOld = AppThemeScope(
      controller: controller,
      child: const SizedBox(),
    );

    await controller.setDarkMode(false);

    final scopeNew = AppThemeScope(
      controller: controller,
      child: const SizedBox(),
    );

    expect(scopeNew.updateShouldNotify(scopeOld), true);
  });
}
