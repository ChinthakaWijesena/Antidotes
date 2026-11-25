import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/file_size_formatter.dart';
import '../../data/models/browser_clean_item.dart';
import '../../data/models/browser_profile_group.dart';
import '../../data/models/browser_type.dart';

class BrowserCard extends StatefulWidget {
  final BrowserProfileGroup group;
  final Function(String itemId) onItemToggle;
  final Function(bool selectAll) onGroupToggle;
  final VoidCallback onCloseBrowser;
  final bool isInteractive;

  const BrowserCard({
    super.key,
    required this.group,
    required this.onItemToggle,
    required this.onGroupToggle,
    required this.onCloseBrowser,
    this.isInteractive = true,
  });

  @override
  State<BrowserCard> createState() => _BrowserCardState();
}

class _BrowserCardState extends State<BrowserCard> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final brandColor = _getBrowserBrandColor(group.type);
    final hasJunk = group.totalSizeBytes > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: group.isAnySelected && hasJunk
              ? AppColors.primary.withValues(alpha: 0.35)
              : AppColors.surfaceBorder,
        ),
      ),
      child: Column(
        children: [
          // Header Row
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // Group Select All Checkbox
                  Checkbox(
                    value: group.isAllSelected
                        ? true
                        : (group.isAnySelected ? null : false),
                    tristate: true,
                    activeColor: AppColors.primary,
                    checkColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    onChanged: widget.isInteractive && group.isInstalled
                        ? (val) {
                            widget.onGroupToggle(val ?? false);
                          }
                        : null,
                  ),
                  const SizedBox(width: 8),

                  // Browser Brand Icon
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: brandColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: brandColor.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Icon(
                      _getBrowserIcon(group.type),
                      color: brandColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Browser Name & Badges
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              group.name,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (!group.isInstalled) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Not Installed',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ] else if (group.isRunning) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: AppColors.warning.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.circle,
                                        size: 7, color: AppColors.warning),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'Running',
                                      style: TextStyle(
                                        color: AppColors.warning,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          group.isInstalled
                              ? '${group.totalFiles} items detected across ${group.items.length} cleaning categories'
                              : 'No browser profile found on this system',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Action Buttons / Stats
                  if (group.isInstalled && group.isRunning) ...[
                    OutlinedButton.icon(
                      onPressed: widget.isInteractive ? widget.onCloseBrowser : null,
                      icon: const Icon(Icons.close_rounded, size: 14),
                      label: const Text('Close Browser'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.warning,
                        side: BorderSide(
                          color: AppColors.warning.withValues(alpha: 0.5),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        textStyle: const TextStyle(fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],

                  // Size Label
                  Text(
                    FileSizeFormatter.format(group.totalSizeBytes),
                    style: TextStyle(
                      color: hasJunk ? AppColors.textPrimary : AppColors.textMuted,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Expand Icon
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Collapsible Items List
          if (_isExpanded && group.isInstalled) ...[
            Divider(height: 1, color: AppColors.surfaceBorder),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                children: group.items.map((item) {
                  return _buildItemRow(item, brandColor);
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemRow(BrowserCleanItem item, Color brandColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: widget.isInteractive
            ? () => widget.onItemToggle(item.id)
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              Checkbox(
                value: item.isSelected,
                activeColor: AppColors.primary,
                checkColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                onChanged: widget.isInteractive
                    ? (_) => widget.onItemToggle(item.id)
                    : null,
              ),
              const SizedBox(width: 8),
              Icon(
                _getCategoryIcon(item.category),
                size: 16,
                color: item.category == BrowserCleanCategory.cache
                    ? brandColor
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (item.warning.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Tooltip(
                            message: item.warning,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Caution',
                                style: TextStyle(
                                  color: AppColors.warning,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      item.description,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                item.sizeBytes > 0
                    ? FileSizeFormatter.format(item.sizeBytes)
                    : (item.fileCount > 0 ? '${item.fileCount} files' : '0 B'),
                style: TextStyle(
                  color: item.sizeBytes > 0
                      ? AppColors.textPrimary
                      : AppColors.textMuted,
                  fontSize: 12,
                  fontWeight:
                      item.sizeBytes > 0 ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getBrowserBrandColor(BrowserType type) {
    switch (type) {
      case BrowserType.chrome:
        return const Color(0xFF4285F4);
      case BrowserType.edge:
        return const Color(0xFF0078D7);
      case BrowserType.firefox:
        return const Color(0xFFFF7139);
      case BrowserType.opera:
        return const Color(0xFFFF1B2D);
      case BrowserType.operaGx:
        return const Color(0xFFFA1E4E);
      case BrowserType.brave:
        return const Color(0xFFFF5000);
      case BrowserType.internetExplorer:
        return const Color(0xFF0076D6);
    }
  }

  IconData _getBrowserIcon(BrowserType type) {
    switch (type) {
      case BrowserType.chrome:
      case BrowserType.edge:
      case BrowserType.brave:
      case BrowserType.opera:
      case BrowserType.operaGx:
        return Icons.language_rounded;
      case BrowserType.firefox:
        return Icons.local_fire_department_rounded;
      case BrowserType.internetExplorer:
        return Icons.explore_rounded;
    }
  }

  IconData _getCategoryIcon(BrowserCleanCategory category) {
    switch (category) {
      case BrowserCleanCategory.cache:
        return Icons.memory_rounded;
      case BrowserCleanCategory.history:
        return Icons.history_rounded;
      case BrowserCleanCategory.cookies:
        return Icons.cookie_rounded;
      case BrowserCleanCategory.downloads:
        return Icons.download_rounded;
      case BrowserCleanCategory.forms:
        return Icons.password_rounded;
      case BrowserCleanCategory.sessions:
        return Icons.tab_rounded;
    }
  }
}
