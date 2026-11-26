import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_icon_widget.dart';
import '../../data/models/game_model.dart';

/// Card tile representing a single game in the library.
class GameCard extends StatelessWidget {
  final Game game;
  final bool isCurrentlyBoosted;
  final VoidCallback onLaunch;
  final VoidCallback onBoost;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const GameCard({
    super.key,
    required this.game,
    required this.isCurrentlyBoosted,
    required this.onLaunch,
    required this.onBoost,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrentlyBoosted ? AppColors.accent : AppColors.surfaceBorder,
          width: isCurrentlyBoosted ? 1.5 : 1.0,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIconWidget(
                name: game.name,
                iconCachePath: game.iconCachePath,
                iconPath: game.exePath,
                fallbackIcon: Icons.sports_esports_rounded,
                size: 40,
                borderRadius: 8,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.name,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      game.exeFileName,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, size: 18, color: AppColors.textSecondary),
                color: AppColors.surface,
                onSelected: (val) {
                  if (val == 'edit') onEdit();
                  if (val == 'delete') onDelete();
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.tune_rounded, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Text('Configure Boost', style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                        SizedBox(width: 8),
                        Text('Remove Game', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          // Action toggles badges summary
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              if (game.switchPowerPlan)
                _buildOptionBadge(Icons.bolt_rounded, 'High Perf'),
              if (game.raisePriority)
                _buildOptionBadge(Icons.priority_high_rounded, game.targetPriority.label),
              if (game.closeBackgroundApps)
                _buildOptionBadge(Icons.close_rounded, 'Close Apps'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onLaunch,
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('Play & Boost'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onBoost,
                tooltip: isCurrentlyBoosted ? 'Boosted' : 'Boost Now (without launch)',
                icon: Icon(
                  isCurrentlyBoosted ? Icons.check_circle_rounded : Icons.rocket_launch_rounded,
                  color: isCurrentlyBoosted ? Colors.greenAccent : AppColors.textSecondary,
                  size: 20,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.background,
                  side: BorderSide(color: AppColors.surfaceBorder),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: AppColors.accent),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
