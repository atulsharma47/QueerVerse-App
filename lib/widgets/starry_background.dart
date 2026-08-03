import 'dart:math' as math;
import 'package:flutter/material.dart';

class StarryBackground extends StatelessWidget {
  const StarryBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(child: CustomPaint(painter: _StarryPainter()));
  }
}

class _StarryPainter extends CustomPainter {
  static final math.Random _rand = math.Random(11);

  @override
  void paint(Canvas canvas, Size size) {
    _paintSky(canvas, size);
    _paintDots(canvas, size);
    _paintSparkles(canvas, size);
    _paintShootingStar(canvas, size);
    _paintMoon(canvas, size);
    _paintClouds(canvas, size);
  }

  void _paintSky(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF07050D), Color(0xFF0D0A18), Color(0xFF1A0F26)],
        ).createShader(rect),
    );
  }

  void _paintDots(Canvas canvas, Size size) {
    final paint = Paint();
    for (int i = 0; i < 90; i++) {
      final dx = _rand.nextDouble() * size.width;
      final dy = _rand.nextDouble() * size.height * 0.9;
      final r = 0.5 + _rand.nextDouble() * 1.3;
      paint.color = Colors.white.withValues(
        alpha: 0.2 + _rand.nextDouble() * 0.5,
      );
      canvas.drawCircle(Offset(dx, dy), r, paint);
    }
  }

  void _paintSparkles(Canvas canvas, Size size) {
    final positions = [
      Offset(size.width * 0.12, size.height * 0.14),
      Offset(size.width * 0.85, size.height * 0.30),
      Offset(size.width * 0.06, size.height * 0.42),
      Offset(size.width * 0.92, size.height * 0.55),
      Offset(size.width * 0.30, size.height * 0.05),
      Offset(size.width * 0.55, size.height * 0.20),
      Offset(size.width * 0.75, size.height * 0.62),
      Offset(size.width * 0.15, size.height * 0.60),
    ];
    for (int i = 0; i < positions.length; i++) {
      final color = i.isEven
          ? const Color(0xFFF3D9A4)
          : const Color(0xFFEC4899);
      _drawSparkle(canvas, positions[i], 6 + _rand.nextDouble() * 5, color);
    }
  }

  void _drawSparkle(Canvas canvas, Offset center, double size, Color color) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.6);

    final path = Path();
    path.moveTo(center.dx, center.dy - size);
    path.quadraticBezierTo(center.dx, center.dy, center.dx + size, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + size);
    path.quadraticBezierTo(center.dx, center.dy, center.dx - size, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - size);
    path.close();
    canvas.drawPath(path, paint);

    // tiny cross-glint through the center
    final glint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(center.dx - size * 0.3, center.dy),
      Offset(center.dx + size * 0.3, center.dy),
      glint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - size * 0.3),
      Offset(center.dx, center.dy + size * 0.3),
      glint,
    );
  }

  void _paintShootingStar(Canvas canvas, Size size) {
    final start = Offset(size.width * 0.62, size.height * 0.10);
    final end = Offset(size.width * 0.82, size.height * 0.22);
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFFEC4899).withValues(alpha: 0.0),
          const Color(0xFFF3D9A4).withValues(alpha: 0.9),
        ],
      ).createShader(Rect.fromPoints(start, end))
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(start, end, paint);
  }

  void _paintMoon(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.83, size.height * 0.13);
    const radius = 30.0;

    // soft glow behind the moon
    canvas.drawCircle(
      center,
      radius * 1.8,
      Paint()
        ..color = const Color(0xFFF3D9A4).withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );

    canvas.saveLayer(
      Rect.fromCircle(center: center, radius: radius * 1.4),
      Paint(),
    );
    canvas.drawCircle(center, radius, Paint()..color = const Color(0xFFF3E5C4));
    canvas.drawCircle(
      center.translate(radius * 0.5, -radius * 0.12),
      radius * 0.88,
      Paint()..blendMode = BlendMode.dstOut,
    );
    canvas.restore();
  }

  void _paintClouds(Canvas canvas, Size size) {
    final cloudPaint = Paint()
      ..color = const Color(0xFF3A1F52).withValues(alpha: 0.65)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);

    // bottom-left blob cluster
    canvas.drawCircle(
      Offset(size.width * 0.05, size.height * 0.98),
      70,
      cloudPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.16, size.height * 0.94),
      55,
      cloudPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.02, size.height * 0.88),
      40,
      cloudPaint,
    );

    // bottom-right blob cluster
    canvas.drawCircle(
      Offset(size.width * 0.95, size.height * 0.97),
      65,
      cloudPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.93),
      50,
      cloudPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.99, size.height * 0.87),
      38,
      cloudPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _StarryPainter oldDelegate) => false;
}
