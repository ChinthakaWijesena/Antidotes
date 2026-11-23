import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/system_restore_service.dart';
import '../../../../core/theme/app_theme_scope.dart';
import 'package:antidotes/features/software_installer/data/models/software_app_item.dart';
import 'package:antidotes/features/software_installer/data/models/software_category.dart';
import '../controllers/software_installer_controller.dart';
import '../widgets/software_app_card.dart';

class SoftwareInstallerScreen extends StatefulWidget {
  const SoftwareInstallerScreen({super.key});

  @override
  State<SoftwareInstallerScreen> createState() =>
      _SoftwareInstallerScreenState();
}

class _SoftwareInstallerScreenState extends State<SoftwareInstallerScreen> {
  late final SoftwareInstallerController _controller;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = SoftwareInstallerController();
    _controller.addListener(_onUpdate);
    _controller.loadCatalog();
  }

  @override
  void dispose() {
    _controller.removeListener(_onUpdate);
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _handleSingleInstall(SoftwareAppItem app) async {
    bool createRestorePoint = false;

    final confirm = await showDialog<bool>(
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
              Icon(Icons.download_rounded, color: AppColors.primary, size: 24),
              const SizedBox(width: 10),
              Text(
                'Install ${app.name}?',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Antidotes will download and install the official ${app.name} (${app.packageId}) package silently in the background.',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 14),

                // System Restore Point prompt
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
                            createRestorePoint = val ?? false;
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
                          'Create System Restore Point before installing',
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
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Install Now'),
            ),
          ],
        ),
      ),
    );

    if (confirm == true && mounted) {
      if (createRestorePoint) {
        final sr = SystemRestoreService();
        await sr.createRestorePoint('Antidotes - Pre-Install ${app.name}');
      }

      final res = await _controller.installApp(app);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.message),
            backgroundColor:
                res.isSuccess ? AppColors.success : AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _handleBatchInstall() async {
    final count = _controller.selectedCount;
    if (count == 0) return;

    bool createRestorePoint = true;

    final confirm = await showDialog<bool>(
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
              Icon(Icons.download_for_offline_rounded,
                  color: AppColors.primary, size: 24),
              const SizedBox(width: 10),
              Text(
                'Install $count Selected Apps?',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Antidotes will install all $count selected applications sequentially in the background using Windows Package Manager.',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 14),

                // System Restore Point prompt
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
                          'Create System Restore Point before installing (Recommended)',
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
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Install $count Apps'),
            ),
          ],
        ),
      ),
    );

    if (confirm == true && mounted) {
      if (createRestorePoint) {
        final sr = SystemRestoreService();
        await sr.createRestorePoint('Antidotes - Batch Software Install');
      }

      await _controller.installSelectedApps();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Batch software installation finished.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    AppThemeScope.of(context);
    final isBusy = _controller.isBatchInstalling || _controller.isLoading;
    final apps = _controller.filteredApps;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(isBusy),
              const SizedBox(height: 18),

              // Batch install progress banner
              if (_controller.isBatchInstalling) ...[
                _buildBatchProgressBanner(),
                const SizedBox(height: 16),
              ],

              // Categories Filter & Actions Toolbar
              _buildToolbar(isBusy),
              const SizedBox(height: 16),

              // Apps Grid
              Expanded(
                child: _controller.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : apps.isEmpty
                        ? Center(
                            child: Text(
                              'No matching software found.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          )
                        : GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 420,
                              mainAxisExtent: 175,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: apps.length,
                            itemBuilder: (context, index) {
                              final app = apps[index];
                              return SoftwareAppCard(
                                key: ValueKey(app.id),
                                app: app,
                                isInteractive: !isBusy,
                                onInstall: () => _handleSingleInstall(app),
                                onToggleSelect: () =>
                                    _controller.toggleSelectApp(app.id),
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
    final canBatchInstall = _controller.selectedCount > 0 && !isBusy;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 740;

        final titleWidget = Row(
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
              child: const Icon(Icons.get_app_rounded,
                  color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Software Installer',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '1-Click install popular Windows applications cleanly & silently via winget',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        );

        final searchWidget = SizedBox(
          width: isNarrow ? null : 260,
          height: 38,
          child: TextField(
            controller: _searchController,
            onChanged: (val) => _controller.setSearchQuery(val),
            decoration: InputDecoration(
              hintText: 'Search software (Chrome, VS Code...)',
              hintStyle:
                  TextStyle(color: AppColors.textMuted, fontSize: 12),
              prefixIcon: Icon(Icons.search_rounded,
                  size: 18, color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.surface,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.surfaceBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.surfaceBorder),
              ),
            ),
          ),
        );

        final batchButton = ElevatedButton.icon(
          onPressed: canBatchInstall ? _handleBatchInstall : null,
          icon: const Icon(Icons.download_for_offline_rounded, size: 18),
          label: Text(
            _controller.selectedCount > 0
                ? 'Install Selected (${_controller.selectedCount})'
                : 'Install Selected',
          ),
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              titleWidget,
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: searchWidget),
                  const SizedBox(width: 12),
                  batchButton,
                ],
              ),
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: titleWidget),
            const SizedBox(width: 16),
            Row(
              children: [
                searchWidget,
                const SizedBox(width: 12),
                batchButton,
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildBatchProgressBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              _controller.currentOperationText.isNotEmpty
                  ? _controller.currentOperationText
                  : 'Batch installation in progress...',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(bool isBusy) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Category Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: SoftwareCategory.values.map((cat) {
              final isSelected = _controller.selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(cat.displayName),
                  selected: isSelected,
                  onSelected:
                      isBusy ? null : (_) => _controller.selectCategory(cat),
                  backgroundColor: AppColors.surface,
                  selectedColor: AppColors.primary.withValues(alpha: 0.15),
                  side: BorderSide(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.4)
                        : AppColors.surfaceBorder,
                  ),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // Quick Select actions
        Row(
          children: [
            TextButton.icon(
              onPressed:
                  isBusy ? null : () => _controller.selectAllUninstalled(true),
              icon: const Icon(Icons.select_all_rounded, size: 16),
              label: const Text('Select All'),
            ),
            const SizedBox(width: 6),
            TextButton.icon(
              onPressed:
                  isBusy ? null : () => _controller.selectAllUninstalled(false),
              icon: const Icon(Icons.deselect_rounded, size: 16),
              label: const Text('Deselect'),
            ),
          ],
        ),
      ],
    );
  }
}
