import 'package:flutter/material.dart';
import 'package:antidotes/core/constants/app_colors.dart';
import 'package:antidotes/core/theme/app_theme_scope.dart';

class ThemeModeCard extends StatelessWidget {
  final bool isLightMode;
  final ValueChanged<bool> onThemeChanged;

  const ThemeModeCard({
    super.key,
    required this.isLightMode,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF673AB7).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.palette_rounded, color: Color(0xFF673AB7), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Windows Theme Mode (Dark / Light)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Toggles system-wide Windows app & taskbar themes in real-time',
                      style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              // Switch
              Row(
                children: [
                  Icon(
                    isLightMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    size: 18,
                    color: isLightMode ? const Color(0xFFF57C00) : const Color(0xFF3F51B5),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isLightMode ? 'Light Mode' : 'Dark Mode',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Switch(
                    value: isLightMode,
                    activeTrackColor: const Color(0xFFF57C00),
                    onChanged: (val) {
                      onThemeChanged(val);
                      AppThemeScope.of(context).setDarkMode(!val);
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildThemePreview(
                  title: 'Dark Mode (Recommended)',
                  subtitle: 'Reduces eye strain, saves laptop OLED power',
                  isSelected: !isLightMode,
                  onTap: () {
                    onThemeChanged(false);
                    AppThemeScope.of(context).setDarkMode(true);
                  },
                  icon: Icons.nightlight_round,
                  bg: const Color(0xFF1E222D),
                  textColor: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildThemePreview(
                  title: 'Light Mode',
                  subtitle: 'Clean high contrast for bright daylight environments',
                  isSelected: isLightMode,
                  onTap: () {
                    onThemeChanged(true);
                    AppThemeScope.of(context).setDarkMode(false);
                  },
                  icon: Icons.wb_sunny_rounded,
                  bg: const Color(0xFFF3F4F6),
                  textColor: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemePreview({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    required IconData icon,
    required Color bg,
    required Color textColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF2979FF) : AppColors.surfaceBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: textColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: textColor.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: Color(0xFF2979FF), size: 18),
          ],
        ),
      ),
    );
  }
}
