/// Liquid and glass for the UI itself.
///
/// Two primitives every control reaches for, so the whole app is made of one material:
///
/// * [LiquidDrop] is a body of coloured liquid: lighter where the light enters at the
///   top, the colour itself through the middle, deeper at the bottom, with a specular
///   highlight across the top, a faint caustic at the bottom where the light that passed
///   through it lands, a lit rim, and a glow of its own colour on the surface below.
///   Primary buttons, the selected tab, progress fills and selected chips are liquid.
/// * [GlassBead] is a clear glass body: a lit face up and to the left, a rim, a shadow
///   under it, and the same highlight and caustic. Icon wells, chips, code cells and
///   resting tabs are glass.
///
/// Both keep the highlight in the top band and the caustic in the bottom band, so
/// neither sits behind a label in the middle.
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import 'glass_surface.dart';

/// A body of coloured liquid, with [child] floating in it.
class LiquidDrop extends StatelessWidget {
  const LiquidDrop({
    super.key,
    this.child,
    this.color,
    this.borderRadius,
    this.padding,
    this.glow = true,
  });

  final Widget? child;

  /// The liquid's colour. Defaults to the brand colour.
  final Color? color;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;

  /// A soft shadow in the liquid's own colour. Off for small fills inside another
  /// surface, where a glow would smear across its neighbours.
  final bool glow;

  /// How much lighter the top edge is than the colour, per theme.
  static const topLightenLight = 0.18;
  static const topLightenDark = 0.22;

  /// Where, as a fraction of the height, the lighter top has fully become the colour.
  /// A label's band starts at [labelBandTop], so everything behind a label is the colour
  /// or deeper. Public so the contrast test holds the two to each other.
  static const colourStop = 0.30;
  static const labelBandTop = 0.30;

  /// Whichever of white and near-black reads better on [color].
  static Color foregroundOn(Color color) {
    const dark = Color(0xFF0B0F17);
    final l = color.computeLuminance();
    final onWhite = 1.05 / (l + 0.05);
    final onDark = (l + 0.05) / (dark.computeLuminance() + 0.05);
    return onWhite >= onDark ? Colors.white : dark;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = color ?? colors.primary;
    final radius = borderRadius ?? VocaRadius.pillAll;
    final body = padding == null
        ? child
        : Padding(padding: padding!, child: child);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(
              c,
              Colors.white,
              dark ? topLightenDark : topLightenLight,
            )!,
            c,
            Color.lerp(c, Colors.black, dark ? 0.08 : 0.12)!,
          ],
          stops: const [0, colourStop, 1],
        ),
        border: GradientBoxBorder(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: 0.55),
              Colors.white.withValues(alpha: 0),
            ],
            stops: const [0, 0.6],
          ),
        ),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: c.withValues(alpha: dark ? 0.5 : 0.4),
                  blurRadius: 16,
                  spreadRadius: -3,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: CustomPaint(
        painter: const LiquidShine(strength: 0.66),
        child: body,
      ),
    );
  }
}

/// A clear glass bead, with [child] seen through it.
class GlassBead extends StatelessWidget {
  const GlassBead({
    super.key,
    this.child,
    this.borderRadius,
    this.padding,
    this.tint,
    this.size,
  });

  final Widget? child;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;

  /// A colour laid into the glass, for a bead that belongs to a state such as the brand
  /// or an error.
  final Color? tint;

  /// Width and height, for a bead of a fixed size.
  final double? size;

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? VocaRadius.pillAll;
    final body = padding == null
        ? child
        : Padding(padding: padding!, child: child);

    Widget content = CustomPaint(
      painter: LiquidShine(strength: dark ? 0.4 : 1),
      child: body,
    );
    if (tint != null) {
      content = DecoratedBox(
        decoration: BoxDecoration(color: tint, borderRadius: radius),
        child: content,
      );
    }

    final bead = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.5),
          radius: 0.95,
          colors: dark
              ? const [Color(0x38FFFFFF), Color(0x14FFFFFF), Color(0x08FFFFFF)]
              : const [Color(0xF2FFFFFF), Color(0x8CFFFFFF), Color(0x40FFFFFF)],
          stops: const [0, 0.6, 1],
        ),
        border: GradientBoxBorder(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark
                ? const [Color(0x59FFFFFF), Color(0x0DFFFFFF)]
                : [Colors.white, colors.primary.withValues(alpha: 0.22)],
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: dark ? const Color(0x73000000) : const Color(0x262B2B60),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: content,
    );

    return size == null ? bead : SizedBox.square(dimension: size, child: bead);
  }
}

/// A specular highlight across the top and a faint caustic at the bottom: light entering
/// a body is focused through it and lands on the far side. The highlight is gone by
/// [highlightBottom], above any label in the middle.
class LiquidShine extends CustomPainter {
  const LiquidShine({required this.strength});

  final double strength;

  static const highlightTop = 0.07;
  static const highlightBottom = 0.26;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final w = size.width;
    final h = size.height;

    final top = Rect.fromLTRB(
      w * 0.14,
      h * highlightTop,
      w * 0.86,
      h * highlightBottom,
    );
    canvas.drawOval(
      top,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.9 * strength),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(top),
    );

    final low = Rect.fromLTWH(w * 0.3, h * 0.8, w * 0.4, h * 0.1);
    canvas.drawOval(
      low,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.4 * strength)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
  }

  @override
  bool shouldRepaint(LiquidShine old) => old.strength != strength;
}
