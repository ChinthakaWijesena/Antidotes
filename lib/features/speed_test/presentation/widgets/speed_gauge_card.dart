import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/speed_test_result.dart';

/// Futuristic circular arc speedometer displaying real-time Mbps during speed testing.
class SpeedGaugeCard extends StatelessWidget {
  final double currentSpeed;
  final SpeedTestPhase phase;
  final double progress;
  final int remainingSeconds;
  final VoidCallback onStart;
  final VoidCallback onCancel;

  const SpeedGaugeCard({
    super.key,
    required this.currentSpeed,
    required this.phase,
    required this.progress,
    this.remainingSeconds = 0,
    required this.onStart,
    required this.onCancel,
  });

  bool get isTesting =>
      phase == SpeedTestPhase.pinging ||
      phase == SpeedTestPhase.downloading ||
      phase == SpeedTestPhase.uploading;

  String get _phaseLabel {
    switch (phase) {
      case SpeedTestPhase.idle:
        return 'READY';
      case SpeedTestPhase.fetchingMeta:
        return 'DETECTING ISP';
      case SpeedTestPhase.pinging:
        return 'TESTING PING';
      case SpeedTestPhase.downloading:
        return 'TESTING DOWNLOAD';
      case SpeedTestPhase.uploading:
        return 'TESTING UPLOAD';
      case SpeedTestPhase.completed:
        return 'TEST COMPLETE';
      case SpeedTestPhase.error:
        return 'INTERRUPTED';
    }
  }

  Color get _phaseColor {
    switch (phase) {
      case SpeedTestPhase.downloading:
        return const Color(0xFF00E676);
      case SpeedTestPhase.uploading:
        return const Color(0xFFFF9100);
      case SpeedTestPhase.pinging:
        return const Color(0xFF7E57C2);
      case SpeedTestPhase.completed:
        return AppColors.primary;
      case SpeedTestPhase.error:
        return AppColors.danger;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        children: [
          // Phase Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: _phaseColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _phaseColor.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: _phaseColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _phaseLabel,
                    style: TextStyle(
                      color: _phaseColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          if (isTesting && remainingSeconds > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.surfaceBorder, width: 0.8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer_outlined,
                      size: 13, color: AppColors.primary),
                  const SizedBox(width: 5),
                  Text(
                    '~${remainingSeconds}s remaining',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Consolas',
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 18),

          // Custom Arc Speedometer
          SizedBox(
            width: 220,
            height: 155,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _SpeedometerPainter(
                      speed: currentSpeed,
                      maxSpeed: currentSpeed > 180 ? 500.0 : 200.0,
                      color: _phaseColor,
                    ),
                  ),
                ),
                Positioned(
                  top: 48,
                  left: 0,
                  right: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currentSpeed.toStringAsFixed(1),
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1,
                          fontFamily: 'Consolas',
                        ),
                      ),
                      Text(
                        'Mbps',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Action Button
          SizedBox(
            width: 200,
            height: 44,
            child: isTesting
                ? OutlinedButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.stop_circle_outlined, size: 18),
                    label: const Text('Cancel Test'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: onStart,
                    icon: const Icon(Icons.bolt_rounded, size: 20),
                    label: Text(
                      phase == SpeedTestPhase.completed
                          ? 'Test Again'
                          : 'Start Speed Test',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: AppColors.primary.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SpeedometerPainter extends CustomPainter {
  final double speed;
  final double maxSpeed;
  final Color color;

  _SpeedometerPainter({
    required this.speed,
    required this.maxSpeed,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Positioned safely inside the 155px height box with 28px bottom clearance
    final center = Offset(size.width / 2, 78);
    const radius = 68.0;

    const startAngle = 135 * (math.pi / 180);
    const sweepAngle = 270 * (math.pi / 180);

    // Background track arc
    final bgPaint = Paint()
      ..color = AppColors.surfaceLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    // Active speed arc
    final fillRatio = (speed / maxSpeed).clamp(0.0, 1.0);
    final activeSweep = sweepAngle * fillRatio;

    if (activeSweep > 0.01) {
      final activePaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        activeSweep,
        false,
        activePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SpeedometerPainter oldDelegate) {
    return oldDelegate.speed != speed || oldDelegate.color != color;
  }
}
