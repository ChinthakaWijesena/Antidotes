import 'package:flutter/material.dart';
import 'package:antidotes/core/constants/app_colors.dart';
import 'package:antidotes/features/windows_settings/data/models/power_scheme_item.dart';

class PowerModesCard extends StatelessWidget {
  final List<PowerSchemeItem> schemes;
  final ValueChanged<String> onSchemeSelected;
  final VoidCallback onOpenNativePower;

  const PowerModesCard({
    super.key,
    required this.schemes,
    required this.onSchemeSelected,
    required this.onOpenNativePower,
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
                  color: const Color(0xFFF57C00).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.bolt_rounded, color: Color(0xFFF57C00), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Windows Power Modes & Schemes',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Optimize CPU clock throttling, battery life and cooling profiles',
                      style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: onOpenNativePower,
                icon: const Icon(Icons.open_in_new_rounded, size: 14),
                label: const Text('Power Options'),
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
          if (schemes.isEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'No power schemes detected.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: schemes.map((scheme) => _buildSchemeChip(scheme)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildSchemeChip(PowerSchemeItem scheme) {
    final isActive = scheme.isActive;
    Color chipColor = const Color(0xFF0288D1);
    IconData icon = Icons.battery_charging_full_rounded;

    final lower = scheme.name.toLowerCase();
    if (lower.contains('perform') || lower.contains('turbo') || lower.contains('ultimate')) {
      chipColor = const Color(0xFFE53935);
      icon = Icons.rocket_launch_rounded;
    } else if (lower.contains('saver') || lower.contains('silent') || lower.contains('eco')) {
      chipColor = Colors.green;
      icon = Icons.eco_rounded;
    }

    return InkWell(
      onTap: () => onSchemeSelected(scheme.guid),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 195,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? chipColor.withValues(alpha: 0.12) : AppColors.surfaceLight.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? chipColor : AppColors.surfaceBorder,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: chipColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    scheme.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isActive ? chipColor : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: isActive ? chipColor : AppColors.surfaceBorder),
              ),
              child: Text(
                isActive ? 'ACTIVE' : 'SWITCH',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.white : AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
