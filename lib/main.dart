import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_theme_scope.dart';
import 'core/theme/system_theme_controller.dart';
import 'features/navigation/presentation/screens/main_shell_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
