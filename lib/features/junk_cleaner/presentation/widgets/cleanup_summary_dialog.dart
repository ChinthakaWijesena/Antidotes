import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/file_size_formatter.dart';
import '../../data/services/junk_cleaner_service.dart';

class CleanupSummaryDialog extends StatelessWidget {
  final CleanupResult result;

  const CleanupSummaryDialog({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.surfaceBorder),
      ),
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: AppColors.success, size: 48),
            ),
            const SizedBox(height: 18),
            const Text(
              'Cleanup Complete!',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You reclaimed ${FileSizeFormatter.format(result.bytesFreed)} of disk space.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _SummaryRow(
                    label: 'Files Removed',
                    value: '${result.filesDeleted} files',
                  ),
                  const SizedBox(height: 10),
                  _SummaryRow(
                    label: 'Space Recovered',
                    value: FileSizeFormatter.format(result.bytesFreed),
                    valueColor: AppColors.primary,
                  ),
                  if (result.filesFailed > 0) ...[
                    const SizedBox(height: 10),
                    _SummaryRow(
                      label: 'In-Use / Skipped',
                      value: '${result.filesFailed} files',
                      valueColor: AppColors.warning,
                    ),
                  ],
                  const SizedBox(height: 10),
                  _SummaryRow(
                    label: 'Time Taken',
                    value: '${(result.duration.inMilliseconds / 1000).toStringAsFixed(1)} s',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
