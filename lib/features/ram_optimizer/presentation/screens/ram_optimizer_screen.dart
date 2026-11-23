import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme_scope.dart';
import '../../data/models/ram_snapshot.dart';
import '../controllers/ram_optimizer_controller.dart';
import '../widgets/ram_usage_meter.dart';
import '../widgets/boost_result_banner.dart';
import '../widgets/optimize_options_panel.dart';

class RamOptimizerScreen extends StatefulWidget {
  const RamOptimizerScreen({super.key});

  @override
  State<RamOptimizerScreen> createState() => _RamOptimizerScreenState();
}

class _RamOptimizerScreenState extends State<RamOptimizerScreen> {
  late final RamOptimizerController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = RamOptimizerController();
    _ctrl.addListener(_onCtrlUpdate);
    _ctrl.startMonitoring();
  }

  void _onCtrlUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onCtrlUpdate);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppThemeScope.of(context);
    final snap = _ctrl.snapshot;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              Expanded(
                child: snap == null
                    ? const Center(child: CircularProgressIndicator())
                    : _buildContent(snap),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Icon(Icons.memory_rounded, color: AppColors.primary, size: 24),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'RAM Optimizer',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'One-click memory clean — 5 operations, full control',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
        const Spacer(),
        // Live indicator
        if (_ctrl.boostState != RamBoostState.boosting)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: AppColors.success.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                      color: AppColors.success, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  'LIVE',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ── Scrollable body ───────────────────────────────────────────────────────
  Widget _buildContent(RamSnapshot snap) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // ── Gauge + Stats ────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.surfaceBorder, width: 1),
            ),
            child: Row(
              children: [
                // Circular gauge — left side
                RamUsageMeter(snapshot: snap, size: 140),
                const SizedBox(width: 24),
                // Stats — right side
                Expanded(child: _buildStatsColumn(snap)),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Operations panel ─────────────────────────────────────────
          OptimizeOptionsPanel(
            options: _ctrl.options,
            onToggle: _ctrl.toggleOperation,
          ),

          const SizedBox(height: 14),

          // ── Boost button ─────────────────────────────────────────────
          _buildBoostCard(),

          // ── Result banner ─────────────────────────────────────────────
          if (_ctrl.lastResult != null &&
              _ctrl.boostState == RamBoostState.done) ...[
            const SizedBox(height: 14),
            BoostResultBanner(result: _ctrl.lastResult!),
          ],

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Stats column (right of gauge) ─────────────────────────────────────────
  Widget _buildStatsColumn(RamSnapshot snap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatChip(
          label: 'TOTAL',
          value: '${snap.totalMb} MB',
          color: AppColors.textSecondary,
          icon: Icons.memory_rounded,
        ),
        const SizedBox(height: 10),
        _StatChip(
          label: 'IN USE',
          value: '${snap.usedMb} MB',
          color: AppColors.danger,
          icon: Icons.show_chart_rounded,
        ),
        const SizedBox(height: 10),
        _StatChip(
          label: 'AVAILABLE',
          value: '${snap.availableMb} MB',
          color: AppColors.success,
          icon: Icons.check_circle_outline_rounded,
        ),
        const SizedBox(height: 10),
        _StatChip(
          label: 'STANDBY',
          value: '${snap.standbyMb} MB',
          color: AppColors.warning,
          icon: Icons.layers_rounded,
        ),
      ],
    );
  }

  // ── Boost card ────────────────────────────────────────────────────────────
  Widget _buildBoostCard() {
    final isBoosting = _ctrl.boostState == RamBoostState.boosting;
    final noneSelected = _ctrl.options.selected.isEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceBorder, width: 1),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: (isBoosting || noneSelected) ? null : _ctrl.runBoost,
              icon: isBoosting
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.textPrimary,
                      ),
                    )
                  : Icon(Icons.bolt_rounded,
                      color: AppColors.textPrimary, size: 20),
              label: Text(
                isBoosting
                    ? 'Optimizing…'
                    : noneSelected
                        ? 'Select at least one operation'
                        : '⚡  Optimize RAM',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: noneSelected
                    ? AppColors.surfaceBorder
                    : isBoosting
                        ? AppColors.surfaceBorder
                        : AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            noneSelected
                ? 'Select operations above to optimize memory'
                : 'Trims process working sets, clears file cache & purges standby memory',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small stat chip ──────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 9,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
