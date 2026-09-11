/// The background behind every screen.
///
/// A still, barely-there wash of colour: the brand indigo in two soft fields with a quiet
/// green between them, blurred together over the page colour. It does not move. The
/// liquid and the glass live on the UI in front of it, on the cards, buttons and
/// controls; the background only keeps the page from being flat white or flat black.
///
/// Restraint is the point. A background that competes for attention makes every screen
/// in front of it harder to read.
///
/// It is painted once and cached: one blur over three gradients inside a
/// [RepaintBoundary], so content scrolling in front of it never repaints it. It is never
/// a [BackdropFilter], which re-reads the whole frame.
library;

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class LiquidBackground extends StatelessWidget {
  const LiquidBackground({
    super.key,
    required this.child,
    this.intensity = 1.0,
  });

  final Widget child;

  /// Scales the fields' opacity. Capped at 1, the strength contrast_test checks text
  /// against.
  final double intensity;

  /// The three fields at full strength, per theme: colour at its centre, where, and how
  /// large as a fraction of the shorter screen side. Public so the contrast test reads
  /// the real values.
  ///
  /// Light leans green, with teal and a touch of the brand indigo, so the white glass in
  /// front has colour to sit on. Dark keeps its indigo wash with a quiet green.
  @visibleForTesting
  static List<(Color, Alignment, double)> fields(
    VocaColors colors,
    Brightness brightness,
  ) => brightness == Brightness.dark
      ? [
          (
            _indigoDark.withValues(alpha: 0.22),
            const Alignment(-0.7, -0.42),
            0.55,
          ),
          (
            colors.success.withValues(alpha: 0.13),
            const Alignment(0.79, -0.04),
            0.45,
          ),
          (
            _indigoDark.withValues(alpha: 0.16),
            const Alignment(0.1, 0.72),
            0.6,
          ),
        ]
      : [
          (
            _indigoLight.withValues(alpha: 0.14),
            const Alignment(-0.75, -0.5),
            0.55,
          ),
          (
            const Color(0xFF14B8A6).withValues(alpha: 0.24),
            const Alignment(0.8, -0.1),
            0.55,
          ),
          (
            const Color(0xFF22C55E).withValues(alpha: 0.18),
            const Alignment(0.05, 0.75),
            0.65,
          ),
        ];

  // The background keeps its own indigo whatever the brand colour is, so the look of the
  // page does not move when the brand does.
  static const _indigoLight = Color(0xFF5B5BF7);
  static const _indigoDark = Color(0xFF7C7CFF);

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: colors.background),
        RepaintBoundary(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
            child: CustomPaint(
              painter: _FieldPainter(
                fields: fields(colors, Theme.of(context).brightness),
                strength: intensity.clamp(0.0, 1.0),
              ),
              size: Size.infinite,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _FieldPainter extends CustomPainter {
  const _FieldPainter({required this.fields, required this.strength});

  final List<(Color, Alignment, double)> fields;
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    for (final (color, centre, radius) in fields) {
      final c = centre.alongSize(size);
      final r = size.shortestSide * radius;
      final peak = color.withValues(alpha: color.a * strength);
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [peak, peak.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: c, radius: r)),
      );
    }
  }

  @override
  bool shouldRepaint(_FieldPainter old) =>
      old.strength != strength || !listEquals(old.fields, fields);
}
