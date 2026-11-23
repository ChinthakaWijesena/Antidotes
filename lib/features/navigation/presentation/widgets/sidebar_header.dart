import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Top header of the Antidotes sidebar displaying the app icon, title and category badge.
class SidebarHeader extends StatelessWidget {
  final VoidCallback? onToggleCollapse;

  const SidebarHeader({
    super.key,
    this.onToggleCollapse,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/icons/app_logo.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.shield_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Antidotes',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'PC OPTIMIZER',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (onToggleCollapse != null)
                IconButton(
                  icon: const Icon(Icons.menu_open_rounded, size: 18),
                  tooltip: 'Collapse sidebar',
                  color: AppColors.textMuted,
                  onPressed: onToggleCollapse,
                  splashRadius: 18,
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Divider(height: 1),
        const SizedBox(height: 10),
      ],
    );
  }
}
