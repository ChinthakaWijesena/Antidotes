import 'package:flutter/material.dart';
import 'package:antidotes/core/constants/app_colors.dart';
import 'package:antidotes/features/windows_settings/presentation/controllers/windows_settings_controller.dart';
import 'package:antidotes/features/windows_settings/presentation/widgets/app_behavior_card.dart';
import 'package:antidotes/features/windows_settings/presentation/widgets/env_variables_card.dart';
import 'package:antidotes/features/windows_settings/presentation/widgets/performance_options_card.dart';
import 'package:antidotes/features/windows_settings/presentation/widgets/power_modes_card.dart';
import 'package:antidotes/features/windows_settings/presentation/widgets/theme_mode_card.dart';
import 'package:antidotes/features/windows_settings/presentation/widgets/virtual_memory_card.dart';

class WindowsSettingsScreen extends StatefulWidget {
  final WindowsSettingsController? controller;

  const WindowsSettingsScreen({super.key, this.controller});

  @override
  State<WindowsSettingsScreen> createState() => _WindowsSettingsScreenState();
}

class _WindowsSettingsScreenState extends State<WindowsSettingsScreen> {
  late final WindowsSettingsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? WindowsSettingsController();
    _controller.addListener(_onControllerUpdate);
    _controller.loadAllSettings();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Screen Header
                  _buildHeader(),
                  const SizedBox(height: 18),

                  // 0. Antidotes Startup & System Tray Behavior Card
                  AppBehaviorCard(
                    isStartupEnabled: _controller.isStartupEnabled,
                    onStartupChanged: _controller.toggleStartup,
                  ),
                  const SizedBox(height: 16),

                  // 1. Dark Mode / Light Mode Switch
                  ThemeModeCard(
                    isLightMode: _controller.isLightMode,
                    onThemeChanged: _controller.toggleThemeMode,
                  ),
                  const SizedBox(height: 16),

                  // 2. Performance Options
                  PerformanceOptionsCard(
                    currentPreset: _controller.performancePreset,
                    onPresetChanged: _controller.setPerformancePreset,
                    onOpenNativeOptions: _controller.service.openNativePerformanceOptions,
                  ),
                  const SizedBox(height: 16),

                  // 3. Power Modes Switch
                  PowerModesCard(
                    schemes: _controller.powerSchemes,
                    onSchemeSelected: _controller.setActivePowerScheme,
                    onOpenNativePower: _controller.service.openNativePowerOptions,
                  ),
                  const SizedBox(height: 16),

                  // 4. Virtual Memory with Recommendations
                  VirtualMemoryCard(
                    config: _controller.virtualMemoryConfig,
                    onConfigSave: _controller.updateVirtualMemory,
                    onOpenNativeVirtualMemory:
                        _controller.service.openNativeVirtualMemoryDialog,
                  ),
                  const SizedBox(height: 16),

                  // 5. Environment Variables Edit
                  EnvVariablesCard(
                    variables: _controller.filteredEnvVariables,
                    searchQuery: _controller.envSearchQuery,
                    filterTab: _controller.envFilterTab,
                    onSearchChanged: _controller.setEnvSearchQuery,
                    onTabChanged: _controller.setEnvFilterTab,
                    onSaveVariable: _controller.saveEnvVariable,
                    onDeleteVariable: _controller.deleteEnvVariable,
                    onOpenNativeEnv:
                        _controller.service.openNativeEnvironmentVariablesDialog,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Windows Settings & Tools',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'System theme toggle, visual performance options, power schemes, virtual memory & environment variables',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: _controller.loadAllSettings,
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Refresh Settings',
          color: AppColors.textSecondary,
        ),
      ],
    );
  }
}

