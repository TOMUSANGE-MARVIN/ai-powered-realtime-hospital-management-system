import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The subtle medical-doodle backdrop behind a chat thread — a loose,
/// repeating scatter of care-themed glyphs (pill bottle, stethoscope,
/// thermometer, heart, syringe, clipboard) tinted into the brand's teal
/// background, mirroring WhatsApp's printed-wallpaper chat background but
/// themed to Ask Musawo instead of a generic doodle set.
class ChatBackground extends StatelessWidget {
  const ChatBackground({super.key, required this.child});

  final Widget child;

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
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: tealBackground,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _DoodlePainter(icons: _icons)),
          child,
        ],
      ),
    );
  }
}

class _DoodlePainter extends CustomPainter {
  _DoodlePainter({required this.icons});

  final List<IconData> icons;

  static const _cell = 84.0;
  static const _iconSize = 26.0;
  static const _opacity = 0.07;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(7);
    final color = seedTeal.withValues(alpha: _opacity);

    final cols = (size.width / _cell).ceil() + 1;
    final rows = (size.height / _cell).ceil() + 1;

    var iconIndex = 0;
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final jitterX = (random.nextDouble() - 0.5) * 18;
        final jitterY = (random.nextDouble() - 0.5) * 18;
        final offsetX = col * _cell + (row.isOdd ? _cell / 2 : 0) + jitterX;
        final offsetY = row * _cell + jitterY;

        final icon = icons[iconIndex % icons.length];
        iconIndex++;

        final painter = TextPainter(
          text: TextSpan(
            text: String.fromCharCode(icon.codePoint),
            style: TextStyle(
              color: color,
              fontSize: _iconSize,
              fontFamily: icon.fontFamily,
              package: icon.fontPackage,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        painter.paint(canvas, Offset(offsetX, offsetY));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DoodlePainter oldDelegate) => false;
}
