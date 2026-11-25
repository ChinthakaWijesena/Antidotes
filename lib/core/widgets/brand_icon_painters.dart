import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Pixel-perfect vector brand painters for popular desktop applications.
/// Provides authentic, resolution-independent brand graphics with 0ms load time.

/// 1. Spotify - Iconic green circle with 3 curved sound waves
class SpotifyPainter extends CustomPainter {
  const SpotifyPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Green disc
    final bgPaint = Paint()
      ..color = const Color(0xFF1DB954)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawCircle(center, radius, bgPaint);

    final wavePaint = Paint()
      ..color = const Color(0xFF121212)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    // Offset center for the sound arcs (slightly down-left)
    final arcCenter = Offset(size.width * 0.46, size.height * 0.60);

    // Top arc
    wavePaint.strokeWidth = size.width * 0.082;
    final r1 = size.width * 0.44;
    canvas.drawArc(
      Rect.fromCircle(center: arcCenter, radius: r1),
      -math.pi * 0.68,
      math.pi * 0.38,
      false,
      wavePaint,
    );

    // Middle arc
    wavePaint.strokeWidth = size.width * 0.075;
    final r2 = size.width * 0.32;
    canvas.drawArc(
      Rect.fromCircle(center: arcCenter, radius: r2),
      -math.pi * 0.69,
      math.pi * 0.39,
      false,
      wavePaint,
    );

    // Bottom arc
    wavePaint.strokeWidth = size.width * 0.068;
    final r3 = size.width * 0.20;
    canvas.drawArc(
      Rect.fromCircle(center: arcCenter, radius: r3),
      -math.pi * 0.70,
      math.pi * 0.40,
      false,
      wavePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 2. Google Chrome - 4-color segmented disc
class ChromePainter extends CustomPainter {
  const ChromePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final p = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Red sector (top)
    p.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, -math.pi * 0.75, math.pi * 0.72, true, p);

    // Yellow sector (right)
    p.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, -math.pi * 0.03, math.pi * 0.68, true, p);

    // Green sector (bottom-left)
    p.color = const Color(0xFF34A853);
    canvas.drawArc(rect, math.pi * 0.65, math.pi * 0.60, true, p);

    // White ring
    p.color = Colors.white;
    canvas.drawCircle(center, radius * 0.48, p);

    // Blue center
    p.color = const Color(0xFF4285F4);
    canvas.drawCircle(center, radius * 0.38, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 3. Mozilla Firefox - Purple/blue globe with fiery orange/red tail
class FirefoxPainter extends CustomPainter {
  const FirefoxPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Inner globe (deep blue/purple)
    final globePaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFF301569), Color(0xFF1F0C42)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..isAntiAlias = true;
    canvas.drawCircle(center, radius * 0.75, globePaint);

    // Fiery outer swoosh (orange/red fox silhouette)
    final firePaint = Paint()
      ..shader = const SweepGradient(
        colors: [
          Color(0xFFFF2A00),
          Color(0xFFFF9400),
          Color(0xFFFFD000),
          Color(0xFFFF7139),
          Color(0xFFFF2A00),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.22
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.85),
      -math.pi * 0.8,
      math.pi * 1.6,
      false,
      firePaint,
    );

    // Cute fox ear top-left
    final earPaint = Paint()
      ..color = const Color(0xFFFF9400)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final earPath = Path()
      ..moveTo(size.width * 0.22, size.height * 0.28)
      ..lineTo(size.width * 0.32, size.height * 0.12)
      ..lineTo(size.width * 0.44, size.height * 0.22)
      ..close();
    canvas.drawPath(earPath, earPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 4. Microsoft Edge - Modern wave swirl
class EdgePainter extends CustomPainter {
  const EdgePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0078D7), Color(0xFF00C7FF), Color(0xFF107C41)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawCircle(center, radius, bgPaint);

    // Swirl cutout
    final innerPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final path = Path()
      ..moveTo(size.width * 0.5, size.height * 0.28)
      ..quadraticBezierTo(size.width * 0.85, size.height * 0.35, size.width * 0.65, size.height * 0.75)
      ..quadraticBezierTo(size.width * 0.45, size.height * 0.95, size.width * 0.3, size.height * 0.7)
      ..quadraticBezierTo(size.width * 0.2, size.height * 0.4, size.width * 0.5, size.height * 0.4)
      ..close();

    canvas.drawPath(path, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 5. Discord - Blurple background with Clyde controller mascot
class DiscordPainter extends CustomPainter {
  const DiscordPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = const Color(0xFF5865F2)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(size.width * 0.24),
    );
    canvas.drawRRect(rrect, bgPaint);

    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Clyde face shape
    final w = size.width;
    final h = size.height;
    final clyde = Path()
      ..moveTo(w * 0.26, h * 0.36)
      ..cubicTo(w * 0.32, h * 0.32, w * 0.42, h * 0.30, w * 0.50, h * 0.30)
      ..cubicTo(w * 0.58, h * 0.30, w * 0.68, h * 0.32, w * 0.74, h * 0.36)
      ..lineTo(w * 0.78, h * 0.64)
      ..cubicTo(w * 0.72, h * 0.68, w * 0.62, h * 0.70, w * 0.56, h * 0.68)
      ..lineTo(w * 0.53, h * 0.63)
      ..lineTo(w * 0.47, h * 0.63)
      ..lineTo(w * 0.44, h * 0.68)
      ..cubicTo(w * 0.38, h * 0.70, w * 0.28, h * 0.68, w * 0.22, h * 0.64)
      ..close();

    canvas.drawPath(clyde, whitePaint);

    // Eye cutouts
    final blurplePaint = Paint()
      ..color = const Color(0xFF5865F2)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.38, h * 0.48), width: w * 0.12, height: h * 0.14),
      blurplePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.62, h * 0.48), width: w * 0.12, height: h * 0.14),
      blurplePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 6. Telegram - Blue circle with white paper airplane
class TelegramPainter extends CustomPainter {
  const TelegramPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF2AABEE), Color(0xFF229ED9)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..isAntiAlias = true;
    canvas.drawCircle(center, radius, bgPaint);

    final planePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final w = size.width;
    final h = size.height;

    final plane = Path()
      ..moveTo(w * 0.78, h * 0.24)
      ..lineTo(w * 0.20, h * 0.48)
      ..lineTo(w * 0.38, h * 0.56)
      ..lineTo(w * 0.42, h * 0.72)
      ..lineTo(w * 0.52, h * 0.62)
      ..lineTo(w * 0.68, h * 0.74)
      ..close();

    canvas.drawPath(plane, planePaint);

    // Fold shadow
    final foldPaint = Paint()
      ..color = const Color(0xFFD2EAF6)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final fold = Path()
      ..moveTo(w * 0.38, h * 0.56)
      ..lineTo(w * 0.42, h * 0.72)
      ..lineTo(w * 0.52, h * 0.62)
      ..close();
    canvas.drawPath(fold, foldPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 7. WhatsApp - Emerald green bubble with phone handset
class WhatsAppPainter extends CustomPainter {
  const WhatsAppPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final bgPaint = Paint()
      ..color = const Color(0xFF25D366)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawCircle(center, radius, bgPaint);

    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Chat bubble
    canvas.drawCircle(Offset(center.dx, center.dy - size.height * 0.03), radius * 0.70, whitePaint);

    // Speech pointer
    final w = size.width;
    final h = size.height;
    final tail = Path()
      ..moveTo(w * 0.28, h * 0.62)
      ..lineTo(w * 0.22, h * 0.78)
      ..lineTo(w * 0.42, h * 0.72)
      ..close();
    canvas.drawPath(tail, whitePaint);

    // Green phone icon inside
    final greenPaint = Paint()
      ..color = const Color(0xFF25D366)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final phone = Path()
      ..moveTo(w * 0.36, h * 0.42)
      ..cubicTo(w * 0.38, h * 0.36, w * 0.44, h * 0.36, w * 0.48, h * 0.40)
      ..lineTo(w * 0.52, h * 0.46)
      ..cubicTo(w * 0.54, h * 0.49, w * 0.53, h * 0.53, w * 0.50, h * 0.55)
      ..cubicTo(w * 0.52, h * 0.59, w * 0.55, h * 0.62, w * 0.59, h * 0.64)
      ..cubicTo(w * 0.61, h * 0.61, w * 0.65, h * 0.60, w * 0.68, h * 0.62)
      ..lineTo(w * 0.74, h * 0.66)
      ..cubicTo(w * 0.78, h * 0.70, w * 0.78, h * 0.76, w * 0.72, h * 0.78)
      ..cubicTo(w * 0.54, h * 0.82, w * 0.32, h * 0.60, w * 0.36, h * 0.42)
      ..close();
    canvas.drawPath(phone, greenPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 8. Visual Studio Code - Angled folded infinity ribbon
class VSCodePainter extends CustomPainter {
  const VSCodePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background squircle
    final bgPaint = Paint()
      ..color = const Color(0xFF007ACC)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), Radius.circular(w * 0.22)),
      bgPaint,
    );

    // White ribbon lines
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final rightFin = Path()
      ..moveTo(w * 0.74, h * 0.16)
      ..lineTo(w * 0.86, h * 0.24)
      ..lineTo(w * 0.86, h * 0.76)
      ..lineTo(w * 0.74, h * 0.84)
      ..close();
    canvas.drawPath(rightFin, whitePaint);

    final leftFold = Path()
      ..moveTo(w * 0.68, h * 0.24)
      ..lineTo(w * 0.20, h * 0.44)
      ..lineTo(w * 0.20, h * 0.56)
      ..lineTo(w * 0.68, h * 0.76)
      ..close();

    final lightPaint = Paint()
      ..color = const Color(0xFFE0F2FE)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawPath(leftFold, lightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 9. VLC Media Player - Traffic Cone
class VLCPainter extends CustomPainter {
  const VLCPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Orange cone
    final orangePaint = Paint()
      ..color = const Color(0xFFFF8800)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Cone base plate
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.12, h * 0.80, w * 0.76, h * 0.12),
        Radius.circular(w * 0.05),
      ),
      orangePaint,
    );

    // Cone body
    final cone = Path()
      ..moveTo(w * 0.42, h * 0.14)
      ..lineTo(w * 0.58, h * 0.14)
      ..lineTo(w * 0.74, h * 0.80)
      ..lineTo(w * 0.26, h * 0.80)
      ..close();
    canvas.drawPath(cone, orangePaint);

    // White stripes
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Upper stripe
    final stripe1 = Path()
      ..moveTo(w * 0.38, h * 0.36)
      ..lineTo(w * 0.62, h * 0.36)
      ..lineTo(w * 0.65, h * 0.48)
      ..lineTo(w * 0.35, h * 0.48)
      ..close();
    canvas.drawPath(stripe1, whitePaint);

    // Lower stripe
    final stripe2 = Path()
      ..moveTo(w * 0.32, h * 0.58)
      ..lineTo(w * 0.68, h * 0.58)
      ..lineTo(w * 0.72, h * 0.70)
      ..lineTo(w * 0.28, h * 0.70)
      ..close();
    canvas.drawPath(stripe2, whitePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 10. Steam - Locomotive valve gear
class SteamPainter extends CustomPainter {
  const SteamPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Dark circle
    final bgPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFF2A475E), Color(0xFF171A21)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..isAntiAlias = true;
    canvas.drawCircle(center, radius, bgPaint);

    // Valve arm & discs
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..isAntiAlias = true;

    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Big central circle
    canvas.drawCircle(Offset(size.width * 0.56, size.height * 0.44), size.width * 0.20, whitePaint);

    // Connecting rod
    canvas.drawLine(
      Offset(size.width * 0.56, size.height * 0.44),
      Offset(size.width * 0.32, size.height * 0.68),
      whitePaint,
    );

    // Small crank circle
    canvas.drawCircle(Offset(size.width * 0.32, size.height * 0.68), size.width * 0.10, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 11. Git - Orange tilted diamond with branch nodes
class GitPainter extends CustomPainter {
  const GitPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Rotated rounded square
    canvas.save();
    canvas.translate(w / 2, h / 2);
    canvas.rotate(math.pi / 4);

    final bgPaint = Paint()
      ..color = const Color(0xFFF05032)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final side = w * 0.64;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: side, height: side),
        Radius.circular(side * 0.22),
      ),
      bgPaint,
    );
    canvas.restore();

    // White branch lines
    final linePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.065
      ..isAntiAlias = true;

    final nodePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawLine(Offset(w * 0.34, h * 0.32), Offset(w * 0.66, h * 0.64), linePaint);
    canvas.drawLine(Offset(w * 0.50, h * 0.48), Offset(w * 0.66, h * 0.34), linePaint);

    canvas.drawCircle(Offset(w * 0.34, h * 0.32), w * 0.08, nodePaint);
    canvas.drawCircle(Offset(w * 0.66, h * 0.64), w * 0.08, nodePaint);
    canvas.drawCircle(Offset(w * 0.66, h * 0.34), w * 0.08, nodePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 12. Python - Interlocking Blue and Yellow snakes
class PythonPainter extends CustomPainter {
  const PythonPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final bluePaint = Paint()
      ..color = const Color(0xFF3776AB)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final yellowPaint = Paint()
      ..color = const Color(0xFFFFD43B)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Top Blue Snake
    final blue = Path()
      ..moveTo(w * 0.48, h * 0.16)
      ..lineTo(w * 0.64, h * 0.16)
      ..arcToPoint(Offset(w * 0.74, h * 0.26), radius: Radius.circular(w * 0.10))
      ..lineTo(w * 0.74, h * 0.38)
      ..lineTo(w * 0.44, h * 0.38)
      ..lineTo(w * 0.44, h * 0.52)
      ..lineTo(w * 0.28, h * 0.52)
      ..arcToPoint(Offset(w * 0.18, h * 0.42), radius: Radius.circular(w * 0.10))
      ..lineTo(w * 0.18, h * 0.30)
      ..arcToPoint(Offset(w * 0.28, h * 0.20), radius: Radius.circular(w * 0.10))
      ..lineTo(w * 0.48, h * 0.20)
      ..close();
    canvas.drawPath(blue, bluePaint);

    // Bottom Yellow Snake
    final yellow = Path()
      ..moveTo(w * 0.52, h * 0.84)
      ..lineTo(w * 0.36, h * 0.84)
      ..arcToPoint(Offset(w * 0.26, h * 0.74), radius: Radius.circular(w * 0.10))
      ..lineTo(w * 0.26, h * 0.62)
      ..lineTo(w * 0.56, h * 0.62)
      ..lineTo(w * 0.56, h * 0.48)
      ..lineTo(w * 0.72, h * 0.48)
      ..arcToPoint(Offset(w * 0.82, h * 0.58), radius: Radius.circular(w * 0.10))
      ..lineTo(w * 0.82, h * 0.70)
      ..arcToPoint(Offset(w * 0.72, h * 0.80), radius: Radius.circular(w * 0.10))
      ..lineTo(w * 0.52, h * 0.80)
      ..close();
    canvas.drawPath(yellow, yellowPaint);

    // Eye dots
    final whitePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(w * 0.32, h * 0.26), w * 0.035, whitePaint);
    canvas.drawCircle(Offset(w * 0.68, h * 0.74), w * 0.035, whitePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 13. Brave Browser - Orange lion shield
class BravePainter extends CustomPainter {
  const BravePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final shieldPaint = Paint()
      ..color = const Color(0xFFFF5000)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final shield = Path()
      ..moveTo(w * 0.5, h * 0.10)
      ..lineTo(w * 0.85, h * 0.25)
      ..lineTo(w * 0.75, h * 0.75)
      ..lineTo(w * 0.5, h * 0.92)
      ..lineTo(w * 0.25, h * 0.75)
      ..lineTo(w * 0.15, h * 0.25)
      ..close();
    canvas.drawPath(shield, shieldPaint);

    // White lion face accents
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final face = Path()
      ..moveTo(w * 0.35, h * 0.40)
      ..lineTo(w * 0.50, h * 0.55)
      ..lineTo(w * 0.65, h * 0.40)
      ..lineTo(w * 0.50, h * 0.75)
      ..close();
    canvas.drawPath(face, whitePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 14. Opera / Opera GX - Red / Magenta Ring
class OperaPainter extends CustomPainter {
  final bool isGx;
  const OperaPainter({this.isGx = false});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    if (isGx) {
      // Dark gaming background
      final bg = Paint()..color = const Color(0xFF18181B);
      canvas.drawCircle(center, radius, bg);
    }

    final ringPaint = Paint()
      ..color = isGx ? const Color(0xFFFA1E4E) : const Color(0xFFFF1B2D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.22
      ..isAntiAlias = true;

    canvas.drawOval(
      Rect.fromCenter(center: center, width: size.width * 0.68, height: size.height * 0.82),
      ringPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 15. Internet Explorer - Classic 'e' with yellow orbital halo
class InternetExplorerPainter extends CustomPainter {
  const InternetExplorerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final w = size.width;
    final h = size.height;

    // Blue 'e'
    final bluePaint = Paint()
      ..color = const Color(0xFF0076D6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.16
      ..isAntiAlias = true;

    canvas.drawCircle(center, w * 0.32, bluePaint);

    final crossPaint = Paint()
      ..color = const Color(0xFF0076D6)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawRect(Rect.fromLTWH(w * 0.20, h * 0.44, w * 0.60, h * 0.12), crossPaint);

    // Yellow halo orbit
    final yellowPaint = Paint()
      ..color = const Color(0xFFFFC000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.08
      ..isAntiAlias = true;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-math.pi / 6);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: w * 0.95, height: h * 0.32),
      yellowPaint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
