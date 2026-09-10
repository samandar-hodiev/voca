/// The liquid background layer.
///
/// Soft, blurred colour fields that drift slowly behind content. It is the "liquid" half
/// of Voca's visual direction, and it is deliberately quiet: three low-opacity orbs, a
/// long drift period, and no hard edges anywhere.
///
/// Restraint is the whole point. A background that competes for attention makes every
/// screen in front of it harder to read, and this one sits behind the most important
/// moments in the product.
///
/// Performance and accessibility notes, both of which outrank the effect:
///
/// * The blur is applied ONCE to the orb layer, not per orb, and never as a
///   [BackdropFilter]. Backdrop blur re-reads the whole frame and is the fastest way to
///   make a mid-range Android device stutter.
/// * With reduce-motion enabled the orbs are painted in a fixed position. A still
///   gradient is still a good background.
library;

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class LiquidBackground extends StatefulWidget {
  const LiquidBackground({
    super.key,
    required this.child,
    this.intensity = 1.0,
  });

  final Widget child;

  /// Scales orb opacity. Below 1 for screens with dense content in front.
  final double intensity;

  @override
  State<LiquidBackground> createState() => _LiquidBackgroundState();
}

class _LiquidBackgroundState extends State<LiquidBackground>
    with SingleTickerProviderStateMixin {
  // A long period: the movement should be noticeable only if you look for it.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: colors.background),
        RepaintBoundary(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
            child: reduceMotion
                ? _Orbs(t: 0, colors: colors, intensity: widget.intensity)
                : AnimatedBuilder(
                    animation: _controller,
                    builder: (_, __) => _Orbs(
                      t: _controller.value,
                      colors: colors,
                      intensity: widget.intensity,
                    ),
                  ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _Orbs extends StatelessWidget {
  const _Orbs({required this.t, required this.colors, required this.intensity});

  final double t;
  final VocaColors colors;
  final double intensity;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _OrbPainter(t: t, colors: colors, intensity: intensity),
      size: Size.infinite,
    );
  }
}

class _OrbPainter extends CustomPainter {
  _OrbPainter({required this.t, required this.colors, required this.intensity});

  final double t;
  final VocaColors colors;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    // Each orb travels its own slow ellipse, offset in phase so they never line up.
    _orb(
      canvas,
      size,
      colors.primary.withValues(alpha: 0.22 * intensity),
      centre: Alignment(-0.7 + 0.25 * math.sin(t * 2 * math.pi),
          -0.6 + 0.18 * math.cos(t * 2 * math.pi)),
      radius: 0.55,
    );
    _orb(
      canvas,
      size,
      colors.success.withValues(alpha: 0.13 * intensity),
      centre: Alignment(0.85 + 0.18 * math.cos(t * 2 * math.pi + 1.9),
          -0.25 + 0.22 * math.sin(t * 2 * math.pi + 1.9)),
      radius: 0.45,
    );
    _orb(
      canvas,
      size,
      colors.primary.withValues(alpha: 0.16 * intensity),
      centre: Alignment(0.2 + 0.22 * math.sin(t * 2 * math.pi + 3.6),
          0.85 + 0.14 * math.cos(t * 2 * math.pi + 3.6)),
      radius: 0.6,
    );
  }

  void _orb(
    Canvas canvas,
    Size size,
    Color color, {
    required Alignment centre,
    required double radius,
  }) {
    final offset = centre.alongSize(size);
    final r = size.shortestSide * radius;

    canvas.drawCircle(
      offset,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: offset, radius: r)),
    );
  }

  @override
  bool shouldRepaint(_OrbPainter old) =>
      old.t != t || old.intensity != intensity || old.colors != colors;
}
