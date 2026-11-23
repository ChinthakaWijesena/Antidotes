import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme_scope.dart';
import '../../../../core/theme/system_theme_controller.dart';
import '../../../../core/utils/admin_helper.dart';
import '../../data/models/disk_health_model.dart';
import '../controllers/disk_health_controller.dart';

class DiskHealthScreen extends StatefulWidget {
  const DiskHealthScreen({super.key});

  @override
  State<DiskHealthScreen> createState() => _DiskHealthScreenState();
}

class _DiskHealthScreenState extends State<DiskHealthScreen> {
  late final DiskHealthController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = DiskHealthController();
    _ctrl.addListener(() { if (mounted) setState(() {}); });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeScope.of(context);
    return Container(
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(SystemThemeController theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.surfaceBorder)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.storage_rounded,
                color: theme.accentColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Disk Health',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                Text('S.M.A.R.T. status · temperature · lifespan',
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
          // Last refreshed label
          if (_ctrl.lastRefreshed != null)
            Text(
              'Updated ${_timeAgo(_ctrl.lastRefreshed!)}',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          const SizedBox(width: 12),
          // Refresh button
          _buildRefreshButton(theme),
        ],
      ),
    );
  }

  Widget _buildRefreshButton(SystemThemeController theme) {
    return GestureDetector(
      onTap: _ctrl.isLoading ? null : _ctrl.refresh,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: theme.accentColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: theme.accentColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ctrl.isLoading
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.accentColor,
                    ),
                  )
                : Icon(Icons.refresh_rounded,
                    color: theme.accentColor, size: 15),
            const SizedBox(width: 6),
            Text('Refresh',
                style: TextStyle(
                    color: theme.accentColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ── Body ───────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    switch (_ctrl.state) {
      case DiskHealthLoadState.idle:
      case DiskHealthLoadState.loading:
        return _buildLoadingState();
      case DiskHealthLoadState.error:
        return _buildErrorState();
      case DiskHealthLoadState.loaded:
        if (_ctrl.drives.isEmpty) return _buildEmptyState();
        return _buildDriveList();
    }
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
              color: AppColors.textMuted, strokeWidth: 2),
          const SizedBox(height: 16),
          Text('Scanning S.M.A.R.T. data…',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded,
              color: AppColors.danger, size: 48),
          const SizedBox(height: 12),
          Text('Failed to read disk data',
              style: TextStyle(
                  color: AppColors.textPrimary, fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(_ctrl.errorMessage,
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          _RetryButton(onTap: _ctrl.refresh),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.storage_rounded,
              color: AppColors.textMuted, size: 48),
          const SizedBox(height: 12),
          Text('No drives detected',
              style: TextStyle(
                  color: AppColors.textPrimary, fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Try running as Administrator for full S.M.A.R.T. access.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          const SizedBox(height: 20),
          _RetryButton(onTap: _ctrl.refresh),
        ],
      ),
    );
  }

  Widget _buildDriveList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary banner
          _SummaryBanner(
            total: _ctrl.drives.length,
            healthy: _ctrl.healthyCount,
            warning: _ctrl.warningCount,
            critical: _ctrl.criticalCount,
          ),
          const SizedBox(height: 20),
          // Admin tip if not admin and no SMART data
          if (!_ctrl.isAdmin && _ctrl.drives.every((d) => d.smartAttributes.isEmpty))
            _buildAdminTip(),
          // Drive cards
          ...(_ctrl.drives.map((drive) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _DriveCard(drive: drive),
              ))),
        ],
      ),
    );
  }

  Widget _buildAdminTip() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: Color(0xFFF59E0B), size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Run Antidotes as Administrator to unlock full S.M.A.R.T. attribute data (temperature, power-on hours, life remaining).',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => AdminHelper.restartAsAdmin(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shield_rounded, color: Color(0xFFF59E0B), size: 14),
                  SizedBox(width: 5),
                  Text(
                    'Restart as Admin',
                    style: TextStyle(
                      color: Color(0xFFF59E0B),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}

// ── Summary Banner ─────────────────────────────────────────────────────────────

class _SummaryBanner extends StatelessWidget {
  const _SummaryBanner({
    required this.total,
    required this.healthy,
    required this.warning,
    required this.critical,
  });

  final int total, healthy, warning, critical;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          _stat('$total', 'Total Drives',
              AppColors.textPrimary, Icons.storage_rounded),
          _divider(),
          _stat('$healthy', 'Healthy',
              const Color(0xFF10B981), Icons.check_circle_rounded),
          _divider(),
          _stat('$warning', 'Warning',
              const Color(0xFFF59E0B), Icons.warning_rounded),
          _divider(),
          _stat('$critical', 'Critical',
              AppColors.danger, Icons.dangerous_rounded),
        ],
      ),
    );
  }

  Widget _stat(String count, String label, Color color, IconData icon) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(count,
                  style: TextStyle(
                      color: color,
                      fontSize: 20,
                      fontWeight: FontWeight.w700)),
              Text(label,
                  style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 36,
        color: AppColors.surfaceBorder,
        margin: const EdgeInsets.symmetric(horizontal: 8),
      );
}

// ── Drive Card ────────────────────────────────────────────────────────────────

class _DriveCard extends StatefulWidget {
  const _DriveCard({required this.drive});
  final DiskDrive drive;

  @override
  State<_DriveCard> createState() => _DriveCardState();
}

class _DriveCardState extends State<_DriveCard> {
  bool _expanded = true;

  DiskDrive get d => widget.drive;

  Color get _healthColor {
    if (d.predictFailure) return AppColors.danger;
    switch (d.healthStatus) {
      case DiskHealthStatus.healthy:
        return const Color(0xFF10B981);
      case DiskHealthStatus.warning:
        return const Color(0xFFF59E0B);
      case DiskHealthStatus.unhealthy:
        return AppColors.danger;
      case DiskHealthStatus.unknown:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: d.predictFailure
              ? AppColors.danger.withValues(alpha: 0.5)
              : AppColors.surfaceBorder,
          width: d.predictFailure ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          // ── Card Header ──
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Drive type icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _healthColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: _healthColor.withValues(alpha: 0.3)),
                    ),
                    child: Center(
                      child: Icon(_driveIcon(d.mediaType),
                          color: _healthColor, size: 22),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Name & model
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d.name,
                            style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            _Chip(d.mediaType.label, _healthColor),
                            const SizedBox(width: 6),
                            Text(d.sizeFormatted,
                                style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Health badge
                  _HealthBadge(
                      status: d.predictFailure
                          ? 'FAIL PREDICTED'
                          : d.healthStatus.label.toUpperCase(),
                      color: _healthColor),
                  const SizedBox(width: 10),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded Detail ──
          if (_expanded) ...[
            Divider(color: AppColors.surfaceBorder, height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Metric row
                  Row(
                    children: [
                      _MetricTile(
                        icon: Icons.thermostat_rounded,
                        label: 'Temperature',
                        value: d.temperatureLabel,
                        color: _tempColor(d),
                        sub: d.temperatureState == 'unknown'
                            ? null
                            : d.temperatureState[0].toUpperCase() +
                                d.temperatureState.substring(1),
                      ),
                      _MetricTile(
                        icon: Icons.battery_full_rounded,
                        label: 'Life Remaining',
                        value: d.lifeLabel,
                        color: _lifeColor(d.lifeRemaining),
                      ),
                      _MetricTile(
                        icon: Icons.schedule_rounded,
                        label: 'Power-On Hours',
                        value: d.powerOnLabel,
                        color: AppColors.textSecondary,
                      ),
                      _MetricTile(
                        icon: Icons.pie_chart_rounded,
                        label: 'Used Space',
                        value: '${d.usedPercent}%',
                        color: AppColors.textSecondary,
                        sub: '${d.usedFormatted} / ${d.sizeFormatted}',
                      ),
                    ],
                  ),

                  // Used space bar
                  const SizedBox(height: 14),
                  _StorageBar(
                    usedBytes: d.usedBytes,
                    totalBytes: d.sizeBytes,
                    color: d.usedPercent > 90
                        ? AppColors.danger
                        : const Color(0xFF3B82F6),
                  ),

                  // S.M.A.R.T. attributes table (if available)
                  if (d.smartAttributes.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _SmartAttributeTable(attrs: d.smartAttributes),
                  ],

                  // Failure prediction warning
                  if (d.predictFailure) ...[
                    const SizedBox(height: 14),
                    _FailureBanner(),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _driveIcon(DiskMediaType type) {
    switch (type) {
      case DiskMediaType.ssd:
        return Icons.memory_rounded;
      case DiskMediaType.nvme:
        return Icons.developer_board_rounded;
      case DiskMediaType.hdd:
        return Icons.storage_rounded;
      case DiskMediaType.unspecified:
        return Icons.storage_rounded;
    }
  }

  Color _tempColor(DiskDrive d) {
    if (d.temperature == null) return AppColors.textMuted;
    if (d.temperature! < 40) return const Color(0xFF10B981);
    if (d.temperature! < 55) return const Color(0xFFF59E0B);
    return AppColors.danger;
  }

  Color _lifeColor(int? life) {
    if (life == null) return AppColors.textMuted;
    if (life > 50) return const Color(0xFF10B981);
    if (life > 20) return const Color(0xFFF59E0B);
    return AppColors.danger;
  }
}

// ── S.M.A.R.T. Attribute Table ─────────────────────────────────────────────

class _SmartAttributeTable extends StatelessWidget {
  const _SmartAttributeTable({required this.attrs});
  final List<SmartAttribute> attrs;

  static const _keyIds = {5, 9, 194, 190, 177, 231, 197, 198, 1, 199};

  @override
  Widget build(BuildContext context) {
    // Show key attrs first, then others
    final key = attrs.where((a) => _keyIds.contains(a.id)).toList();
    final rest = attrs.where((a) => !_keyIds.contains(a.id)).toList();
    final displayed = [...key, ...rest].take(15).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.analytics_rounded,
                color: AppColors.textMuted, size: 13),
            const SizedBox(width: 6),
            Text('S.M.A.R.T. Attributes',
                style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: [
                    SizedBox(
                        width: 36,
                        child: Text('ID',
                            style: _hStyle)),
                    Expanded(
                        child: Text('Attribute',
                            style: _hStyle)),
                    SizedBox(
                        width: 50,
                        child: Text('Value',
                            style: _hStyle,
                            textAlign: TextAlign.center)),
                    SizedBox(
                        width: 50,
                        child: Text('Worst',
                            style: _hStyle,
                            textAlign: TextAlign.center)),
                    SizedBox(
                        width: 60,
                        child: Text('Raw',
                            style: _hStyle,
                            textAlign: TextAlign.right)),
                  ],
                ),
              ),
              Divider(color: AppColors.surfaceBorder, height: 1),
              ...displayed.asMap().entries.map((e) {
                final i = e.key;
                final attr = e.value;
                final failing = attr.isFailing;
                return Column(
                  children: [
                    if (i > 0)
                      Divider(color: AppColors.surfaceBorder, height: 1),
                    Container(
                      color: failing
                          ? AppColors.danger.withValues(alpha: 0.05)
                          : Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 36,
                            child: Text(
                              '0x${attr.id.toRadixString(16).toUpperCase().padLeft(2, '0')}',
                              style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 10,
                                  fontFamily: 'monospace'),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              attr.name,
                              style: TextStyle(
                                  color: failing
                                      ? AppColors.danger
                                      : AppColors.textSecondary,
                                  fontSize: 11,
                                  fontWeight: failing
                                      ? FontWeight.w600
                                      : FontWeight.normal),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(
                            width: 50,
                            child: Text(
                              '${attr.value}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: failing
                                      ? AppColors.danger
                                      : AppColors.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          SizedBox(
                            width: 50,
                            child: Text(
                              '${attr.worst}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: AppColors.textMuted, fontSize: 11),
                            ),
                          ),
                          SizedBox(
                            width: 60,
                            child: Text(
                              '${attr.rawValue}',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 10,
                                  fontFamily: 'monospace'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  static final _hStyle = TextStyle(
    color: AppColors.textMuted,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );
}

// ── Storage Bar ───────────────────────────────────────────────────────────────

class _StorageBar extends StatelessWidget {
  const _StorageBar({
    required this.usedBytes,
    required this.totalBytes,
    required this.color,
  });

  final int usedBytes, totalBytes;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final pct = totalBytes > 0
        ? (usedBytes / totalBytes).clamp(0.0, 1.0)
        : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Storage Usage',
                style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8)),
            Text('${(pct * 100).round()}%',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 10)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 6,
            backgroundColor: AppColors.surfaceBorder,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

// ── Metric Tile ───────────────────────────────────────────────────────────────

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.sub,
  });

  final IconData icon;
  final String label, value;
  final Color color;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w500)),
            if (sub != null) ...[
              const SizedBox(height: 2),
              Text(sub!,
                  style: TextStyle(
                      color: color.withValues(alpha: 0.7), fontSize: 10)),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Health Badge ──────────────────────────────────────────────────────────────

class _HealthBadge extends StatelessWidget {
  const _HealthBadge({required this.status, required this.color});
  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(status,
          style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5)),
    );
  }
}

// ── Chip ──────────────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  const _Chip(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700)),
    );
  }
}

// ── Failure Banner ────────────────────────────────────────────────────────────

class _FailureBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              color: AppColors.danger, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('S.M.A.R.T. Failure Predicted',
                    style: TextStyle(
                        color: AppColors.danger,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                    'Back up your data immediately. This drive has signalled an imminent failure.',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Retry Button ──────────────────────────────────────────────────────────────

class _RetryButton extends StatelessWidget {
  const _RetryButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeScope.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: theme.accentColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: theme.accentColor.withValues(alpha: 0.3)),
        ),
        child: Text('Try Again',
            style: TextStyle(
                color: theme.accentColor,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      ),
    );
  }
}
