import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/speed_test_result.dart';

/// Renders the 4 primary test metrics: Download, Upload, Ping, and Jitter.
class SpeedMetricsGrid extends StatelessWidget {
  final SpeedTestResult? result;
  final double currentLiveSpeed;
  final SpeedTestPhase phase;

  const SpeedMetricsGrid({
    super.key,
    required this.result,
    required this.currentLiveSpeed,
    required this.phase,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDownloading = phase == SpeedTestPhase.downloading;
    final bool isUploading = phase == SpeedTestPhase.uploading;

    final downloadVal = isDownloading
        ? '${currentLiveSpeed.toStringAsFixed(1)} Mbps'
        : (result != null ? '${result!.downloadMbps.toStringAsFixed(1)} Mbps' : '-- Mbps');

    final uploadVal = isUploading
        ? '${currentLiveSpeed.toStringAsFixed(1)} Mbps'
        : (result != null ? '${result!.uploadMbps.toStringAsFixed(1)} Mbps' : '-- Mbps');

    final pingVal = result != null ? '${result!.pingMs} ms' : '-- ms';
    final jitterVal = result != null ? '${result!.jitterMs} ms' : '-- ms';

    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            Expanded(
              child: _MetricTile(
                title: 'Download',
                value: downloadVal,
                icon: Icons.arrow_downward_rounded,
                accentColor: const Color(0xFF00E676),
                isActive: isDownloading,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricTile(
                title: 'Upload',
                value: uploadVal,
                icon: Icons.arrow_upward_rounded,
                accentColor: const Color(0xFFFF9100),
                isActive: isUploading,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricTile(
                title: 'Ping',
                value: pingVal,
                icon: Icons.bolt_rounded,
                accentColor: const Color(0xFF7E57C2),
                isActive: phase == SpeedTestPhase.pinging,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricTile(
                title: 'Jitter',
                value: jitterVal,
                icon: Icons.graphic_eq_rounded,
                accentColor: const Color(0xFF00B0FF),
                isActive: phase == SpeedTestPhase.pinging,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;
  final bool isActive;

  const _MetricTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? accentColor.withValues(alpha: 0.6)
              : AppColors.surfaceBorder,
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: accentColor),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Consolas',
            ),
          ),
        ],
      ),
    );
  }
}
