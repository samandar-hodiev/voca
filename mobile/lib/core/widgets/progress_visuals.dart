/// Lightweight progress drawing: a bar and a ring.
///
/// Painted directly rather than pulled from a chart library. The dashboard needs two
/// shapes, and a charting dependency for two shapes is weight the app carries on every
/// launch for nothing.
///
/// Both animate from zero the first time they appear, once, and never loop. With reduced
/// motion they appear at their value.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import 'liquid_drop.dart';

/// A horizontal bar filled to [value], between 0 and 1.
class AnimatedProgressBar extends StatelessWidget {
  const AnimatedProgressBar({
    super.key,
    required this.value,
    this.height = 8,
    this.color,
  });

  final double value;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final target = value.clamp(0.0, 1.0);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: target),
      duration: VocaMotion.respectReducedMotion(context, VocaMotion.emphasized),
      curve: VocaMotion.enterCurve,
      builder: (context, v, _) => ClipRRect(
        borderRadius: BorderRadius.circular(VocaRadius.pill),
        child: SizedBox(
          height: height,
          child: Stack(
            children: [
              // A groove in the glass, darker along its top edge where it is in shadow.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color.lerp(colors.border, colors.textPrimary, 0.14)!,
                        colors.border,
                      ],
                    ),
                  ),
                ),
              ),
              FractionallySizedBox(
                widthFactor: v,
                child: LiquidDrop(color: color ?? colors.primary, glow: false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A ring filled to [value], between 0 and 1, with [child] in the middle.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    this.size = 88,
    this.stroke = 9,
    this.child,
    this.color,
  });

  final double value;
  final double size;
  final double stroke;
  final Widget? child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final target = value.clamp(0.0, 1.0);

    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: target),
        duration: VocaMotion.respectReducedMotion(
          context,
          VocaMotion.expressive,
        ),
        curve: VocaMotion.enterCurve,
        builder: (context, v, inner) => CustomPaint(
          painter: _RingPainter(
            value: v,
            stroke: stroke,
            track: colors.border,
            fill: color ?? colors.primary,
          ),
          child: Center(child: inner),
        ),
        child: child,
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.value,
    required this.stroke,
    required this.track,
    required this.fill,
  });

  final double value;
  final double stroke;
  final Color track;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(arcRect, 0, math.pi * 2, false, base..color = track);
    if (value <= 0) return;

    final sweep = math.pi * 2 * value;

    // A soft glow of the liquid's own colour under the tube.
    canvas.drawArc(
      arcRect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = fill.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawArc(
      arcRect,
      -math.pi / 2,
      sweep,
      false,
      base
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: math.pi * 1.5,
          colors: [fill.withValues(alpha: 0.7), fill],
        ).createShader(rect),
    );

    // A thin lighter line along the outer edge, which makes the stroke read as a round
    // tube of liquid rather than a flat band.
    canvas.drawArc(
      rect.deflate(stroke * 0.3),
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke * 0.28
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.45),
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value ||
      old.track != track ||
      old.fill != fill ||
      old.stroke != stroke;
}
