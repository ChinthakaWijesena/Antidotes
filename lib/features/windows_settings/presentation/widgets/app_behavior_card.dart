import 'package:flutter/material.dart';
import 'package:antidotes/core/constants/app_colors.dart';

class AppBehaviorCard extends StatelessWidget {
  final bool isStartupEnabled;
  final ValueChanged<bool> onStartupChanged;

  const AppBehaviorCard({
    super.key,
    required this.isStartupEnabled,
    required this.onStartupChanged,
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
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.rocket_launch_rounded,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Antidotes Startup & System Tray',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Launch Antidotes on Windows boot & keep running silently in System Tray overflow menu',
                      style:
                          TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              // Switch
              Row(
                children: [
                  Icon(
                    isStartupEnabled
                        ? Icons.check_circle_rounded
                        : Icons.power_settings_new_rounded,
                    size: 18,
                    color: isStartupEnabled
                        ? AppColors.success
                        : AppColors.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isStartupEnabled ? 'Start with Windows' : 'Disabled',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isStartupEnabled
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Switch(
                    value: isStartupEnabled,
                    activeTrackColor: AppColors.primary,
                    onChanged: onStartupChanged,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildInfoTile(
                  icon: Icons.vertical_align_top_rounded,
                  title: 'System Tray Overflow Menu',
                  description:
                      'Runs in the taskbar overflow (^) area. Closing the window minimizes to tray instead of exiting.',
                  statusText: 'ACTIVE',
                  statusColor: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoTile(
                  icon: Icons.flash_on_rounded,
                  title: 'Silent Boot Optimizer',
                  description: isStartupEnabled
                      ? 'Starts with --minimized to optimize memory & startup without desktop popup clutter.'
                      : 'Enable "Start with Windows" above to maintain real-time background PC optimization.',
                  statusText: isStartupEnabled ? 'ENABLED' : 'OFF',
                  statusColor:
                      isStartupEnabled ? AppColors.success : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String description,
    required String statusText,
    required Color statusColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceBorder.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: statusColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
