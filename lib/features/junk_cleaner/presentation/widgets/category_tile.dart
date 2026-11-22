import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/file_size_formatter.dart';
import '../../data/models/junk_category.dart';
import '../../data/models/junk_item.dart';
import '../../data/models/junk_pattern.dart';

class CategoryTile extends StatefulWidget {
  final JunkCategory category;
  final VoidCallback onToggle;
  final Function(JunkItem item)? onItemToggle;
  final bool isInteractive;

  const CategoryTile({
    super.key,
    required this.category,
    required this.onToggle,
    this.onItemToggle,
    this.isInteractive = true,
  });

  @override
  State<CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<CategoryTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final cat = widget.category;
    final hasFiles = cat.items.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: cat.isSelected && (hasFiles || cat.isRecycleBin)
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.surfaceBorder,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Selection checkbox
                Checkbox(
                  value: cat.isSelected,
                  activeColor: AppColors.primary,
                  checkColor: AppColors.background,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  onChanged: widget.isInteractive ? (_) => widget.onToggle() : null,
                ),
                const SizedBox(width: 8),

                // Category Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cat.isCareful
                        ? AppColors.warning.withValues(alpha: 0.12)
                        : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    cat.icon,
                    color: cat.isCareful ? AppColors.warning : AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),

                // Title & Description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              cat.title,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (cat.isCareful) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Careful',
                                style: TextStyle(
                                  color: AppColors.warning,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        cat.description,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // File count & size badges
                if (cat.isScanning)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (cat.isCleaned)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Cleaned',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        FileSizeFormatter.format(cat.totalBytes),
                        style: TextStyle(
                          color: cat.totalBytes > 0
                              ? AppColors.textPrimary
                              : AppColors.textMuted,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        cat.isRecycleBin
                            ? '${cat.fileCount} items'
                            : '${cat.fileCount} files',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],

                // Expand button to view files
                if (hasFiles && !cat.isRecycleBin) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                  ),
                ],
              ],
            ),
          ),

          // File items preview list when expanded
          if (_isExpanded && hasFiles && !cat.isRecycleBin) ...[
            const Divider(height: 1),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              color: AppColors.surfaceLight.withValues(alpha: 0.25),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.all(12),
                itemCount: cat.items.length > 50 ? 50 : cat.items.length,
                separatorBuilder: (context, index) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final item = cat.items[index];
                  return Row(
                    children: [
                      Checkbox(
                        value: item.isSelected,
                        activeColor: AppColors.primary,
                        checkColor: AppColors.background,
                        visualDensity: VisualDensity.compact,
                        onChanged: widget.isInteractive
                            ? (_) {
                                setState(() {
                                  item.isSelected = !item.isSelected;
                                });
                                widget.onItemToggle?.call(item);
                              }
                            : null,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontFamily: 'Consolas',
                          ),
                        ),
                      ),
                      if (item.risk != PatternRisk.low) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: item.risk == PatternRisk.high
                                ? AppColors.danger.withValues(alpha: 0.2)
                                : AppColors.warning.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.risk == PatternRisk.high ? 'High Risk' : 'Medium',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: item.risk == PatternRisk.high
                                  ? AppColors.danger
                                  : AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 12),
                      Text(
                        FileSizeFormatter.format(item.sizeInBytes),
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
