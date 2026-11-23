import 'package:flutter/material.dart';
import 'package:antidotes/core/constants/app_colors.dart';
import 'package:antidotes/core/theme/app_theme_scope.dart';
import 'package:antidotes/features/browser_cleaner/presentation/screens/browser_cleaner_screen.dart';
import 'package:antidotes/features/hardware_monitor/presentation/screens/hardware_monitor_screen.dart';
import 'package:antidotes/features/junk_cleaner/presentation/screens/junk_cleaner_screen.dart';
import 'package:antidotes/features/software_installer/presentation/screens/software_installer_screen.dart';
import 'package:antidotes/features/software_uninstaller/presentation/screens/software_uninstaller_screen.dart';
import 'package:antidotes/features/startup_manager/presentation/screens/startup_manager_screen.dart';
import 'package:antidotes/features/windows_settings/presentation/screens/windows_settings_screen.dart';
import 'package:antidotes/features/dns_changer/presentation/screens/dns_changer_screen.dart';
import 'package:antidotes/features/speed_test/presentation/screens/speed_test_screen.dart';
import 'package:antidotes/features/ram_optimizer/presentation/screens/ram_optimizer_screen.dart';
import 'package:antidotes/features/storage_tools/presentation/screens/large_file_finder_screen.dart';
import 'package:antidotes/features/storage_tools/presentation/screens/duplicate_finder_screen.dart';
import 'package:antidotes/features/storage_tools/presentation/screens/file_shredder_screen.dart';
import 'package:antidotes/features/disk_health/presentation/screens/disk_health_screen.dart';
import 'package:antidotes/features/auth/presentation/controllers/auth_controller.dart';
import 'package:antidotes/features/profile/presentation/controllers/profile_controller.dart';
import '../widgets/app_sidebar.dart';

class MainShellScreen extends StatefulWidget {
  final AuthController? authController;
  final ProfileController? profileController;

  const MainShellScreen({
    super.key,
    this.authController,
    this.profileController,
  });

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _selectedNavIndex = 0;
  bool? _manuallyCollapsed;

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeScope.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 1050;
          final isCompact = _manuallyCollapsed ?? isNarrow;

          return Row(
            children: [
              // Left Sidebar Navigation (Full 255px or Compact 72px rail)
              AppSidebar(
                selectedIndex: _selectedNavIndex,
                isCompact: isCompact,
                onToggleCollapse: () {
                  setState(() {
                    _manuallyCollapsed = !isCompact;
                  });
                },
                onDestinationSelected: (index) {
                  setState(() {
                    _selectedNavIndex = index;
                  });
                },
                authController: widget.authController,
                profileController: widget.profileController,
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
                    SoftwareUninstallerScreen(
                      key: ValueKey(
                          'uninstaller_${theme.isDarkMode}_${theme.accentColor.toARGB32()}'),
                    ),
                    WindowsSettingsScreen(
                      key: ValueKey(
                          'windows_settings_${theme.isDarkMode}_${theme.accentColor.toARGB32()}'),
                    ),
                    DnsChangerScreen(
                      key: ValueKey(
                          'dns_changer_${theme.isDarkMode}_${theme.accentColor.toARGB32()}'),
                    ),
                    SpeedTestScreen(
                      key: ValueKey(
                          'speed_test_${theme.isDarkMode}_${theme.accentColor.toARGB32()}'),
                    ),
                    RamOptimizerScreen(
                      key: ValueKey(
                          'ram_optimizer_${theme.isDarkMode}_${theme.accentColor.toARGB32()}'),
                    ),
                    LargeFileFinderScreen(
                      key: ValueKey(
                          'large_file_${theme.isDarkMode}_${theme.accentColor.toARGB32()}'),
                    ),
                    DuplicateFinderScreen(
                      key: ValueKey(
                          'dup_finder_${theme.isDarkMode}_${theme.accentColor.toARGB32()}'),
                    ),
                    FileShredderScreen(
                      key: ValueKey(
                          'file_shredder_${theme.isDarkMode}_${theme.accentColor.toARGB32()}'),
                    ),
                    DiskHealthScreen(
                      key: ValueKey(
                          'disk_health_${theme.isDarkMode}_${theme.accentColor.toARGB32()}'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
