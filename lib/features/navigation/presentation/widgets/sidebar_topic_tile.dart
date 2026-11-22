import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/nav_topic.dart';
import 'sidebar_sub_item.dart';

/// Renders a collapsible Topic header with count badge and animated subtopic children.
class SidebarTopicTile extends StatelessWidget {
  final NavTopic topic;
  final bool isExpanded;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final VoidCallback onToggleExpand;

  const SidebarTopicTile({
    super.key,
    required this.topic,
    required this.isExpanded,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onToggleExpand,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasSelectedChild =
        topic.items.any((item) => item.index == selectedIndex);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Topic Header Row
          InkWell(
            onTap: onToggleExpand,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              child: Row(
                children: [
                  Icon(
                    topic.icon,
                    size: 14,
                    color: hasSelectedChild
                        ? AppColors.primary
                        : AppColors.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      topic.title,
                      style: TextStyle(
                        color: hasSelectedChild
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  // Count pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.surfaceBorder,
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      '${topic.items.length}',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Animated Expand/Collapse Chevron
                  AnimatedRotation(
                    turns: isExpanded ? 0 : -0.25,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Subtopics List with vertical guide line
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 4),
              child: Stack(
                children: [
                  Positioned(
                    left: 17,
                    top: 4,
                    bottom: 8,
                    child: Container(
                      width: 1.5,
                      color: AppColors.surfaceBorder.withValues(alpha: 0.6),
                    ),
                  ),
                  Column(
                    children: topic.items.map((item) {
                      return SidebarSubItem(
                        item: item,
                        isSelected: selectedIndex == item.index,
                        onTap: () => onItemSelected(item.index),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
