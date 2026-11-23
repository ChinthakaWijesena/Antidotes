import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/ram_snapshot.dart';

/// Circular RAM usage meter widget.
class RamUsageMeter extends StatelessWidget {
  final RamSnapshot snapshot;
  final double size;

  const RamUsageMeter({
    super.key,
    required this.snapshot,
    this.size = 180,
  });

  @override
  Widget build(BuildContext context) {
    final pct = snapshot.usedPercent / 100;
    final color = _meterColor(snapshot.usedPercent);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Arc background
          CustomPaint(
            size: Size(size, size),
            painter: _ArcPainter(progress: 1.0, color: AppColors.surfaceBorder),
          ),
          // Arc foreground
          CustomPaint(
            size: Size(size, size),
            painter: _ArcPainter(progress: pct, color: color),
          ),
          // Centre text
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${snapshot.usedPercent.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: color,
                  fontSize: size * 0.18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'USED',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: size * 0.09,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _meterColor(double pct) {
    if (pct < 60) return AppColors.success;
    if (pct < 80) return AppColors.warning;
    return AppColors.danger;
  }
}

class _ArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  const _ArcPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.09;
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width - stroke,
      height: size.height - stroke,
    );
    final paint = Paint()
      ..color = color
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const startAngle = 2.356; // ~135°
    const sweepFull = 4.712; // ~270°
    canvas.drawArc(rect, startAngle, sweepFull * progress, false, paint);
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.progress != progress || old.color != color;
}
