import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/system_restore_service.dart';
import '../../../../core/theme/app_theme_scope.dart';
import '../../../../core/utils/file_size_formatter.dart';
import '../controllers/browser_cleaner_controller.dart';
import '../widgets/browser_card.dart';
import '../widgets/browser_clean_summary_dialog.dart';

class BrowserCleanerScreen extends StatefulWidget {
  const BrowserCleanerScreen({super.key});

  @override
  State<BrowserCleanerScreen> createState() => _BrowserCleanerScreenState();
}

class _BrowserCleanerScreenState extends State<BrowserCleanerScreen> {
  late final BrowserCleanerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = BrowserCleanerController();
    _controller.addListener(_onControllerUpdate);
    _controller.scan();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    setState(() {});
  }

  Future<void> _handleClean() async {
    if (_controller.selectedJunkBytes == 0) return;

    bool createRestorePoint = true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.surfaceBorder),
          ),
          title: Row(
            children: [
              const Icon(Icons.delete_sweep_rounded,
                  color: AppColors.danger, size: 24),
              const SizedBox(width: 10),
              Text(
                'Confirm Browser Cleaning',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to clean selected browser data? This will permanently delete ${FileSizeFormatter.format(_controller.selectedJunkBytes)} across ${_controller.selectedFilesCount} items.',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 14),
                if (_controller.runningBrowsersCount > 0) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: AppColors.warning, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${_controller.runningBrowsersCount} browser(s) are currently running. For best cleaning results, close open browsers or click "Close Browser" first.',
                            style: TextStyle(
                                color: AppColors.textPrimary, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // System Restore Point Checkbox
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: createRestorePoint
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : AppColors.surfaceLight.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: createRestorePoint
                          ? AppColors.primary.withValues(alpha: 0.35)
                          : AppColors.surfaceBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: createRestorePoint,
                        activeColor: AppColors.primary,
                        checkColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        onChanged: (val) {
                          setDialogState(() {
                            createRestorePoint = val ?? true;
                          });
                        },
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.settings_backup_restore_rounded,
                          size: 18,
                          color: createRestorePoint
                              ? AppColors.primary
                              : AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Create System Restore Point before cleaning (Recommended)',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Proceed & Clean'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      if (createRestorePoint) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppColors.surfaceBorder),
            ),
            content: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Creating System Restore Point...',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Please approve the Windows UAC prompt if displayed.',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        final srService = SystemRestoreService();
        await srService.createRestorePoint(
          'Antidotes - Pre-Browser Clean (${DateTime.now().toString().split('.')[0]})',
        );

        if (mounted) {
          Navigator.of(context).pop(); // Dismiss loading
        }
      }

      final res = await _controller.startClean();
      if (res != null && mounted) {
        showDialog(
          context: context,
          builder: (_) => BrowserCleanSummaryDialog(result: res),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    AppThemeScope.of(context);
    final isBusy = _controller.isLoading || _controller.isCleaning;
    final groups = _controller.visibleGroups;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              _buildHeader(isBusy),
              const SizedBox(height: 20),

              // Stats Row
              _buildStatsRow(),
              const SizedBox(height: 20),

              // Live Cleaning / Scanning Progress
              if (isBusy) ...[
                _buildProgressCard(),
                const SizedBox(height: 16),
              ],

              // Toolbar (Filter & Select All)
              _buildToolbar(isBusy),
              const SizedBox(height: 12),

              // Browser Cards List
              Expanded(
                child: groups.isEmpty
                    ? Center(
                        child: Text(
                          'No browsers found or matched the filter.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        itemCount: groups.length,
                        itemBuilder: (context, index) {
                          final group = groups[index];
                          return BrowserCard(
                            key: ValueKey(group.type.name),
                            group: group,
                            isInteractive: !isBusy,
                            onItemToggle: (id) => _controller.toggleItem(id),
                            onGroupToggle: (selectAll) =>
                                _controller.toggleGroup(group.type, selectAll),
                            onCloseBrowser: () =>
                                _controller.closeBrowserProcess(group),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isBusy) {
    final canClean = _controller.selectedJunkBytes > 0 && !isBusy;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 700;

        final titleSection = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.accent, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.travel_explore_rounded,
                  color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Browser Cleaner',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Clean caches, history, cookies & session leftovers across all browsers',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        final actionButtons = Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Scan Button
            OutlinedButton.icon(
              onPressed: isBusy ? null : () => _controller.scan(),
              icon: const Icon(Icons.search_rounded, size: 18),
              label: const Text('Scan Browsers'),
            ),

            // Clean Button
            ElevatedButton.icon(
              onPressed: canClean ? _handleClean : null,
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: Text(
                _controller.selectedJunkBytes > 0
                    ? 'Clean Now (${FileSizeFormatter.format(_controller.selectedJunkBytes)})'
                    : 'Clean Now',
              ),
            ),
          ],
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleSection,
              const SizedBox(height: 14),
              actionButtons,
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: titleSection),
            const SizedBox(width: 16),
            actionButtons,
          ],
        );
      },
    );
  }

  Widget _buildStatsRow() {
    final card1 = _statCard(
      title: 'Total Detected',
      value: FileSizeFormatter.format(_controller.totalJunkBytes),
      subtitle: '${_controller.totalFilesDetected} files found',
      icon: Icons.delete_outline_rounded,
      iconColor: AppColors.textSecondary,
    );

    final card2 = _statCard(
      title: 'Selected for Cleaning',
      value: FileSizeFormatter.format(_controller.selectedJunkBytes),
      subtitle: '${_controller.selectedFilesCount} items ready to clean',
      icon: Icons.check_circle_outline_rounded,
      iconColor: AppColors.primary,
    );

    final card3 = _statCard(
      title: 'Active Browsers',
      value: _controller.runningBrowsersCount == 0
          ? 'All Closed'
          : '${_controller.runningBrowsersCount} Running',
      subtitle: _controller.runningBrowsersCount == 0
          ? 'Safe to clean all caches'
          : 'Close browsers to unlock all files',
      icon: Icons.shield_outlined,
      iconColor: _controller.runningBrowsersCount == 0
          ? AppColors.success
          : AppColors.warning,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
          return Column(
            children: [
              card1,
              const SizedBox(height: 10),
              card2,
              const SizedBox(height: 10),
              card3,
            ],
          );
        } else if (constraints.maxWidth < 820) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: card1),
                  const SizedBox(width: 12),
                  Expanded(child: card2),
                ],
              ),
              const SizedBox(height: 12),
              card3,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: card1),
            const SizedBox(width: 14),
            Expanded(child: card2),
            const SizedBox(width: 14),
            Expanded(child: card3),
          ],
        );
      },
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _controller.isCleaning
                    ? 'Cleaning browser caches & leftovers...'
                    : 'Scanning browsers for temporary files...',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (_controller.currentProcessingPath.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _controller.currentProcessingPath,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Consolas',
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildToolbar(bool isBusy) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              'Supported Browsers',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 16),
            FilterChip(
              label: const Text('Show Installed Only'),
              selected: _controller.showInstalledOnly,
              onSelected: isBusy
                  ? null
                  : (val) => _controller.toggleShowInstalledOnly(val),
              backgroundColor: AppColors.surface,
              selectedColor: AppColors.primary.withValues(alpha: 0.15),
              side: BorderSide(
                color: _controller.showInstalledOnly
                    ? AppColors.primary.withValues(alpha: 0.4)
                    : AppColors.surfaceBorder,
              ),
              labelStyle: TextStyle(
                fontSize: 12,
                color: _controller.showInstalledOnly
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        Row(
          children: [
            TextButton.icon(
              onPressed: isBusy ? null : () => _controller.selectAll(true),
              icon: const Icon(Icons.select_all_rounded, size: 16),
              label: const Text('Select All'),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: isBusy ? null : () => _controller.selectAll(false),
              icon: const Icon(Icons.deselect_rounded, size: 16),
              label: const Text('Deselect All'),
            ),
          ],
        ),
      ],
    );
  }
}
