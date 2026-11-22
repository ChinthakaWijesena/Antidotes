import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
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
        onConfirm: () => _controller.startClean(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
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
                  color: AppColors.background, size: 28),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Antidotes Junk Cleaner',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Strict whitelist scanning, pattern-based risk assessment & safe deletion',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            // Safety Settings Button
            IconButton.filledTonal(
              tooltip: 'Safety Settings & Exclusions',
              onPressed: isBusy ? null : _openSafetySettings,
              icon: const Icon(Icons.shield_outlined, size: 20),
            ),
            const SizedBox(width: 12),

            // Scan Button
            OutlinedButton.icon(
              onPressed: isBusy ? null : () => _controller.startScan(),
              icon: const Icon(Icons.search_rounded, size: 18),
              label: Text(_controller.hasScanned ? 'Re-scan' : 'Scan Now'),
            ),
            const SizedBox(width: 12),

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
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        StatsCard(
          title: 'Total Junk Detected',
          value: FileSizeFormatter.format(_controller.totalJunkBytes),
          subtitle: '${_controller.totalJunkFiles} files detected',
          icon: Icons.delete_outline_rounded,
          iconColor: AppColors.primary,
        ),
        const SizedBox(width: 16),
        StatsCard(
          title: 'Selected for Cleaning',
          value: FileSizeFormatter.format(_controller.selectedJunkBytes),
          subtitle: '${_controller.selectedJunkFiles} items ready to clean',
          icon: Icons.check_circle_outline_rounded,
          iconColor: AppColors.secondary,
        ),
        const SizedBox(width: 16),
        StatsCard(
          title: '24h File Protection',
          value: _controller.safetyOptions.ignoreRecent24Hours ? 'Active' : 'Disabled',
          subtitle: _controller.safetyOptions.sendToRecycleBin
              ? 'Recycle Bin Mode'
              : 'Permanent Mode',
          icon: Icons.verified_user_outlined,
          iconColor: _controller.safetyOptions.ignoreRecent24Hours
              ? AppColors.success
              : AppColors.warning,
        ),
      ],
    );
  }

  Widget _buildCategoriesToolbar(bool isBusy) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
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
                style: const TextStyle(
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
