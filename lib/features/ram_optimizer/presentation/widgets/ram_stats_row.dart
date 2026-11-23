import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/ram_snapshot.dart';

/// Row of stat chips: Total / Used / Available / Standby.
class RamStatsRow extends StatelessWidget {
  final RamSnapshot snapshot;
  const RamStatsRow({super.key, required this.snapshot});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Chip(label: 'TOTAL',     value: '${snapshot.totalMb} MB',    color: AppColors.textSecondary),
        _Chip(label: 'USED',      value: '${snapshot.usedMb} MB',      color: AppColors.danger),
        _Chip(label: 'AVAILABLE', value: '${snapshot.availableMb} MB', color: AppColors.success),
        _Chip(label: 'STANDBY',   value: '${snapshot.standbyMb} MB',   color: AppColors.warning),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Chip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
