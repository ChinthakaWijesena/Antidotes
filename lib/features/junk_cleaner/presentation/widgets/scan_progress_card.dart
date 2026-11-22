import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class ScanProgressCard extends StatelessWidget {
  final String statusText;
  final String currentPath;
  final bool isCleaning;

  const ScanProgressCard({
    super.key,
    required this.statusText,
    required this.currentPath,
    this.isCleaning = false,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = isCleaning ? AppColors.warning : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: activeColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(activeColor),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                statusText,
                style: TextStyle(
                  color: activeColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              minHeight: 4,
              backgroundColor: AppColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(activeColor),
            ),
          ),
          if (currentPath.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              currentPath,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Consolas',
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
