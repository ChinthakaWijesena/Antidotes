import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/ram_boost_result.dart';
import '../../data/models/ram_optimize_options.dart';

/// Result banner shown after a boost completes.
/// Shows total MB freed + per-operation result rows.
class BoostResultBanner extends StatelessWidget {
  final RamBoostResult result;
  const BoostResultBanner({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final success = result.success;
    final freed   = result.freedMb;
    final color   = success ? AppColors.success : AppColors.danger;

    return AnimatedOpacity(
      opacity: 1,
      duration: const Duration(milliseconds: 400),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Summary row ────────────────────────────────────────────
            Row(
              children: [
                Icon(
                  success ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                  color: color,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        success
                            ? freed > 0
                                ? '$freed MB freed!'
                                : 'Boost complete!'
                            : 'Boost incomplete',
                        style: TextStyle(
                          color: color,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (result.errorMessage != null)
                        Text(
                          result.errorMessage!,
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 11),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            // ── Per-operation details ──────────────────────────────────
            if (result.operationResults.isNotEmpty) ...[
              const SizedBox(height: 12),
              Divider(color: color.withValues(alpha: 0.2), height: 1),
              const SizedBox(height: 10),
              ...result.operationResults.entries.map((e) {
                final op  = e.key;
                final msg = e.value;
                final isErr = msg.toLowerCase().startsWith('error');
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        isErr ? Icons.warning_amber_rounded : op.icon,
                        color: isErr ? AppColors.warning : AppColors.primary,
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '${op.displayName}: ',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(
                                text: msg,
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
