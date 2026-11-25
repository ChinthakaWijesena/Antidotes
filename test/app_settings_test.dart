import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:antidotes/core/theme/app_theme_scope.dart';
import 'package:antidotes/core/theme/system_theme_controller.dart';
import 'package:antidotes/features/app_settings/presentation/screens/app_settings_screen.dart';
import 'package:antidotes/features/auto_updater/presentation/controllers/auto_updater_controller.dart';
import 'auto_updater_test.dart';

void main() {
  testWidgets('AppSettingsScreen renders updates card, theme card and about info', (tester) async {
    final themeController = SystemThemeController();
    final updaterController = AutoUpdaterController(
      service: FakeAutoUpdaterService(),
    );

    await tester.pumpWidget(
      AppThemeScope(
        controller: themeController,
        child: MaterialApp(
          home: AppSettingsScreen(
            updaterController: updaterController,
            initialStartupEnabled: false,
          ),
        ),
      ),
    );

    expect(find.text('Settings & Preferences'), findsOneWidget);
    expect(find.text('Antidotes Updates'), findsOneWidget);
    expect(find.text('Antidotes PC Optimizer'), findsOneWidget);
    expect(find.text('v1.0.2'), findsWidgets);
  });
}
