import 'dart:async';
import 'package:flutter/material.dart';
import 'package:antidotes/core/constants/app_colors.dart';
import 'package:antidotes/core/services/system_restore_service.dart';
import 'package:antidotes/features/software_uninstaller/data/models/installed_app_item.dart';
import 'package:antidotes/features/software_uninstaller/data/models/leftover_item.dart';
import 'package:antidotes/features/software_uninstaller/data/models/uninstall_scan_mode.dart';
import 'package:antidotes/features/software_uninstaller/data/services/software_uninstaller_service.dart';
import 'package:antidotes/features/software_uninstaller/presentation/widgets/leftover_tree_view.dart';

enum WizardStage {
  confirmation,
  analysis,
  scanning,
  leftovers,
  completed,
}

class SoftwareUninstallWizardDialog extends StatefulWidget {
  final InstalledAppItem app;
  final SoftwareUninstallerService service;
  final VoidCallback onUninstallComplete;

  const SoftwareUninstallWizardDialog({
    super.key,
    required this.app,
    required this.service,
    required this.onUninstallComplete,
  });

  @override
  State<SoftwareUninstallWizardDialog> createState() => _SoftwareUninstallWizardDialogState();
}

class _SoftwareUninstallWizardDialogState extends State<SoftwareUninstallWizardDialog> {
  WizardStage _stage = WizardStage.confirmation;
  bool _makeRestorePoint = true;
  UninstallScanMode _scanMode = UninstallScanMode.advanced;

  // Analysis status
  bool _restorePointDone = false;
  String _restorePointStatus = 'Creating System Restore Point...';
  bool _uninstallerLaunched = false;

  // Leftovers state
  List<LeftoverItem> _leftovers = [];
  String _selectedPath = '';
  double _scanProgress = 0.0;
  Timer? _scanTimer;

  int get _selectedRegistryKeysCount =>
      _leftovers.where((i) => i.isSelected && !i.isDeleted && i.type == LeftoverType.registryKey).length;

  int get _selectedRegistryValuesCount =>
      _leftovers.where((i) => i.isSelected && !i.isDeleted && i.type == LeftoverType.registryValue).length;

  int get _selectedFilesCount =>
      _leftovers.where((i) => i.isSelected && !i.isDeleted && !i.isRegistry).length;

  bool get _allSelected =>
      _leftovers.isNotEmpty && _leftovers.where((i) => !i.isDeleted).every((i) => i.isSelected);

  @override
  void dispose() {
    _scanTimer?.cancel();
    super.dispose();
  }

  void _onContinueFromConfirmation() async {
    setState(() {
      _stage = WizardStage.analysis;
    });

    // 1. System Restore Point step
    if (_makeRestorePoint) {
      setState(() {
        _restorePointStatus = 'Creating System Restore Point...';
      });

      final srService = SystemRestoreService();
      final res = await srService.createRestorePoint('Before uninstalling ${widget.app.name}');
      if (mounted) {
        setState(() {
          _restorePointDone = true;
          _restorePointStatus = res.isSuccess
              ? 'Creating System Restore Point - completed!'
              : 'Creating System Restore Point - finished with status: ${res.message}';
        });
      }
    } else {
      setState(() {
        _restorePointDone = true;
        _restorePointStatus = 'Creating System Restore Point - skipped!';
      });
    }

    // 2. Launch native uninstaller
    if (mounted) {
      setState(() {
        _uninstallerLaunched = true;
      });
      // Run non-blocking so the wizard stays responsive
      widget.service.launchNativeUninstaller(widget.app);
    }
  }

  void _startScanning() {
    setState(() {
      _stage = WizardStage.scanning;
      _scanProgress = 0.1;
    });

    _scanTimer = Timer.periodic(const Duration(milliseconds: 120), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _scanProgress += 0.08;
      });

      if (_scanProgress >= 1.0) {
        timer.cancel();
        final results = await widget.service.scanForLeftovers(widget.app, _scanMode);
        if (mounted) {
          setState(() {
            _leftovers = results;
            _selectedPath = results.isNotEmpty ? results.first.path : '';
            _stage = WizardStage.leftovers;
          });
        }
      }
    });
  }

  void _toggleSelectAll() {
    final target = !_allSelected;
    setState(() {
      for (final item in _leftovers) {
        if (!item.isDeleted) {
          item.isSelected = target;
        }
      }
    });
  }

  Future<void> _deleteSelectedItems() async {
    final selectedCount = _leftovers.where((i) => i.isSelected && !i.isDeleted).length;
    if (selectedCount == 0) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFF57C00), size: 28),
            const SizedBox(width: 10),
            Text(
              'Antidotes Uninstaller',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure that you want to delete the selected items?',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              backgroundColor: const Color(0xFFF4B400).withValues(alpha: 0.3),
            ),
            child: const Text('Yes', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(foregroundColor: AppColors.textMuted),
            child: const Text('No'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.service.deleteLeftoverItems(_leftovers);
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.background,
      elevation: 24,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppColors.surfaceBorder, width: 1.5),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 540),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top window titlebar
              _buildWindowTitleBar(),

              // Banner
              _buildTopBanner(),

              // Wizard Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  child: _buildCurrentStageView(),
                ),
              ),

              // Bottom Actions Bar
              _buildBottomActionBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWindowTitleBar() {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.surfaceBorder)),
      ),
      child: Row(
        children: [
          Icon(widget.app.defaultIcon, size: 16, color: const Color(0xFFF57C00)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Uninstalling ${widget.app.name}',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(4),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close_rounded, size: 16, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBanner() {
    String text;
    if (_stage == WizardStage.leftovers) {
      text = 'Found leftover Registry items';
    } else {
      text = 'Performing the initial analysis and uninstall';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFFFDE89C),
        border: Border(bottom: BorderSide(color: Color(0xFFE5CF7B), width: 1)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF4A3800),
          fontSize: 16.5,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  Widget _buildCurrentStageView() {
    switch (_stage) {
      case WizardStage.confirmation:
        return _buildConfirmationView();
      case WizardStage.analysis:
        return _buildAnalysisView();
      case WizardStage.scanning:
        return _buildScanningView();
      case WizardStage.leftovers:
        return _buildLeftoversView();
      case WizardStage.completed:
        return _buildCompletedView();
    }
  }

  // --- STAGE 1: CONFIRMATION ---
  Widget _buildConfirmationView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        Center(
          child: Text(
            'Are you sure that you want to uninstall the selected program?',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFF57C00).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF57C00).withValues(alpha: 0.4)),
              ),
              child: Icon(widget.app.defaultIcon, size: 34, color: const Color(0xFFF57C00)),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.app.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.app.formattedSize,
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.app.displayVersion,
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.app.displayDate,
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.app.displayPublisher,
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.app.uninstallString,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontFamily: 'Consolas',
                      color: AppColors.textMuted,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        const Spacer(),
        // Checkbox: Make a System Restore Point
        Row(
          children: [
            Checkbox(
              value: _makeRestorePoint,
              onChanged: (val) {
                setState(() {
                  _makeRestorePoint = val ?? true;
                });
              },
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _makeRestorePoint = !_makeRestorePoint;
                });
              },
              child: Text(
                'Make a System Restore Point before uninstall',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- STAGE 2: INITIAL ANALYSIS ---
  Widget _buildAnalysisView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        // Step 1: System Restore Point
        Row(
          children: [
            Icon(
              _restorePointDone ? Icons.check_circle_rounded : Icons.pending_rounded,
              color: _restorePointDone ? Colors.green : const Color(0xFFF57C00),
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _restorePointStatus,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Step 2: Native Uninstaller
        Row(
          children: [
            Icon(
              _uninstallerLaunched ? Icons.check_circle_rounded : Icons.hourglass_top_rounded,
              color: _uninstallerLaunched ? Colors.green : const Color(0xFFF57C00),
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Analyzing and starting the program's built-in uninstaller for the default uninstall",
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Step 3: Prompt to Scan
        Row(
          children: [
            const Icon(Icons.search_rounded, color: Color(0xFF0288D1), size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'After the program\'s uninstaller has finished, press the "Scan" button to start scanning for leftover files, folders and registry items.',
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
        const Spacer(),

        // Scanning modes box
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Scanning modes',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _buildScanRadio(UninstallScanMode.safe, 'Safe'),
                  const SizedBox(width: 24),
                  _buildScanRadio(UninstallScanMode.moderate, 'Moderate'),
                  const SizedBox(width: 24),
                  _buildScanRadio(UninstallScanMode.advanced, 'Advanced'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScanRadio(UninstallScanMode mode, String label) {
    return InkWell(
      onTap: () {
        setState(() {
          _scanMode = mode;
        });
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _scanMode == mode ? const Color(0xFFF57C00) : AppColors.textMuted,
                width: 1.5,
              ),
            ),
            child: _scanMode == mode
                ? Center(
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFF57C00),
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: _scanMode == mode ? FontWeight.bold : FontWeight.normal,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // --- STAGE 3: SCANNING ---
  Widget _buildScanningView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 22),
            const SizedBox(width: 12),
            Text(
              _restorePointStatus,
              style: TextStyle(fontSize: 12.5, color: AppColors.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Analyzing and starting the program's built-in uninstaller for the default uninstall",
                style: TextStyle(fontSize: 12.5, color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            const Icon(Icons.search_rounded, color: Color(0xFF0288D1), size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Scanning for leftover files, folders and registry items (${_scanMode.displayName} mode)...',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _scanProgress.clamp(0.0, 1.0),
            backgroundColor: AppColors.surfaceBorder,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            minHeight: 18,
          ),
        ),
        const Spacer(),
      ],
    );
  }

  // --- STAGE 4: LEFTOVERS REVIEW ---
  Widget _buildLeftoversView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Leftovers Tree View
        Expanded(
          child: LeftoverTreeView(
            items: _leftovers,
            onPathSelected: (path) {
              setState(() {
                _selectedPath = path;
              });
            },
            onItemToggled: () {
              setState(() {});
            },
          ),
        ),
        const SizedBox(height: 8),

        // Path indicator
        Row(
          children: [
            Text(
              'Path: ',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Text(
                  _selectedPath.isNotEmpty ? _selectedPath : 'Select a node above',
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'Consolas',
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Stats & Controls Row
        Row(
          children: [
            // Select All / Deselect All
            OutlinedButton(
              onPressed: _toggleSelectAll,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                side: BorderSide(color: AppColors.surfaceBorder),
              ),
              child: Text(
                _allSelected ? 'Deselect All' : 'Select All',
                style: TextStyle(fontSize: 11.5, color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(width: 8),

            // Delete Button
            ElevatedButton(
              onPressed: _leftovers.any((i) => i.isSelected && !i.isDeleted)
                  ? _deleteSelectedItems
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F).withValues(alpha: 0.15),
                foregroundColor: const Color(0xFFD32F2F),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                side: const BorderSide(color: Color(0xFFD32F2F)),
                elevation: 0,
              ),
              child: const Text(
                'Delete',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
              ),
            ),
            const Spacer(),

            // Stats Counter
            Text(
              'Keys: $_selectedRegistryKeysCount   Values: $_selectedRegistryValuesCount   Files: $_selectedFilesCount',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- STAGE 5: COMPLETED ---
  Widget _buildCompletedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 44),
          ),
          const SizedBox(height: 18),
          Text(
            'Uninstallation Completed!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.app.name} and all residual traces have been safely removed.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.surfaceBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_stage == WizardStage.confirmation) ...[
            _buildActionButton(
              label: 'Continue',
              onPressed: _onContinueFromConfirmation,
            ),
            const SizedBox(width: 10),
            _buildStandardButton(
              label: 'Cancel',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ] else if (_stage == WizardStage.analysis) ...[
            _buildActionButton(
              label: 'Scan',
              onPressed: _startScanning,
            ),
            const SizedBox(width: 10),
            _buildStandardButton(
              label: 'Cancel',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ] else if (_stage == WizardStage.scanning) ...[
            _buildStandardButton(
              label: 'Cancel',
              onPressed: () {
                _scanTimer?.cancel();
                Navigator.of(context).pop();
              },
            ),
          ] else if (_stage == WizardStage.leftovers) ...[
            _buildActionButton(
              label: 'Finish',
              onPressed: () {
                setState(() {
                  _stage = WizardStage.completed;
                });
                widget.onUninstallComplete();
              },
            ),
            const SizedBox(width: 10),
            _buildStandardButton(
              label: 'Cancel',
              onPressed: () {
                widget.onUninstallComplete();
                Navigator.of(context).pop();
              },
            ),
          ] else if (_stage == WizardStage.completed) ...[
            _buildActionButton(
              label: 'Close',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({required String label, required VoidCallback onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFF4B400),
        foregroundColor: const Color(0xFF212121),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        elevation: 1,
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStandardButton({required String label, required VoidCallback onPressed}) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        side: BorderSide(color: AppColors.surfaceBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12.5),
      ),
    );
  }
}
