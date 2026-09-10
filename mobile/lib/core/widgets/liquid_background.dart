/// The liquid background layer.
///
/// Soft colour fields that drift slowly behind content, giving the page depth without
/// competing with it.
///
/// Three decisions define how it looks:
///
/// 1. **One colour family.** Indigo through violet to a cool blue, all neighbours on the
///    wheel. Mixing in a distant hue such as green produces muddy secondary colours where
///    fields overlap, which reads as a cheap gradient rather than as light.
/// 2. **The centre stays clear.** Fields are anchored to the edges and corners, so the
///    middle of the screen stays pale and dark text placed there keeps its contrast.
/// 3. **Blur defines, it does not erase.** Enough to remove every hard edge, not so much
///    that the fields flatten into a single wash. Past roughly 50 sigma the shapes stop
///    being shapes.
///
/// Accessibility and performance, both of which outrank the effect:
///
/// * Blur is applied ONCE to the whole field layer, never per shape, and never as a
///   [BackdropFilter]. Backdrop blur re-reads the frame and is the fastest way to make a
///   mid-range Android device stutter.
/// * With reduce-motion the fields are painted in a fixed position. A still gradient is
///   still a good background.
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

  /// Scales field opacity. Below 1 for screens with dense content in front.
  final double intensity;

  @override
  State<LiquidBackground> createState() => _LiquidBackgroundState();
}

class _LiquidBackgroundState extends State<LiquidBackground>
    with SingleTickerProviderStateMixin {
  // A long period: the movement should be noticeable only if you look for it.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 22),
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
        // A base wash so the page is never flat white behind the fields.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colors.background,
                Color.lerp(colors.background, colors.primary, 0.03)!,
              ],
            ),
          ),
        ),
        RepaintBoundary(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: reduceMotion
                ? _Fields(t: 0, colors: colors, intensity: widget.intensity)
                : AnimatedBuilder(
                    animation: _controller,
                    builder: (_, __) => _Fields(
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

class _Fields extends StatelessWidget {
  const _Fields({required this.t, required this.colors, required this.intensity});

  final double t;
  final VocaColors colors;
  final double intensity;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _FieldPainter(t: t, colors: colors, intensity: intensity),
      size: Size.infinite,
    );
  }
}

class _FieldPainter extends CustomPainter {
  _FieldPainter({required this.t, required this.colors, required this.intensity});

  final double t;
  final VocaColors colors;
  final double intensity;

  // One family: the brand indigo, a violet beside it, and a cool blue on the other side.
  static const _violet = Color(0xFF8B5CF6);
  static const _blue = Color(0xFF4F8DF7);

  @override
  void paint(Canvas canvas, Size size) {
    final tau = 2 * math.pi;

    // Top left, the strongest field. Anchored off-screen so only its falloff is visible.
    _field(
      canvas, size,
      colors.primary.withValues(alpha: 0.34 * intensity),
      centre: Alignment(-0.85 + 0.14 * math.sin(t * tau),
          -0.75 + 0.10 * math.cos(t * tau)),
      radius: 0.58,
    );

    // Top right, violet, cooler and smaller.
    _field(
      canvas, size,
      _violet.withValues(alpha: 0.24 * intensity),
      centre: Alignment(0.92 + 0.12 * math.cos(t * tau + 2.1),
          -0.62 + 0.14 * math.sin(t * tau + 2.1)),
      radius: 0.46,
    );

    // Bottom, a wide cool blue that grounds the page.
    _field(
      canvas, size,
      _blue.withValues(alpha: 0.30 * intensity),
      centre: Alignment(-0.45 + 0.18 * math.sin(t * tau + 3.9),
          1.02 + 0.09 * math.cos(t * tau + 3.9)),
      radius: 0.62,
    );

    // Bottom right, a quiet indigo echo so the corner is not empty.
    _field(
      canvas, size,
      colors.primary.withValues(alpha: 0.22 * intensity),
      centre: Alignment(0.88 + 0.10 * math.cos(t * tau + 5.2),
          0.78 + 0.12 * math.sin(t * tau + 5.2)),
      radius: 0.48,
    );
  }

  void _field(
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
          // Hold the colour through the middle before falling away, so the field has a
          // body rather than being a thin ring of colour.
          stops: const [0.15, 1],
        ).createShader(Rect.fromCircle(center: offset, radius: r)),
    );
  }

  @override
  bool shouldRepaint(_FieldPainter old) =>
      old.t != t || old.intensity != intensity || old.colors != colors;
}
