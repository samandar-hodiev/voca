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
              Positioned.fill(child: ColoredBox(color: colors.border)),
              FractionallySizedBox(
                widthFactor: v,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        (color ?? colors.primary).withValues(alpha: 0.75),
                        color ?? colors.primary,
                      ],
                    ),
                  ),
                ),
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

    canvas.drawArc(
      arcRect,
      -math.pi / 2,
      math.pi * 2 * value,
      false,
      base
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: math.pi * 1.5,
          colors: [fill.withValues(alpha: 0.7), fill],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value ||
      old.track != track ||
      old.fill != fill ||
      old.stroke != stroke;
}
