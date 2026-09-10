/// Brand marks drawn in code.
///
/// Painted rather than shipped as image assets: an asset would mean redistributing
/// someone else's artwork, and these are simple enough to draw faithfully.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The Google "G", in its four brand colours.
class GoogleMark extends StatelessWidget {
  const GoogleMark({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(size: Size.square(size), painter: _GooglePainter()),
    );
  }
}

class _GooglePainter extends CustomPainter {
  static const _blue = Color(0xFF4285F4);
  static const _green = Color(0xFF34A853);
  static const _yellow = Color(0xFFFBBC05);
  static const _red = Color(0xFFEA4335);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height).deflate(size.width * 0.08);
    final stroke = size.width * 0.22;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    // Four arcs, one per brand colour, starting at the right and going clockwise.
    const quarter = math.pi / 2;
    final arcs = <(Color, double, double)>[
      (_red, -quarter * 1.15, quarter * 0.95),
      (_yellow, -quarter * 0.2, quarter * 1.1),
      (_green, quarter * 0.9, quarter * 1.1),
      (_blue, quarter * 2.0, quarter * 1.05),
    ];
    for (final (color, start, sweep) in arcs) {
      canvas.drawArc(rect, start, sweep, false, paint..color = color);
    }

    // The crossbar that makes the shape a G rather than a circle.
    final centre = rect.center;
    canvas.drawLine(
      Offset(centre.dx + rect.width * 0.02, centre.dy),
      Offset(rect.right, centre.dy),
      Paint()
        ..color = _blue
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt,
    );
  }

  @override
  bool shouldRepaint(_GooglePainter oldDelegate) => false;
}

/// The Apple mark, drawn as a monochrome glyph.
class AppleMark extends StatelessWidget {
  const AppleMark({super.key, this.size = 20, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Icon(Icons.apple, size: size + 4, color: color),
    );
  }
}
