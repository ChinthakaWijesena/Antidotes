import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme_scope.dart';
import '../../../../core/utils/file_size_formatter.dart';
import '../controllers/duplicate_finder_controller.dart';

class DuplicateFinderScreen extends StatefulWidget {
  const DuplicateFinderScreen({super.key});
  @override
  State<DuplicateFinderScreen> createState() => _DuplicateFinderScreenState();
}

class _DuplicateFinderScreenState extends State<DuplicateFinderScreen> {
  late final DuplicateFinderController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = DuplicateFinderController();
    _ctrl.addListener(() { if (mounted) setState(() {}); });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppThemeScope.of(context);
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
              _buildControls(),
              const SizedBox(height: 16),
              if (_ctrl.state == DupScanState.scanning) _buildProgress(),
              if (_ctrl.state == DupScanState.scanning) const SizedBox(height: 16),
              Expanded(child: _buildResults()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final wasted = _ctrl.totalWastedBytes;
    return Row(
      children: [
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.secondary.withValues(alpha: 0.4)),
          ),
          child: const Icon(Icons.copy_all_rounded, color: AppColors.secondary, size: 24),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Duplicate File Finder',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 22,
                    fontWeight: FontWeight.w700, letterSpacing: -0.5)),
            Text('Find identical files wasting disk space',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ],
        ),
        const Spacer(),
        if (wasted > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
            ),
            child: Text(
              '${FileSizeFormatter.format(wasted)} wasted',
              style: TextStyle(color: AppColors.warning, fontSize: 11,
                  fontWeight: FontWeight.w700),
            ),
          ),
      ],
    );
  }

  Widget _buildControls() {
    final scanning = _ctrl.state == DupScanState.scanning;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 620;

        final folderBox = Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Row(
            children: [
              Icon(Icons.folder_rounded, color: AppColors.secondary, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _ctrl.rootPath.isEmpty ? 'No folder selected' : _ctrl.rootPath,
                  style: TextStyle(
                      color: _ctrl.rootPath.isEmpty
                          ? AppColors.textMuted
                          : AppColors.textSecondary,
                      fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );

        final actionButtons = Row(
          mainAxisSize: isNarrow ? MainAxisSize.max : MainAxisSize.min,
          children: [
            isNarrow
                ? Expanded(
                    child: OutlinedButton.icon(
                      onPressed: scanning ? null : _ctrl.pickFolder,
                      icon: const Icon(Icons.folder_open_rounded, size: 16),
                      label: const Text('Browse'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: BorderSide(color: AppColors.surfaceBorder),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  )
                : OutlinedButton.icon(
                    onPressed: scanning ? null : _ctrl.pickFolder,
                    icon: const Icon(Icons.folder_open_rounded, size: 16),
                    label: const Text('Browse'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: BorderSide(color: AppColors.surfaceBorder),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
            const SizedBox(width: 10),
            isNarrow
                ? Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: scanning
                            ? _ctrl.cancelScan
                            : (_ctrl.rootPath.isEmpty ? null : _ctrl.startScan),
                        icon: Icon(
                          scanning ? Icons.stop_rounded : Icons.search_rounded,
                          size: 16,
                          color: AppColors.textPrimary,
                        ),
                        label: Text(
                          scanning ? 'Stop' : 'Find Duplicates',
                          style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              scanning ? AppColors.danger : AppColors.secondary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                        ),
                      ),
                    ),
                  )
                : SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: scanning
                          ? _ctrl.cancelScan
                          : (_ctrl.rootPath.isEmpty ? null : _ctrl.startScan),
                      icon: Icon(
                        scanning ? Icons.stop_rounded : Icons.search_rounded,
                        size: 16,
                        color: AppColors.textPrimary,
                      ),
                      label: Text(
                        scanning ? 'Stop' : 'Find Duplicates',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            scanning ? AppColors.danger : AppColors.secondary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                    ),
                  ),
          ],
        );

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: isNarrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    folderBox,
                    const SizedBox(height: 12),
                    actionButtons,
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: folderBox),
                    const SizedBox(width: 10),
                    actionButtons,
                  ],
                ),
        );
      },
    );
  }

  Widget _buildProgress() {
    final pct = _ctrl.totalFiles > 0
        ? _ctrl.filesHashed / _ctrl.totalFiles
        : 0.0;
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
                width: 18, height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: AppColors.secondary),
              ),
              const SizedBox(width: 12),
              Text(
                'Comparing files… ${_ctrl.filesHashed}/${_ctrl.totalFiles}',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: AppColors.surfaceBorder,
              color: AppColors.secondary,
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 4),
          Text(_ctrl.currentPath,
              style: TextStyle(color: AppColors.textMuted, fontSize: 10),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_ctrl.state == DupScanState.idle) {
      return _emptyState(Icons.copy_all_rounded,
          'Select a folder and click Find Duplicates',
          'Files with identical content will be grouped');
    }
    if (_ctrl.state == DupScanState.scanning && _ctrl.groups.isEmpty) {
      return _emptyState(Icons.search_rounded, 'Scanning…', 'Please wait while files are compared');
    }
    if (_ctrl.groups.isEmpty) {
      return _emptyState(Icons.check_circle_outline_rounded,
          'No duplicates found', 'All files in the selected folder are unique');
    }

    return Column(
      children: [
        // Action bar
        Row(
          children: [
            Text('${_ctrl.groups.length} duplicate group(s) found',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13,
                    fontWeight: FontWeight.w600)),
            const Spacer(),
            if (_ctrl.selectedForDelete.isNotEmpty)
              ElevatedButton.icon(
                onPressed: _deleteSelected,
                icon: const Icon(Icons.delete_forever_rounded, size: 16,
                    color: Colors.white),
                label: Text('Delete ${_ctrl.selectedForDelete.length} selected',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.separated(
            itemCount: _ctrl.groups.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _DuplicateGroupCard(
              group: _ctrl.groups[i],
              selectedForDelete: _ctrl.selectedForDelete,
              onToggle: _ctrl.toggleSelect,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _deleteSelected() async {
    final count = _ctrl.selectedForDelete.length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.surfaceBorder)),
        title: Text('Delete $count files?',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16,
                fontWeight: FontWeight.w700)),
        content: Text('This will permanently delete $count duplicate files. '
            'One copy of each group will be kept.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        actions: [
          OutlinedButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete All')),
        ],
      ),
    );
    if (ok == true) await _ctrl.deleteSelected();
  }

  Widget _emptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(color: AppColors.textSecondary,
              fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}

class _DuplicateGroupCard extends StatelessWidget {
  final dynamic group;
  final Set<String> selectedForDelete;
  final void Function(String) onToggle;
  const _DuplicateGroupCard({required this.group, required this.selectedForDelete, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final paths = group.paths as List<String>;
    final sizeBytes = group.sizeBytes as int;
    final wasted = group.wastedBytes as int;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        children: [
          // Group header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.layers_rounded, color: AppColors.secondary, size: 16),
                const SizedBox(width: 8),
                Text('${paths.length} identical files  •  ${FileSizeFormatter.format(sizeBytes)} each',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12,
                        fontWeight: FontWeight.w600)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${FileSizeFormatter.format(wasted)} wasted',
                      style: TextStyle(color: AppColors.warning, fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          Divider(color: AppColors.surfaceBorder, height: 1),
          ...paths.asMap().entries.map((e) {
            final idx  = e.key;
            final path = e.value;
            final name = path.split(RegExp(r'[/\\]')).last;
            final isFirst = idx == 0;
            final isChecked = selectedForDelete.contains(path);
            return Container(
              color: isFirst ? AppColors.success.withValues(alpha: 0.04) : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    if (isFirst)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('KEEP', style: TextStyle(color: AppColors.success,
                            fontSize: 8, fontWeight: FontWeight.w700)),
                      )
                    else
                      Checkbox(
                        value: isChecked,
                        onChanged: (_) => onToggle(path),
                        activeColor: AppColors.danger,
                        side: BorderSide(color: AppColors.textMuted),
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: TextStyle(
                                  color: isFirst ? AppColors.textPrimary : AppColors.textSecondary,
                                  fontSize: 12, fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis),
                          Text(path,
                              style: TextStyle(color: AppColors.textMuted, fontSize: 10),
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
