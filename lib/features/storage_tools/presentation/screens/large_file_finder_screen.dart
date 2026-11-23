import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme_scope.dart';
import '../../../../core/utils/file_size_formatter.dart';
import '../controllers/large_file_controller.dart';

class LargeFileFinderScreen extends StatefulWidget {
  const LargeFileFinderScreen({super.key});
  @override
  State<LargeFileFinderScreen> createState() => _LargeFileFinderScreenState();
}

class _LargeFileFinderScreenState extends State<LargeFileFinderScreen> {
  late final LargeFileController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = LargeFileController();
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
              if (_ctrl.state == ScanState.scanning) _buildProgress(),
              if (_ctrl.state != ScanState.idle) const SizedBox(height: 16),
              Expanded(child: _buildResults()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Icon(Icons.storage_rounded, color: AppColors.primary, size: 24),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Large File Finder',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 22,
                    fontWeight: FontWeight.w700, letterSpacing: -0.5)),
            Text('Scan drives for the biggest space-wasting files',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ],
        ),
        const Spacer(),
        if (_ctrl.state == ScanState.done)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
            ),
            child: Text('${_ctrl.results.length} files found',
                style: TextStyle(color: AppColors.primary, fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ),
      ],
    );
  }

  Widget _buildControls() {
    final scanning = _ctrl.state == ScanState.scanning;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.folder_rounded, color: AppColors.primary, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _ctrl.rootPath,
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: scanning ? null : _ctrl.pickFolder,
                icon: const Icon(Icons.folder_open_rounded, size: 16),
                label: const Text('Browse'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: BorderSide(color: AppColors.surfaceBorder),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Min size:', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ...([50, 100, 250, 500, 1024]).map((mb) => GestureDetector(
                onTap: scanning ? null : () => _ctrl.setMinSizeMb(mb),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _ctrl.minSizeMb == mb
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _ctrl.minSizeMb == mb
                          ? AppColors.primary.withValues(alpha: 0.5)
                          : AppColors.surfaceBorder,
                    ),
                  ),
                  child: Text(
                    mb >= 1024 ? '${mb ~/ 1024} GB' : '$mb MB',
                    style: TextStyle(
                      color: _ctrl.minSizeMb == mb ? AppColors.primary : AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )),
              SizedBox(
                height: 36,
                child: ElevatedButton.icon(
                  onPressed: scanning ? _ctrl.cancelScan : _ctrl.startScan,
                  icon: Icon(
                    scanning ? Icons.stop_rounded : Icons.search_rounded,
                    size: 16,
                    color: AppColors.textPrimary,
                  ),
                  label: Text(
                    scanning ? 'Stop' : 'Scan',
                    style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: scanning ? AppColors.danger : AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgress() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 18, height: 18,
            child: CircularProgressIndicator(
                strokeWidth: 2.5, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Scanning… ${_ctrl.filesScanned} files checked',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12,
                        fontWeight: FontWeight.w600)),
                Text(_ctrl.currentPath,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 10),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_ctrl.state == ScanState.idle) {
      return _emptyState(
        icon: Icons.storage_rounded,
        title: 'Select a folder and click Scan',
        subtitle: 'Large files (default ≥ 100 MB) will appear here',
      );
    }
    if (_ctrl.state == ScanState.scanning && _ctrl.results.isEmpty) {
      return _emptyState(
        icon: Icons.search_rounded,
        title: 'Scanning…',
        subtitle: 'Results will appear as files are found',
      );
    }
    if (_ctrl.results.isEmpty) {
      return _emptyState(
        icon: Icons.check_circle_outline_rounded,
        title: 'No large files found',
        subtitle: 'Try lowering the minimum size filter',
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(child: Text('FILE NAME', style: _headerStyle())),
                SizedBox(width: 220,
                    child: Text('PATH', style: _headerStyle())),
                SizedBox(width: 90,
                    child: Text('SIZE', style: _headerStyle(), textAlign: TextAlign.right)),
                const SizedBox(width: 80),
              ],
            ),
          ),
          Divider(color: AppColors.surfaceBorder, height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: _ctrl.results.length,
              separatorBuilder: (context, index) =>
                  Divider(color: AppColors.surfaceBorder, height: 1),
              itemBuilder: (_, i) => _FileRow(
                item: _ctrl.results[i],
                onOpenLocation: () => _ctrl.openFileLocation(_ctrl.results[i].path),
                onDelete: () => _confirmDelete(i),
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _headerStyle() => TextStyle(
    color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w700,
    letterSpacing: 1.1,
  );

  Future<void> _confirmDelete(int index) async {
    final item = _ctrl.results[index];
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.surfaceBorder)),
        title: Text('Delete File?',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16,
                fontWeight: FontWeight.w700)),
        content: Text('This will permanently delete:\n${item.name}\n'
            '(${FileSizeFormatter.format(item.sizeBytes)})',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        actions: [
          OutlinedButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) await _ctrl.deleteFile(item.path);
  }

  Widget _emptyState({required IconData icon, required String title, required String subtitle}) {
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

class _FileRow extends StatelessWidget {
  final dynamic item;
  final VoidCallback onOpenLocation;
  final VoidCallback onDelete;
  const _FileRow({required this.item, required this.onOpenLocation, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final ext = item.extension as String;
    final color = _extColor(ext);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                ext.isEmpty ? '?' : ext.toUpperCase().substring(0, ext.length.clamp(0, 3)),
                style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(item.name as String,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                overflow: TextOverflow.ellipsis),
          ),
          SizedBox(
            width: 220,
            child: Text(item.path as String,
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                overflow: TextOverflow.ellipsis),
          ),
          SizedBox(
            width: 90,
            child: Text(
              FileSizeFormatter.format(item.sizeBytes as int),
              style: TextStyle(color: AppColors.warning, fontSize: 13,
                  fontWeight: FontWeight.w700),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 10),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.folder_open_rounded,
                    color: AppColors.primary, size: 18),
                tooltip: 'Open location',
                onPressed: onOpenLocation,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline_rounded,
                    color: AppColors.danger, size: 18),
                tooltip: 'Delete file',
                onPressed: onDelete,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _extColor(String ext) {
    return switch (ext) {
      'iso' || 'img' => const Color(0xFF38BDF8),
      'zip' || 'rar' || '7z' || 'tar' || 'gz' => const Color(0xFFFBBF24),
      'mp4' || 'mkv' || 'avi' || 'mov' || 'wmv' => const Color(0xFFA78BFA),
      'mp3' || 'flac' || 'wav' => const Color(0xFF34D399),
      'pdf' => const Color(0xFFEF4444),
      'exe' || 'msi' => const Color(0xFF60A5FA),
      _ => const Color(0xFF94A3B8),
    };
  }
}
