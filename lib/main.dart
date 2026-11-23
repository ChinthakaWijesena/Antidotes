import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_theme_scope.dart';
import 'core/theme/system_theme_controller.dart';
import 'core/utils/admin_helper.dart';
import 'features/navigation/presentation/screens/main_shell_screen.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // In release mode (when opened by user), automatically elevate to Administrator
  if (Platform.isWindows && kReleaseMode && !args.contains('--no-elevate')) {
    final isAdmin = await AdminHelper.isRunningAsAdmin();
    if (!isAdmin) {
      await AdminHelper.restartAsAdmin();
      return;
    }
  }

  final themeController = SystemThemeController();
  await themeController.initialize();
  runApp(AntidotesApp(themeController: themeController));
}

class AntidotesApp extends StatelessWidget {
  final SystemThemeController themeController;

  const AntidotesApp({super.key, required this.themeController});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) {
        return AppThemeScope(
          controller: themeController,
          child: MaterialApp(
            title: 'Antidotes - PC Cleaner & Optimizer',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.buildLightTheme(themeController.accentColor),
            darkTheme: AppTheme.buildDarkTheme(themeController.accentColor),
            themeMode:
                themeController.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const MainShellScreen(),
          ),
        );
      },
    );
  }
}
