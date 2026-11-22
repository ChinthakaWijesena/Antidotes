import 'package:flutter/material.dart';
import 'package:antidotes/core/constants/app_colors.dart';
import 'package:antidotes/core/theme/app_theme_scope.dart';
import 'package:antidotes/features/browser_cleaner/presentation/screens/browser_cleaner_screen.dart';
import 'package:antidotes/features/hardware_monitor/presentation/screens/hardware_monitor_screen.dart';
import 'package:antidotes/features/junk_cleaner/presentation/screens/junk_cleaner_screen.dart';
import 'package:antidotes/features/software_installer/presentation/screens/software_installer_screen.dart';
import 'package:antidotes/features/startup_manager/presentation/screens/startup_manager_screen.dart';
import '../widgets/app_sidebar.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _selectedNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeScope.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Left Sidebar Navigation
          AppSidebar(
            selectedIndex: _selectedNavIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedNavIndex = index;
              });
            },
          ),

          // Main View Content
          Expanded(
            child: IndexedStack(
              index: _selectedNavIndex,
              children: [
                JunkCleanerScreen(
                  key: ValueKey(
                      'junk_${theme.isDarkMode}_${theme.accentColor.toARGB32()}'),
                ),
                StartupManagerScreen(
                  key: ValueKey(
                      'startup_${theme.isDarkMode}_${theme.accentColor.toARGB32()}'),
                ),
                BrowserCleanerScreen(
                  key: ValueKey(
                      'browser_${theme.isDarkMode}_${theme.accentColor.toARGB32()}'),
                ),
                HardwareMonitorScreen(
                  key: ValueKey(
                      'hardware_${theme.isDarkMode}_${theme.accentColor.toARGB32()}'),
                ),
                SoftwareInstallerScreen(
                  key: ValueKey(
                      'installer_${theme.isDarkMode}_${theme.accentColor.toARGB32()}'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
