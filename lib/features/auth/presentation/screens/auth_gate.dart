import 'package:flutter/material.dart';
import 'package:antidotes/features/profile/presentation/controllers/profile_controller.dart';
import 'package:antidotes/features/navigation/presentation/screens/main_shell_screen.dart';
import '../controllers/auth_controller.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class AuthGate extends StatefulWidget {
  final AuthController authController;
  final ProfileController profileController;

  const AuthGate({
    super.key,
    required this.authController,
    required this.profileController,
  });

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _showRegister = false;

  @override
  void initState() {
    super.initState();
    // Bind initial user to profile controller
    widget.profileController.bindUser(widget.authController.currentUser);
    widget.authController.addListener(_onAuthChanged);
  }

  void _onAuthChanged() {
    widget.profileController.bindUser(widget.authController.currentUser);
  }

  @override
  void dispose() {
    widget.authController.removeListener(_onAuthChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.authController,
      builder: (context, _) {
        if (widget.authController.hasAccess) {
          return MainShellScreen(
            authController: widget.authController,
            profileController: widget.profileController,
          );
        }

        if (_showRegister) {
          return RegisterScreen(
            authController: widget.authController,
            onNavigateToLogin: () {
              setState(() {
                _showRegister = false;
              });
            },
            onGuestContinue: () {
              widget.authController.continueAsGuest();
            },
          );
        }

        return LoginScreen(
          authController: widget.authController,
          onNavigateToRegister: () {
            setState(() {
              _showRegister = true;
            });
          },
          onGuestContinue: () {
            widget.authController.continueAsGuest();
          },
        );
      },
    );
  }
}
