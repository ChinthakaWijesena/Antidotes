import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/system_restore_service.dart';
import '../../../../core/theme/app_theme_scope.dart';
import '../../../../core/utils/file_size_formatter.dart';
import '../controllers/junk_cleaner_controller.dart';
import '../widgets/category_tile.dart';
import '../widgets/clean_confirmation_dialog.dart';
import '../widgets/cleanup_summary_dialog.dart';
import '../widgets/safety_settings_dialog.dart';
import '../widgets/scan_progress_card.dart';
import '../widgets/stats_card.dart';

class JunkCleanerScreen extends StatefulWidget {
  const JunkCleanerScreen({super.key});

  @override
  State<JunkCleanerScreen> createState() => _JunkCleanerScreenState();
}

class _JunkCleanerScreenState extends State<JunkCleanerScreen> {
  late final JunkCleanerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = JunkCleanerController();
    _controller.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    setState(() {});

    // Automatically trigger summary dialog when cleaning completes
    if (_controller.state == CleanerState.cleanCompleted &&
        _controller.lastCleanupResult != null) {
      final result = _controller.lastCleanupResult!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => CleanupSummaryDialog(result: result),
        );
      });
    }
  }

  void _openSafetySettings() {
    showDialog(
      context: context,
      builder: (_) => SafetySettingsDialog(
        initialOptions: _controller.safetyOptions,
        onSaved: (newOptions) {
          _controller.updateSafetyOptions(newOptions);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Safety rules updated! Re-scan to apply new filters.'),
              duration: Duration(seconds: 3),
            ),
          );
        },
      ),
    );
  }

  void _confirmAndClean() {
    if (_controller.selectedJunkBytes == 0) return;

    showDialog(
      context: context,
      builder: (_) => CleanConfirmationDialog(
        categories: _controller.categories,
        initialCreateRestorePoint:
            _controller.safetyOptions.askCreateRestorePoint,
        onConfirm: (createRestorePoint) async {
          if (createRestorePoint) {
            await _createRestorePointAndProceed();
          } else {
            _controller.startClean();
          }
        },
      ),
    );
  }

  Future<void> _createRestorePointAndProceed() async {
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
                      'Please approve the Windows UAC elevation if prompted.',
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
    final result = await srService.createRestorePoint(
      'Antidotes - Pre-Cleanup (${DateTime.now().toString().split('.')[0]})',
    );

    if (mounted) {
      Navigator.of(context).pop(); // dismiss loading dialog

      if (!result.isSuccess && result.status != SystemRestoreStatus.unsupported) {
        final proceedAnyway = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppColors.surfaceBorder),
            ),
            title: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: AppColors.warning, size: 24),
                const SizedBox(width: 10),
                Text(
                  'Restore Point Incomplete',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Text(
              '${result.message}\n\nDo you want to proceed with cleaning anyway?',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            actions: [
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel Clean'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Proceed Anyway'),
              ),
            ],
          ),
        );

        if (proceedAnyway != true) return;
      }

      _controller.startClean();
    }
  }

  @override
  Widget build(BuildContext context) {
    AppThemeScope.of(context);
    final isBusy = _controller.isScanning || _controller.isCleaning;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header & Action Buttons
              _buildHeader(isBusy),
              const SizedBox(height: 24),

              // Statistics Cards
              _buildStatsRow(),
              const SizedBox(height: 24),

              // Scanning or Cleaning Live Indicator
              if (isBusy) ...[
                ScanProgressCard(
                  statusText: _controller.isScanning
                      ? 'Scanning safe Windows locations...'
                      : 'Cleaning selected files...',
                  currentPath: _controller.currentProcessingPath,
                  isCleaning: _controller.isCleaning,
                ),
              ],

              // Categories Header with Select All and Safety Settings
              _buildCategoriesToolbar(isBusy),
              const SizedBox(height: 12),

              // Categories List
              Expanded(
                child: ListView.builder(
                  itemCount: _controller.categories.length,
                  itemBuilder: (context, index) {
                    final category = _controller.categories[index];
                    return CategoryTile(
                      key: ValueKey(category.id),
                      category: category,
                      isInteractive: !isBusy,
                      onToggle: () => _controller.toggleCategory(category.id),
                      onItemToggle: (item) => setState(() {}),
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
    final selectedBytes = _controller.selectedJunkBytes;

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
                  colors: [AppColors.primary, AppColors.secondary],
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
              child: const Icon(Icons.cleaning_services_rounded,
                  color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Antidotes Junk Cleaner',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Strict whitelist scanning, pattern-based risk assessment & safe deletion',
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
            // Safety Settings Button
            IconButton.filledTonal(
              tooltip: 'Safety Settings & Exclusions',
              onPressed: isBusy ? null : _openSafetySettings,
              icon: const Icon(Icons.shield_outlined, size: 20),
            ),

            // Scan Button
            OutlinedButton.icon(
              onPressed: isBusy ? null : () => _controller.startScan(),
              icon: const Icon(Icons.search_rounded, size: 18),
              label: Text(_controller.hasScanned ? 'Re-scan' : 'Scan Now'),
            ),

            // Clean Button
            ElevatedButton.icon(
              onPressed: isBusy || selectedBytes == 0 ? null : _confirmAndClean,
              icon: const Icon(Icons.delete_sweep_rounded, size: 18),
              label: Text(
                selectedBytes > 0
                    ? 'Clean (${FileSizeFormatter.format(selectedBytes)})'
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
    final card1 = StatsCard(
      title: 'Total Junk Detected',
      value: FileSizeFormatter.format(_controller.totalJunkBytes),
      subtitle: '${_controller.totalJunkFiles} files detected',
      icon: Icons.delete_outline_rounded,
      iconColor: AppColors.primary,
    );
    final card2 = StatsCard(
      title: 'Selected for Cleaning',
      value: FileSizeFormatter.format(_controller.selectedJunkBytes),
      subtitle: '${_controller.selectedJunkFiles} items ready to clean',
      icon: Icons.check_circle_outline_rounded,
      iconColor: AppColors.secondary,
    );
    final card3 = StatsCard(
      title: '24h File Protection',
      value: _controller.safetyOptions.ignoreRecent24Hours ? 'Active' : 'Disabled',
      subtitle: _controller.safetyOptions.sendToRecycleBin
          ? 'Recycle Bin Mode'
          : 'Permanent Mode',
      icon: Icons.verified_user_outlined,
      iconColor: _controller.safetyOptions.ignoreRecent24Hours
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

  Widget _buildCategoriesToolbar(bool isBusy) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Target Locations & Categories',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          children: [
            TextButton.icon(
              onPressed: isBusy
                  ? null
                  : () => _controller.toggleSelectAll(!_controller.allSelected),
              icon: Icon(
                _controller.allSelected
                    ? Icons.check_box_rounded
                    : Icons.check_box_outline_blank_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              label: Text(
                _controller.allSelected ? 'Deselect All' : 'Select All',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
