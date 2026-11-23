import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_theme_scope.dart';
import 'core/theme/system_theme_controller.dart';
import 'features/auth/data/services/auth_service.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/auth/presentation/screens/auth_gate.dart';
import 'features/navigation/presentation/screens/main_shell_screen.dart';
import 'features/profile/data/services/profile_service.dart';
import 'features/profile/presentation/controllers/profile_controller.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  // Admin elevation is handled by the Windows EXE manifest (requireAdministrator).
  // The manifest guarantees the process always starts elevated — no manual restart needed.

  // Initialize Firebase Cloud Services
  AuthController? authController;
  ProfileController? profileController;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    final authService = FirebaseAuthService();
    authController = AuthController(authService: authService);
    final profileService = FirestoreProfileService();
    profileController = ProfileController(profileService: profileService);
  } catch (e) {
    debugPrint('Firebase init notice: $e');
  }

  final themeController = SystemThemeController();
  await themeController.initialize();
  runApp(AntidotesApp(
    themeController: themeController,
    authController: authController,
    profileController: profileController,
  ));
}

class AntidotesApp extends StatelessWidget {
  final SystemThemeController themeController;
  final AuthController? authController;
  final ProfileController? profileController;

  const AntidotesApp({
    super.key,
    required this.themeController,
    this.authController,
    this.profileController,
  });

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
            home: (authController != null && profileController != null)
                ? AuthGate(
                    authController: authController!,
                    profileController: profileController!,
                  )
                : const MainShellScreen(),
          ),
        );
      },
    );
  }
}
