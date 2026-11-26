import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/boost_stats_model.dart';
import '../controllers/game_booster_controller.dart';

/// Modern top dashboard panel showing real-time CPU %, RAM %, GPU %, and active Boost State.
class LiveStatsPanel extends StatelessWidget {
  final BoostStats stats;
  final BoosterState state;
  final String? activeGameName;

  const LiveStatsPanel({
    super.key,
    required this.stats,
    required this.state,
    this.activeGameName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.speed_rounded, color: AppColors.accent, size: 22),
              const SizedBox(width: 10),
              Text(
                'LIVE SYSTEM TELEMETRY',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              const Spacer(),
              _buildStateBadge(),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.memory_rounded,
                  label: 'CPU USAGE',
                  value: '${stats.cpuUsagePercent.toStringAsFixed(1)}%',
                  progress: stats.cpuUsagePercent / 100.0,
                  accentColor: _getColorForPercent(stats.cpuUsagePercent),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.storage_rounded,
                  label: 'RAM LOAD',
                  value: '${stats.ramUsagePercent.toStringAsFixed(1)}%',
                  subvalue: '${stats.ramUsedGb.toStringAsFixed(1)} / ${stats.ramTotalGb.toStringAsFixed(1)} GB',
                  progress: stats.ramUsagePercent / 100.0,
                  accentColor: _getColorForPercent(stats.ramUsagePercent),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.videogame_asset_rounded,
                  label: 'GPU ACTIVITY',
                  value: stats.gpuUsageDisplay,
                  progress: stats.gpuUsageDisplay.contains('%')
                      ? (double.tryParse(stats.gpuUsageDisplay.replaceAll('%', '')) ?? 0) / 100.0
                      : 0.5,
                  accentColor: Colors.deepPurpleAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStateBadge() {
    Color bg;
    Color fg;
    String text;

    switch (state) {
      case BoosterState.boosted:
        bg = Colors.green.withValues(alpha: 0.2);
        fg = Colors.greenAccent;
        text = activeGameName != null ? 'BOOSTED: $activeGameName' : 'GAME BOOSTED';
        break;
      case BoosterState.boosting:
        bg = Colors.amber.withValues(alpha: 0.2);
        fg = Colors.amberAccent;
        text = 'OPTIMIZING...';
        break;
      case BoosterState.reverting:
        bg = Colors.blue.withValues(alpha: 0.2);
        fg = Colors.lightBlueAccent;
        text = 'RESTORING...';
        break;
      case BoosterState.idle:
        bg = Colors.white.withValues(alpha: 0.08);
        fg = AppColors.textSecondary;
        text = 'STANDBY';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: fg,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String label,
    required String value,
    String? subvalue,
    required double progress,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: accentColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (subvalue != null) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    subvalue,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: AppColors.surfaceBorder,
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForPercent(double percent) {
    if (percent < 50) return Colors.greenAccent;
    if (percent < 80) return Colors.amberAccent;
    return Colors.redAccent;
  }
}
