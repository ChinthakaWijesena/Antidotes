import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme_scope.dart';
import '../../../../core/services/app_startup_service.dart';
import '../../../auto_updater/presentation/controllers/auto_updater_controller.dart';
import '../../../auto_updater/presentation/widgets/app_update_card.dart';
import '../../../windows_settings/presentation/widgets/theme_mode_card.dart';
import '../../../windows_settings/presentation/widgets/app_behavior_card.dart';

/// Dedicated App Settings Screen for Antidotes software preferences:
/// - Software updates check & version info
/// - Windows startup & system tray behavior
/// - Theme & appearance toggle
/// - About software details
class AppSettingsScreen extends StatefulWidget {
  final AutoUpdaterController updaterController;
  final bool? initialStartupEnabled;

  const AppSettingsScreen({
    super.key,
    required this.updaterController,
    this.initialStartupEnabled,
  });

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  bool _isStartupEnabled = false;
  bool _isLoadingStartup = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialStartupEnabled != null) {
      _isStartupEnabled = widget.initialStartupEnabled!;
      _isLoadingStartup = false;
    } else {
      _loadStartupStatus();
    }
  }

  Future<void> _loadStartupStatus() async {
    final enabled = await AppStartupService.isStartupEnabled();
    if (mounted) {
      setState(() {
        _isStartupEnabled = enabled;
        _isLoadingStartup = false;
      });
    }
  }

  Future<void> _toggleStartup(bool enable) async {
    final success = await AppStartupService.setStartupEnabled(enable);
    if (success && mounted) {
      setState(() => _isStartupEnabled = enable);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enable
                ? 'Antidotes registered to start minimized on Windows startup.'
                : 'Antidotes removed from Windows startup.',
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeScope.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Screen Header
            _buildHeader(),
            const SizedBox(height: 20),

            // 1. Antidotes Updates Card
            AppUpdateCard(
              controller: widget.updaterController,
            ),
            const SizedBox(height: 16),

            // 2. Startup & System Tray Behavior Card
            if (!_isLoadingStartup)
              AppBehaviorCard(
                isStartupEnabled: _isStartupEnabled,
                onStartupChanged: _toggleStartup,
              ),
            const SizedBox(height: 16),

            // 3. Theme Mode Card (Dark / Light)
            ThemeModeCard(
              isLightMode: !theme.isDarkMode,
              onThemeChanged: (isLight) async {
                await theme.setDarkMode(!isLight);
                if (mounted) setState(() {});
              },
            ),
            const SizedBox(height: 16),

            // 4. About Antidotes Card
            _buildAboutCard(),
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
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.settings_suggest_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Settings & Preferences',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Manage Antidotes software updates, system tray behavior, and theme appearance',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAboutCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.surfaceBorder,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Image.asset(
                'assets/icons/app_logo.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.shield_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Antidotes PC Optimizer',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'v1.1.0',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Engineered for maximum Windows performance, privacy & system maintenance. Connected to official GitHub Releases.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
