import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../controllers/auto_updater_controller.dart';
import 'update_available_dialog.dart';

/// Card displayed inside Windows Settings & Tools allowing users to view current version
/// and manually trigger a check for updates online.
class AppUpdateCard extends StatefulWidget {
  final AutoUpdaterController controller;

  const AppUpdateCard({
    super.key,
    required this.controller,
  });

  @override
  State<AppUpdateCard> createState() => _AppUpdateCardState();
}

class _AppUpdateCardState extends State<AppUpdateCard> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _handleCheckUpdates() async {
    final hasUpdate = await widget.controller.checkForUpdates(silent: false);
    if (!mounted) return;

    if (hasUpdate && widget.controller.updateInfo != null) {
      UpdateAvailableDialog.show(
        context,
        widget.controller.updateInfo!,
        widget.controller,
      );
    } else if (widget.controller.status == UpdateStatus.upToDate) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Antidotes is up to date (Version ${widget.controller.updateInfo?.currentVersion ?? "1.0.0"})',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (widget.controller.status == UpdateStatus.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.controller.errorMessage ?? 'Could not check for updates. Check internet connection.',
          ),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isChecking = widget.controller.status == UpdateStatus.checking;
    final currentVer = widget.controller.updateInfo?.currentVersion ?? '1.0.7';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 620;

        final iconBox = Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.25),
            ),
          ),
          child: Icon(
            Icons.update_rounded,
            color: AppColors.primary,
            size: 24,
          ),
        );

        final textBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(
                  'Antidotes Updates',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBorder,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'v$currentVer',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              'Keep Antidotes updated with the latest performance algorithms, cleaning rules & security patches',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ],
        );

        final checkButton = ElevatedButton.icon(
          onPressed: isChecking ? null : _handleCheckUpdates,
          icon: isChecking
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.sync_rounded, size: 16),
          label: Text(isChecking ? 'Checking…' : 'Check for Updates'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 0,
          ),
        );

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: isNarrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        iconBox,
                        const SizedBox(width: 14),
                        Expanded(child: textBlock),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerRight,
                      child: checkButton,
                    ),
                  ],
                )
              : Row(
                  children: [
                    iconBox,
                    const SizedBox(width: 16),
                    Expanded(child: textBlock),
                    const SizedBox(width: 16),
                    checkButton,
                  ],
                ),
        );
      },
    );
  }
}
