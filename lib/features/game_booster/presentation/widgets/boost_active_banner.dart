import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/game_model.dart';
import '../../domain/session/boost_session.dart';

/// Banner shown when a game boost session is active, offering one-click restore.
class BoostActiveBanner extends StatelessWidget {
  final BoostSession session;
  final VoidCallback onRevert;

  const BoostActiveBanner({
    super.key,
    required this.session,
    required this.onRevert,
  });

  @override
  Widget build(BuildContext context) {
    final Game game = session.game;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accent.withValues(alpha: 0.25),
            Colors.deepPurple.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.rocket_launch_rounded, color: AppColors.accent, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${game.name} is currently Boosted!',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Power plan set to High Performance • Process priority elevated • Background apps paused',
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: onRevert,
            icon: const Icon(Icons.restore_rounded, size: 16),
            label: const Text('Restore System'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white10,
              foregroundColor: Colors.white,
              side: BorderSide(color: AppColors.surfaceBorder),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}
