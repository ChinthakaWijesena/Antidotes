import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme_scope.dart';
import '../../../../core/utils/file_size_formatter.dart';
import '../../data/models/shred_models.dart';
import '../controllers/file_shredder_controller.dart';

class FileShredderScreen extends StatefulWidget {
  const FileShredderScreen({super.key});
  @override
  State<FileShredderScreen> createState() => _FileShredderScreenState();
}

class _FileShredderScreenState extends State<FileShredderScreen> {
  late final FileShredderController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = FileShredderController();
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
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      _buildAlgorithmCard(),
                      const SizedBox(height: 14),
                      _buildQueueCard(),
                      const SizedBox(height: 14),
                      _buildShredButton(),
                      if (_ctrl.state == ShredState.shredding) ...[
                        const SizedBox(height: 14),
                        _buildProgress(),
                      ],
                      if (_ctrl.lastResult != null &&
                          _ctrl.state == ShredState.done) ...[
                        const SizedBox(height: 14),
                        _buildResult(),
                      ],
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
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
            color: AppColors.danger.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
          ),
          child: Icon(Icons.shield_rounded, color: AppColors.danger, size: 24),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('File Shredder',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 22,
                    fontWeight: FontWeight.w700, letterSpacing: -0.5)),
            Text('Permanently destroy files — unrecoverable by any software',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ],
        ),
      ],
    );
  }

  // ── Algorithm selector ────────────────────────────────────────────────────
  Widget _buildAlgorithmCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security_rounded, color: AppColors.danger, size: 15),
              const SizedBox(width: 8),
              Text('SHRED ALGORITHM', style: TextStyle(
                  color: AppColors.textMuted, fontSize: 10,
                  fontWeight: FontWeight.w700, letterSpacing: 1.3)),
            ],
          ),
          const SizedBox(height: 12),
          ...ShredAlgorithm.values.map((algo) {
            final selected = _ctrl.algorithm == algo;
            return GestureDetector(
              onTap: _ctrl.state == ShredState.shredding
                  ? null
                  : () => _ctrl.setAlgorithm(algo),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.danger.withValues(alpha: 0.08)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected
                        ? AppColors.danger.withValues(alpha: 0.5)
                        : AppColors.surfaceBorder,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Center(
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected ? AppColors.danger : AppColors.textMuted,
                              width: 2,
                            ),
                          ),
                          child: selected
                              ? Center(
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.danger,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(algo.displayName,
                              style: TextStyle(
                                color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                                fontSize: 13, fontWeight: FontWeight.w600,
                              )),
                          Text(algo.description,
                              style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.danger.withValues(alpha: 0.1)
                            : AppColors.surfaceBorder.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('${algo.passes} pass${algo.passes > 1 ? 'es' : ''}',
                          style: TextStyle(
                            color: selected ? AppColors.danger : AppColors.textMuted,
                            fontSize: 10, fontWeight: FontWeight.w700,
                          )),
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

  // ── File queue card ────────────────────────────────────────────────────────
  Widget _buildQueueCard() {
    final shredding = _ctrl.state == ShredState.shredding;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
            child: Row(
              children: [
                Icon(Icons.playlist_add_rounded, color: AppColors.danger, size: 15),
                const SizedBox(width: 8),
                Text('FILES TO SHRED', style: TextStyle(
                    color: AppColors.textMuted, fontSize: 10,
                    fontWeight: FontWeight.w700, letterSpacing: 1.3)),
                const Spacer(),
                if (_ctrl.queue.isNotEmpty) ...[
                  TextButton.icon(
                    onPressed: shredding ? null : _ctrl.clearQueue,
                    icon: const Icon(Icons.clear_all_rounded, size: 14),
                    label: const Text('Clear all', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(foregroundColor: AppColors.textMuted),
                  ),
                  const SizedBox(width: 8),
                ],
                OutlinedButton.icon(
                  onPressed: shredding ? null : _ctrl.addFilesFromPicker,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Add Files'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: BorderSide(color: AppColors.danger.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
          Divider(color: AppColors.surfaceBorder, height: 1),

          if (_ctrl.queue.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Column(
                children: [
                  Icon(Icons.upload_file_rounded, size: 36, color: AppColors.textMuted),
                  const SizedBox(height: 8),
                  Text('No files added', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text('Click "Add Files" to select files for shredding',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                ],
              ),
            )
          else
            ...(_ctrl.queue.asMap().entries.map((e) {
              final path = e.value;
              final name = path.split(RegExp(r'[/\\]')).last;
              int? size;
              try {
                size = File(path).statSync().size;
              } catch (_) {}
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        Icon(Icons.insert_drive_file_rounded,
                            color: AppColors.danger, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: TextStyle(
                                  color: AppColors.textPrimary, fontSize: 13),
                                  overflow: TextOverflow.ellipsis),
                              Text(path, style: TextStyle(
                                  color: AppColors.textMuted, fontSize: 10),
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        if (size != null)
                          Text(FileSizeFormatter.format(size),
                              style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: shredding ? null : () => _ctrl.removeFromQueue(path),
                          icon: Icon(Icons.close_rounded,
                              color: AppColors.textMuted, size: 16),
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                  Divider(color: AppColors.surfaceBorder, height: 1,
                      indent: 16, endIndent: 16),
                ],
              );
            })),
        ],
      ),
    );
  }

  // ── Shred button ───────────────────────────────────────────────────────────
  Widget _buildShredButton() {
    final shredding = _ctrl.state == ShredState.shredding;
    final empty = _ctrl.queue.isEmpty;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: (shredding || empty) ? null : _confirmShred,
        icon: shredding
            ? SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: AppColors.textPrimary))
            : Icon(Icons.local_fire_department_rounded,
                color: AppColors.textPrimary, size: 22),
        label: Text(
          shredding
              ? 'Shredding ${_ctrl.currentIndex}/${_ctrl.queue.length + _ctrl.currentIndex - 1}…'
              : empty
                  ? 'Add files to shred'
                  : '🔥  Shred ${_ctrl.queue.length} file${_ctrl.queue.length > 1 ? "s" : ""} permanently',
          style: TextStyle(color: AppColors.textPrimary,
              fontWeight: FontWeight.w700, fontSize: 14),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: empty ? AppColors.surfaceBorder : AppColors.danger,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
    );
  }

  // ── Progress ──────────────────────────────────────────────────────────────
  Widget _buildProgress() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2.5, color: AppColors.danger),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Shredding file ${_ctrl.currentIndex}…',
                    style: TextStyle(color: AppColors.textSecondary,
                        fontSize: 13, fontWeight: FontWeight.w600)),
                Text(_ctrl.currentFile,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Result ────────────────────────────────────────────────────────────────
  Widget _buildResult() {
    final r = _ctrl.lastResult!;
    final color = r.failCount == 0 ? AppColors.success : AppColors.warning;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(r.failCount == 0
              ? Icons.check_circle_rounded
              : Icons.warning_amber_rounded,
              color: color, size: 22),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${r.successCount} file${r.successCount != 1 ? "s" : ""} permanently destroyed',
                  style: TextStyle(color: color, fontSize: 14,
                      fontWeight: FontWeight.w700)),
              if (r.failCount > 0)
                Text('${r.failCount} file${r.failCount != 1 ? "s" : ""} could not be shredded',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmShred() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.surfaceBorder)),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: AppColors.danger, size: 22),
            const SizedBox(width: 10),
            Text('Permanently Destroy Files?',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 15,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(
          '${_ctrl.queue.length} file${_ctrl.queue.length > 1 ? "s" : ""} will be '
          'overwritten with ${_ctrl.algorithm.passes} passes of random data '
          'and permanently deleted.\n\nThis action CANNOT be undone.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
        ),
        actions: [
          OutlinedButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Shred Forever',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok == true) await _ctrl.shredAll();
  }
}
