/// The liquid background layer.
///
/// Colour that behaves like liquid rather than like light: bodies that drift, touch and
/// flow into one another, each with a lit face and a shaded side so it reads as having
/// volume. It sits behind every screen, so it is also the thing that makes the product feel
/// like one product in both themes.
///
/// It is built from three layers, and each one is there for a reason:
///
/// 1. **A base wash.** The page is never flat white or flat black behind the liquid.
/// 2. **The liquid body.** Solid blobs are blurred and then pushed through an alpha
///    threshold. Where two blurred blobs overlap, their combined alpha crosses the
///    threshold before either one's does, so they fuse with a smooth neck instead of just
///    overlapping. That fusing is what makes this read as liquid; blurred circles on their
///    own only ever read as fog.
/// 3. **Volume.** Each body gets a specular highlight up and to the left and a soft shade
///    down and to the right. Without them the liquid is a flat cut-out; with them it is a
///    droplet. They are drawn over the body and are not thresholded, so they stay soft.
///
/// Decisions that did not change from the previous version:
///
/// * **One colour family.** Indigo, violet and a cool blue, all neighbours on the wheel.
///   Distant hues mix into mud where bodies fuse.
/// * **The centre stays clearer.** Bodies are anchored to the edges and corners and only
///   bulge inwards, so the middle, where text sits, keeps its contrast.
///
/// Accessibility and performance, which still outrank the effect:
///
/// * The blur is applied once, to the whole body layer, never per shape and never as a
///   [BackdropFilter]. Backdrop blur re-reads the frame and is the fastest way to make a
///   mid-range Android device stutter. The volume layer is plain gradients with no blur.
/// * With reduced motion the liquid is painted in a fixed position and the ticker is
///   stopped, not just hidden.
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

  /// Scales how strongly the liquid shows. Below 1 for screens with dense content in
  /// front of it. Capped at 1: that is the strength contrast_test proves text against.
  final double intensity;

  @override
  State<LiquidBackground> createState() => _LiquidBackgroundState();
}

class _LiquidBackgroundState extends State<LiquidBackground>
    with SingleTickerProviderStateMixin {
  // Slow enough that the movement is felt rather than watched.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 20),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // With reduced motion the liquid is painted still, and the ticker is stopped as well
    // rather than left running underneath it. A controller that repeats forever keeps the
    // screen redrawing at full frame rate for somebody who asked for nothing to move.
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final palette = LiquidPalette.of(colors, dark: dark);
    final strength = widget.intensity.clamp(0.0, 1.0);

    Widget layer(_Layer which) {
      Widget paint(double t) => CustomPaint(
        painter: _LiquidPainter(
          t: t,
          palette: palette,
          layer: which,
          strength: strength,
        ),
        size: Size.infinite,
      );
      return reduceMotion
          ? paint(0)
          : AnimatedBuilder(
              animation: _controller,
              builder: (_, __) => paint(_controller.value),
            );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Base wash.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colors.background,
                Color.lerp(
                  colors.background,
                  colors.primary,
                  dark ? 0.10 : 0.06,
                )!,
              ],
            ),
          ),
        ),

        // 2. The liquid body: blur, then threshold, so neighbouring blobs fuse.
        RepaintBoundary(
          child: Opacity(
            opacity: (palette.bodyOpacity * strength).clamp(0.0, 1.0),
            child: ColorFiltered(
              colorFilter: const ColorFilter.matrix(_threshold),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
                child: layer(_Layer.body),
              ),
            ),
          ),
        ),

        // 3. Volume: a lit face and a shaded side on every body.
        RepaintBoundary(child: IgnorePointer(child: layer(_Layer.volume))),

        widget.child,
      ],
    );
  }

  /// Leaves colour alone and steepens alpha: alpha' = 9a - 1020 in 0..255 space, which is
  /// transparent below about 44% and opaque above about 56%. A narrow band gives the
  /// liquid a surface; a wider one would soften it back into fog.
  static const _threshold = <double>[
    1, 0, 0, 0, 0, //
    0, 1, 0, 0, 0, //
    0, 0, 1, 0, 0, //
    0, 0, 0, 9, -1020, //
  ];
}

enum _Layer { body, volume }

/// Colours and strengths for one theme.
///
/// Public so the contrast test can read the real values: text sits straight on this
/// liquid, and every body, shaded side and highlight here is checked against the text
/// colours. Raising a number past what text can bear fails that test.
///
/// Dark is not light inverted. On a near-black page the same colours at the same strength
/// sink into the background, so dark uses paler, more luminous versions at a higher
/// opacity, and a dimmer highlight so the bodies glow instead of shining.
@immutable
class LiquidPalette {
  const LiquidPalette({
    required this.hues,
    required this.bodyOpacity,
    required this.highlight,
    required this.shade,
  });

  factory LiquidPalette.of(VocaColors colors, {required bool dark}) {
    return dark
        ? LiquidPalette(
            hues: [
              colors.primary,
              const Color(0xFFA78BFA),
              const Color(0xFF60A5FA),
              const Color(0xFFC084FC),
            ],
            bodyOpacity: 0.38,
            highlight: 0.08,
            shade: const Color(0x66000014),
          )
        : LiquidPalette(
            hues: [
              colors.primary,
              const Color(0xFF8B5CF6),
              const Color(0xFF4F8DF7),
              const Color(0xFFB36BF2),
            ],
            bodyOpacity: 0.34,
            highlight: 0.55,
            shade: const Color(0x1A1E1B6E),
          );
  }

  /// Indigo, violet, blue and a pink-violet, in that order.
  final List<Color> hues;

  final double bodyOpacity;

  /// Opacity of the white specular face.
  final double highlight;

  /// The shaded side, already carrying its own opacity.
  final Color shade;
}

/// One body of liquid: where it is at time [t], its size and its hue.
typedef _Body = ({Alignment centre, double radius, int hue});

class _LiquidPainter extends CustomPainter {
  _LiquidPainter({
    required this.t,
    required this.palette,
    required this.layer,
    required this.strength,
  });

  final double t;
  final LiquidPalette palette;
  final _Layer layer;
  final double strength;

  static const _tau = 2 * math.pi;

  /// Four large bodies anchored to the corners, and two small droplets that travel along
  /// the top and bottom edges and fuse with them as they pass. The droplets are what make
  /// the fusing visible; without them nothing ever touches.
  List<_Body> _bodies() {
    final a = t * _tau;
    return [
      (
        centre: Alignment(
          -0.95 + 0.20 * math.sin(a),
          -0.85 + 0.12 * math.cos(a),
        ),
        radius: 0.42,
        hue: 0,
      ),
      (
        centre: Alignment(
          0.95 + 0.14 * math.cos(a + 2.1),
          -0.55 + 0.20 * math.sin(a + 2.1),
        ),
        radius: 0.34,
        hue: 1,
      ),
      (
        centre: Alignment(
          -0.70 + 0.22 * math.sin(a + 3.9),
          0.95 + 0.10 * math.cos(a + 3.9),
        ),
        radius: 0.40,
        hue: 2,
      ),
      (
        centre: Alignment(
          0.90 + 0.16 * math.cos(a + 5.2),
          0.80 + 0.14 * math.sin(a + 5.2),
        ),
        radius: 0.32,
        hue: 3,
      ),
      (
        centre: Alignment(
          -0.10 + 0.55 * math.sin(a + 0.8),
          -0.98 + 0.06 * math.cos(a * 2),
        ),
        radius: 0.14,
        hue: 1,
      ),
      (
        centre: Alignment(
          0.20 + 0.50 * math.cos(a + 1.3),
          1.02 + 0.05 * math.sin(a * 2),
        ),
        radius: 0.13,
        hue: 2,
      ),
    ];
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final b in _bodies()) {
      final c = b.centre.alongSize(size);
      final r = size.shortestSide * b.radius;
      final hue = palette.hues[b.hue];

      if (layer == _Layer.body) {
        // Solid: the blur and the threshold that follow decide the surface.
        canvas.drawCircle(c, r, Paint()..color = hue);
        continue;
      }

      // Volume. A shade low and right, then a highlight high and left, both kept well
      // inside the body so they never darken or brighten the page around it.
      final shadeCentre = c + Offset(r * 0.28, r * 0.34);
      final shadeRadius = r * 0.72;
      canvas.drawCircle(
        shadeCentre,
        shadeRadius,
        Paint()
          ..shader =
              RadialGradient(
                colors: [
                  palette.shade.withValues(alpha: palette.shade.a * strength),
                  palette.shade.withValues(alpha: 0),
                ],
              ).createShader(
                Rect.fromCircle(center: shadeCentre, radius: shadeRadius),
              ),
      );

      final lightCentre = c + Offset(-r * 0.34, -r * 0.40);
      final lightRadius = r * 0.52;
      canvas.drawCircle(
        lightCentre,
        lightRadius,
        Paint()
          ..shader =
              RadialGradient(
                colors: [
                  Colors.white.withValues(alpha: palette.highlight * strength),
                  Colors.white.withValues(alpha: 0),
                ],
                stops: const [0, 1],
              ).createShader(
                Rect.fromCircle(center: lightCentre, radius: lightRadius),
              ),
      );
    }
  }

  @override
  bool shouldRepaint(_LiquidPainter old) =>
      old.t != t ||
      old.strength != strength ||
      old.palette != palette ||
      old.layer != layer;
}
