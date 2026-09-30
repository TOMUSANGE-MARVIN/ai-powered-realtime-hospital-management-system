import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// WhatsApp-style doodle wallpaper for chat threads, themed with medical
/// glyphs in the brand teal.
class ChatBackground extends StatelessWidget {
  const ChatBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: context.isDark
              ? const [Color(0xFF0E2222), Color(0xFF0B1A1A)]
              : const [Color(0xFFE6F4F3), Color(0xFFDDEFEE)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const RepaintBoundary(child: CustomPaint(painter: _DoodlePainter())),
          child,
        ],
      ),
    );
  }
}

class _DoodlePainter extends CustomPainter {
  const _DoodlePainter();

  static const _icons = [
    Icons.medication_liquid_outlined,
    Icons.favorite_border,
    Icons.medical_services_outlined,
    Icons.healing_outlined,
    Icons.thermostat_outlined,
    Icons.vaccines_outlined,
    Icons.local_hospital_outlined,
    Icons.assignment_outlined,
    Icons.monitor_heart_outlined,
    Icons.medication_outlined,
    Icons.chat_bubble_outline,
    Icons.sentiment_satisfied_outlined,
    Icons.calendar_today_outlined,
    Icons.local_pharmacy_outlined,
    Icons.bloodtype_outlined,
    Icons.health_and_safety_outlined,
    Icons.coronavirus_outlined,
    Icons.science_outlined,
    Icons.biotech_outlined,
    Icons.masks_outlined,
    Icons.spa_outlined,
    Icons.water_drop_outlined,
    Icons.clean_hands_outlined,
    Icons.psychology_outlined,
  ];

  static const _cell = 62.0;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(11);
    final iconColor = seedTeal.withValues(alpha: 0.13);
    final fillerPaint = Paint()
      ..color = seedTeal.withValues(alpha: 0.10)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final cols = (size.width / _cell).ceil() + 1;
    final rows = (size.height / _cell).ceil() + 1;

    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final cx =
            col * _cell +
            (row.isOdd ? _cell / 2 : 0) +
            (random.nextDouble() - 0.5) * 16;
        final cy = row * _cell + (random.nextDouble() - 0.5) * 16;

        final icon = _icons[random.nextInt(_icons.length)];
        final iconSize = 22.0 + random.nextDouble() * 12;
        final angle = (random.nextDouble() - 0.5) * 0.9;

        final painter = TextPainter(
          text: TextSpan(
            text: String.fromCharCode(icon.codePoint),
            style: TextStyle(
              color: iconColor,
              fontSize: iconSize,
              fontFamily: icon.fontFamily,
              package: icon.fontPackage,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        canvas
          ..save()
          ..translate(cx, cy)
          ..rotate(angle);
        painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
        canvas.restore();

        // Small filler marks between glyphs, like printed doodle wallpaper.
        final fx = cx + _cell / 2 + (random.nextDouble() - 0.5) * 10;
        final fy = cy + _cell / 2 + (random.nextDouble() - 0.5) * 10;
        switch (random.nextInt(3)) {
          case 0:
            canvas.drawCircle(Offset(fx, fy), 2.2, fillerPaint);
          case 1:
            canvas
              ..drawLine(
                Offset(fx - 3.5, fy),
                Offset(fx + 3.5, fy),
                fillerPaint,
              )
              ..drawLine(
                Offset(fx, fy - 3.5),
                Offset(fx, fy + 3.5),
                fillerPaint,
              );
          default:
            break;
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DoodlePainter oldDelegate) => false;
}
