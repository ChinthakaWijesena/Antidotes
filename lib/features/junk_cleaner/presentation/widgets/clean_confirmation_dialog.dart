import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/file_size_formatter.dart';
import '../../data/models/junk_category.dart';
import '../../data/models/junk_item.dart';
import '../../data/models/junk_pattern.dart';

class CleanConfirmationDialog extends StatefulWidget {
  final List<JunkCategory> categories;
  final VoidCallback onConfirm;

  const CleanConfirmationDialog({
    super.key,
    required this.categories,
    required this.onConfirm,
  });

  @override
  State<CleanConfirmationDialog> createState() => _CleanConfirmationDialogState();
}

class _CleanConfirmationDialogState extends State<CleanConfirmationDialog> {
  int get selectedBytes {
    var total = 0;
    for (final cat in widget.categories) {
      if (!cat.isSelected) continue;
      if (cat.isRecycleBin) {
        total += cat.totalBytes;
      } else {
        total += cat.items
            .where((i) => i.isSelected)
            .fold(0, (sum, i) => sum + i.sizeInBytes);
      }
    }
    return total;
  }

  int get selectedCount {
    var total = 0;
    for (final cat in widget.categories) {
      if (!cat.isSelected) continue;
      if (cat.isRecycleBin) {
        total += cat.fileCount;
      } else {
        total += cat.items.where((i) => i.isSelected).length;
      }
    }
    return total;
  }

  bool get hasCarefulOrRiskyFiles {
    for (final cat in widget.categories) {
      if (!cat.isSelected) continue;
      if (cat.isCareful) return true;
      if (cat.items.any((i) => i.isSelected && i.risk != PatternRisk.low)) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.surfaceBorder),
      ),
      child: Container(
        width: 620,
        height: 580,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.checklist_rounded,
                      color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Confirm Items to Clean',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Total: ${FileSizeFormatter.format(selectedBytes)} ($selectedCount items)',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (hasCarefulOrRiskyFiles) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.warning_amber_rounded,
                        color: AppColors.warning, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Some selected items contain System Update Caches or Logs. Please review before proceeding.',
                        style: TextStyle(
                          color: AppColors.warning,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            Text(
              'Selected Categories & Files preview:',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    for (final cat in widget.categories)
                      if (cat.isSelected &&
                          (cat.items.isNotEmpty || cat.isRecycleBin))
                        _buildCategoryGroup(cat),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: selectedBytes == 0
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          widget.onConfirm();
                        },
                  icon: const Icon(Icons.delete_forever_rounded, size: 18),
                  label: Text(
                      'Clean Now (${FileSizeFormatter.format(selectedBytes)})'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGroup(JunkCategory cat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(cat.icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  cat.title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                FileSizeFormatter.format(cat.totalBytes),
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        if (!cat.isRecycleBin)
          ...cat.items.take(30).map((item) => _buildItemRow(cat, item)),
        const Divider(height: 16),
      ],
    );
  }

  Widget _buildItemRow(JunkCategory cat, JunkItem item) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, top: 2, bottom: 2),
      child: Row(
        children: [
          Checkbox(
            value: item.isSelected,
            activeColor: AppColors.primary,
            checkColor: AppColors.background,
            visualDensity: VisualDensity.compact,
            onChanged: (val) {
              setState(() {
                item.isSelected = val ?? false;
              });
            },
          ),
          Expanded(
            child: Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Consolas',
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            FileSizeFormatter.format(item.sizeInBytes),
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
