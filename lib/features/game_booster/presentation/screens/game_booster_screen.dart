import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/game_model.dart';
import '../controllers/game_booster_controller.dart';
import '../widgets/add_game_dialog.dart';
import '../widgets/boost_active_banner.dart';
import '../widgets/closable_apps_dialog.dart';
import '../widgets/game_card.dart';
import '../widgets/live_stats_panel.dart';

/// Main screen for the Game Booster feature in Antidotes.
class GameBoosterScreen extends StatefulWidget {
  const GameBoosterScreen({super.key});

  @override
  State<GameBoosterScreen> createState() => _GameBoosterScreenState();
}

class _GameBoosterScreenState extends State<GameBoosterScreen> {
  late final GameBoosterController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GameBoosterController();
    _controller.init();
    _controller.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  void _openAddGameDialog() {
    showDialog(
      context: context,
      builder: (context) => AddGameDialog(
        onPickExe: _controller.pickGameExecutable,
        onSave: _controller.addGame,
      ),
    );
  }

  void _openEditGameDialog(Game game) {
    showDialog(
      context: context,
      builder: (context) => AddGameDialog(
        existingGame: game,
        onPickExe: _controller.pickGameExecutable,
        onSave: _controller.updateGame,
      ),
    );
  }

  void _openClosableAppsDialog() {
    showDialog(
      context: context,
      builder: (context) => ClosableAppsDialog(controller: _controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    final games = _controller.games;
    final activeSession = _controller.activeSession;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 750;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Game Booster',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Maximize gaming performance, lower latency, prioritize CPU scheduling, and free memory.',
                                style: TextStyle(
                                  color: AppColors.textSecondary.withValues(alpha: 0.9),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isCompact) ...[
                          // Auto-Boost Switch
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.surfaceBorder),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.auto_mode_rounded, size: 16, color: AppColors.accent),
                                const SizedBox(width: 8),
                                Text('Auto-Detect', style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 6),
                                Switch(
                                  value: _controller.isAutoWatcherEnabled,
                                  onChanged: _controller.toggleAutoWatcher,
                                  activeThumbColor: AppColors.accent,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Apps to Close button
                          OutlinedButton.icon(
                            onPressed: _openClosableAppsDialog,
                            icon: const Icon(Icons.tune_rounded, size: 16),
                            label: Text('Apps to Close (${_controller.selectedAppsToClose.length})'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              side: BorderSide(color: AppColors.surfaceBorder),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Add Game button
                          ElevatedButton.icon(
                            onPressed: _openAddGameDialog,
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Add Game'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (isCompact) ...[
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.surfaceBorder),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.auto_mode_rounded, size: 16, color: AppColors.accent),
                                const SizedBox(width: 8),
                                Text('Auto-Detect', style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 6),
                                Switch(
                                  value: _controller.isAutoWatcherEnabled,
                                  onChanged: _controller.toggleAutoWatcher,
                                  activeThumbColor: AppColors.accent,
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: _openClosableAppsDialog,
                            icon: const Icon(Icons.tune_rounded, size: 16),
                            label: Text('Apps to Close (${_controller.selectedAppsToClose.length})'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              side: BorderSide(color: AppColors.surfaceBorder),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _openAddGameDialog,
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Add Game'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            // Live Telemetry
            LiveStatsPanel(
              stats: _controller.stats,
              state: _controller.state,
              activeGameName: activeSession?.game.name,
            ),
            const SizedBox(height: 16),

            // Active Boost Banner
            if (_controller.isBoosted && activeSession != null) ...[
              BoostActiveBanner(
                session: activeSession,
                onRevert: _controller.revertBoost,
              ),
              const SizedBox(height: 20),
            ],

            // Game Library Header
            Row(
              children: [
                const Icon(Icons.sports_esports_rounded, color: AppColors.accent, size: 20),
                const SizedBox(width: 8),
                Text(
                  'GAME LIBRARY',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${games.length})',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Game Cards or Empty State
            if (games.isEmpty)
              _buildEmptyState()
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 340,
                  mainAxisExtent: 180,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                itemCount: games.length,
                itemBuilder: (context, index) {
                  final game = games[index];
                  final isThisBoosted = _controller.isBoosted && activeSession?.game.id == game.id;

                  return GameCard(
                    game: game,
                    isCurrentlyBoosted: isThisBoosted,
                    onLaunch: () => _controller.launchGame(game),
                    onBoost: () => isThisBoosted ? _controller.revertBoost() : _controller.manualBoost(game),
                    onEdit: () => _openEditGameDialog(game),
                    onDelete: () => _controller.removeGame(game.id),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.sports_esports_rounded, size: 40, color: AppColors.accent),
          ),
          const SizedBox(height: 16),
          Text(
            'Your Game Library is Empty',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add your favourite games to enable 1-click launch, automatic power tuning, and memory optimization.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _openAddGameDialog,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add Your First Game'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}
