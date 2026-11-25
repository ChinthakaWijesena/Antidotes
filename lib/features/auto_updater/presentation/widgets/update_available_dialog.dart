import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/update_info.dart';
import '../controllers/auto_updater_controller.dart';

/// Modal dialog styled identically to modern desktop updaters (e.g. Driver Booster)
/// featuring Antidotes dark glassmorphism theme, release notes, and in-place download progress.
class UpdateAvailableDialog extends StatefulWidget {
  final UpdateInfo updateInfo;
  final AutoUpdaterController controller;

  const UpdateAvailableDialog({
    super.key,
    required this.updateInfo,
    required this.controller,
  });

  /// Displays the modal dialog over the active navigator
  static Future<void> show(
    BuildContext context,
    UpdateInfo updateInfo,
    AutoUpdaterController controller,
  ) {
    return showDialog<void>(
      context: context,
      barrierDismissible: !updateInfo.isMandatory && !controller.isDownloading,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => UpdateAvailableDialog(
        updateInfo: updateInfo,
        controller: controller,
      ),
    );
  }

  @override
  State<UpdateAvailableDialog> createState() => _UpdateAvailableDialogState();
}

class _UpdateAvailableDialogState extends State<UpdateAvailableDialog> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChange);
    super.dispose();
  }

  void _onControllerChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.updateInfo;
    final ctrl = widget.controller;
    final isDownloading = ctrl.isDownloading;
    final isReady = ctrl.status == UpdateStatus.readyToInstall;
    final hasError = ctrl.status == UpdateStatus.error;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 540,
          constraints: const BoxConstraints(maxHeight: 600),
          decoration: BoxDecoration(
            color: const Color(0xFF1E232B), // Modern dark desktop updater tone
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 36,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Top Title Bar ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 14, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Antidotes Updater',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (!info.isMandatory && !isDownloading)
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              Divider(
                color: Colors.white.withValues(alpha: 0.08),
                height: 1,
              ),

              // ── Header (Icon + Title + Subtitle) ──────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Circular glowing app update icon
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFF13171D),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.6),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.system_update_alt_rounded,
                            color: AppColors.primary,
                            size: 26,
                          ),
                          Positioned(
                            right: 4,
                            bottom: 4,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Color(0xFF13171D),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.sync_rounded,
                                color: Color(0xFF52C41A),
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'A new version is available!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Antidotes ${info.latestVersion} is now available. Click "Update Now" to get the latest features and improvements.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.72),
                              fontSize: 12.5,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── "What's New" Section ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  "What's New",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Changelog Box
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 180),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14171C),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Version & Release Date Header
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'V${info.latestVersion} ${info.releaseDate}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Bullet Points
                        if (info.changelog.isEmpty)
                          Text(
                            '• Performance optimizations and stability improvements.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 12,
                              height: 1.5,
                            ),
                          )
                        else
                          ...info.changelog.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6, right: 10),
                                    child: Container(
                                      width: 4,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.4),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      item,
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.8),
                                        fontSize: 12,
                                        height: 1.45,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Download Progress Bar (if active) ─────────────────────────
              if (isDownloading || isReady) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isReady
                                ? 'Download completed! Starting installer...'
                                : 'Downloading update... ${(ctrl.downloadProgress * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: isReady ? AppColors.success : AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (isDownloading)
                            Text(
                              'Please wait',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: isReady ? 1.0 : ctrl.downloadProgress,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          color: isReady ? const Color(0xFF52C41A) : AppColors.primary,
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // ── Error Message ─────────────────────────────────────────────
              if (hasError && ctrl.errorMessage != null) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    ctrl.errorMessage!,
                    style: const TextStyle(
                      color: Color(0xFFFF4D4F),
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // ── Bottom Action Bar ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left "Decide later" button
                    if (!info.isMandatory && !isDownloading)
                      TextButton(
                        onPressed: () {
                          ctrl.dismissVersion(info.latestVersion);
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white.withValues(alpha: 0.6),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        child: const Text(
                          'Decide later',
                          style: TextStyle(
                            decoration: TextDecoration.underline,
                            fontSize: 13,
                          ),
                        ),
                      )
                    else
                      const SizedBox.shrink(),

                    // Right "Update Now" action button
                    ElevatedButton(
                      onPressed: (isDownloading || isReady)
                          ? null
                          : () => ctrl.startDownloadAndInstall(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: Colors.white.withValues(alpha: 0.15),
                        disabledForegroundColor: Colors.white.withValues(alpha: 0.4),
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isDownloading) ...[
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('Downloading…'),
                          ] else if (isReady) ...[
                            const Icon(Icons.check_circle_rounded, size: 16),
                            const SizedBox(width: 6),
                            const Text('Installing…'),
                          ] else ...[
                            const Text(
                              'Update Now',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                            ),
                          ],
                        ],
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
  }
}
