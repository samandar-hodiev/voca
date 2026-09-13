/// The overall score, as a ring.
///
/// The number is the point, so it is what sits in the middle at full size; the arc is how
/// far round it has gone. A ring rather than a bar because the result is a single verdict,
/// not a position in a list.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import 'score_palette.dart';

class ScoreRing extends StatelessWidget {
  const ScoreRing({
    super.key,
    required this.score,
    required this.label,
    this.size = 132,
  });

  /// Out of 100.
  final double score;

  /// Read out under the number, and to a screen reader with it.
  final String label;

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final text = context.vocaText;
    final band = bandFor(score);
    final rounded = score.round();

    return Semantics(
      label: '$label: $rounded / 100',
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _RingPainter(
            progress: (score / 100).clamp(0.0, 1.0),
            color: bandColor(colors, band),
            track: colors.border,
            stroke: size * 0.09,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$rounded',
                  style: text.display.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  label,
                  style: text.caption.copyWith(color: colors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.color,
    required this.track,
    required this.stroke,
  });

  final double progress;
  final Color color;
  final Color track;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final inset = rect.deflate(stroke / 2);

    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = track;
    canvas.drawArc(inset, 0, math.pi * 2, false, base);

    if (progress <= 0) return;
    // From the top, clockwise, the way a dial is read.
    canvas.drawArc(
      inset,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      base..color = color,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color || old.track != track;
}
