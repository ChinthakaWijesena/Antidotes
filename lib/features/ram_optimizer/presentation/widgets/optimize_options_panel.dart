import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/ram_optimize_options.dart';

/// Shows the five cleaning operations as toggleable rows.
/// Each row shows icon, name, description, an ADMIN badge where needed,
/// and a switch on the right.
class OptimizeOptionsPanel extends StatelessWidget {
  final RamOptimizeOptions options;
  final ValueChanged<RamOperation> onToggle;

  const OptimizeOptionsPanel({
    super.key,
    required this.options,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Icon(Icons.tune_rounded, color: AppColors.primary, size: 16),
                const SizedBox(width: 8),
                Text(
                  'OPERATIONS',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
                const Spacer(),
                // Admin needed indicator
                if (options.requiresAdmin)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shield_rounded,
                            color: AppColors.warning, size: 11),
                        const SizedBox(width: 4),
                        Text(
                          'UAC REQUIRED',
                          style: TextStyle(
                            color: AppColors.warning,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // ── Divider ───────────────────────────────────────────────────
          Divider(color: AppColors.surfaceBorder, height: 1),

          // ── Operation rows ────────────────────────────────────────────
          ...RamOperation.values.asMap().entries.map((entry) {
            final idx = entry.key;
            final op  = entry.value;
            final isLast = idx == RamOperation.values.length - 1;
            return _OperationRow(
              op: op,
              isSelected: options.isSelected(op),
              onToggle: () => onToggle(op),
              showDivider: !isLast,
            );
          }),
        ],
      ),
    );
  }
}

class _OperationRow extends StatelessWidget {
  final RamOperation op;
  final bool isSelected;
  final VoidCallback onToggle;
  final bool showDivider;

  const _OperationRow({
    required this.op,
    required this.isSelected,
    required this.onToggle,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = isSelected ? AppColors.primary : AppColors.textMuted;

    return Column(
      children: [
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
            child: Row(
              children: [
                // Icon box
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: accentColor.withValues(alpha: 0.25), width: 1),
                  ),
                  child: Icon(op.icon, color: accentColor, size: 18),
                ),
                const SizedBox(width: 14),

                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            op.displayName,
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (op.requiresAdmin) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                    color: AppColors.warning.withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                'ADMIN',
                                style: TextStyle(
                                  color: AppColors.warning,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        op.description,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // Toggle switch
                Switch(
                  value: isSelected,
                  onChanged: (_) => onToggle(),
                  activeThumbColor: AppColors.primary,
                  trackColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppColors.primary.withValues(alpha: 0.3);
                    }
                    return AppColors.surfaceBorder;
                  }),
                  thumbColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppColors.primary;
                    }
                    return AppColors.textMuted;
                  }),
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            color: AppColors.surfaceBorder,
            height: 1,
            indent: 20,
            endIndent: 20,
          ),
      ],
    );
  }
}
