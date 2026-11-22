import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/startup_app_item.dart';

class StartupAppTile extends StatelessWidget {
  final StartupAppItem item;
  final ValueChanged<bool> onToggle;

  const StartupAppTile({
    super.key,
    required this.item,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.isEnabled
              ? AppColors.primary.withValues(alpha: 0.25)
              : AppColors.surfaceBorder,
        ),
      ),
      child: Row(
        children: [
          // Letter or App Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: item.isEnabled
                  ? AppColors.primary.withValues(alpha: 0.12)
              : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: item.isEnabled
                    ? AppColors.primary.withValues(alpha: 0.3)
                    : AppColors.surfaceBorder,
              ),
            ),
            child: Center(
              child: Text(
                item.name.isNotEmpty ? item.name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: item.isEnabled ? AppColors.primary : AppColors.textMuted,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // App Name, Publisher & Command
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _buildLocationBadge(item.location),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      item.publisher,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('•', style: TextStyle(color: AppColors.textMuted)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        item.command,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Consolas',
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Startup Impact Badge
          const SizedBox(width: 14),
          _buildImpactBadge(item.impact),
          const SizedBox(width: 20),

          // On / Off Switch
          Switch(
            value: item.isEnabled,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
            inactiveThumbColor: AppColors.textMuted,
            inactiveTrackColor: AppColors.surfaceLight,
            onChanged: onToggle,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationBadge(String location) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Text(
        location,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildImpactBadge(StartupImpact impact) {
    Color color;
    String label;

    switch (impact) {
      case StartupImpact.high:
        color = AppColors.danger;
        label = 'High';
        break;
      case StartupImpact.medium:
        color = AppColors.warning;
        label = 'Medium';
        break;
      case StartupImpact.low:
        color = AppColors.success;
        label = 'Low';
        break;
      case StartupImpact.none:
        color = AppColors.textMuted;
        label = 'None';
        break;
      case StartupImpact.notMeasured:
        color = AppColors.textMuted;
        label = 'Not measured';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
