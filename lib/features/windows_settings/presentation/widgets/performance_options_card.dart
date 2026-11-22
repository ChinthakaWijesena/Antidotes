import 'package:flutter/material.dart';
import 'package:antidotes/core/constants/app_colors.dart';
import 'package:antidotes/features/windows_settings/data/models/performance_preset.dart';

class PerformanceOptionsCard extends StatelessWidget {
  final PerformancePreset currentPreset;
  final ValueChanged<PerformancePreset> onPresetChanged;
  final VoidCallback onOpenNativeOptions;

  const PerformanceOptionsCard({
    super.key,
    required this.currentPreset,
    required this.onPresetChanged,
    required this.onOpenNativeOptions,
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
                  color: const Color(0xFF0288D1).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.speed_rounded, color: Color(0xFF0288D1), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Windows Performance & Visual Effects',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Control window animations, smooth scrolling, font smoothing and shadows',
                      style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: onOpenNativeOptions,
                icon: const Icon(Icons.open_in_new_rounded, size: 14),
                label: const Text('Advanced Options'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: BorderSide(color: AppColors.surfaceBorder),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 11.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Column(
            children: [
              _buildPresetTile(
                preset: PerformancePreset.bestPerformance,
                icon: Icons.flash_on_rounded,
                accentColor: Colors.amber,
              ),
              const SizedBox(height: 8),
              _buildPresetTile(
                preset: PerformancePreset.letWindowsChoose,
                icon: Icons.balance_rounded,
                accentColor: const Color(0xFF0288D1),
              ),
              const SizedBox(height: 8),
              _buildPresetTile(
                preset: PerformancePreset.bestAppearance,
                icon: Icons.auto_awesome_rounded,
                accentColor: const Color(0xFF9C27B0),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPresetTile({
    required PerformancePreset preset,
    required IconData icon,
    required Color accentColor,
  }) {
    final isSelected = currentPreset == preset;

    return InkWell(
      onTap: () => onPresetChanged(preset),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withValues(alpha: 0.08) : AppColors.surfaceLight.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? accentColor : AppColors.surfaceBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accentColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    preset.displayName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    preset.description,
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? accentColor : AppColors.textMuted,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accentColor,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

