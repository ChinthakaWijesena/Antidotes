import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/navigation/presentation/screens/main_shell_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AntidotesApp());
}

class AntidotesApp extends StatelessWidget {
  const AntidotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Antidotes - PC Cleaner & Optimizer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainShellScreen(),
    );
  }
}
