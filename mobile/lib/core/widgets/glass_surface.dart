/// Glass surface primitives.
///
/// Two widgets, not a family: [GlassSurface] is the primitive and [GlassCard] is the
/// padded card everything else should reach for.
///
/// The surface is built from four layers, and all four are needed for it to read as
/// glass rather than as a pale card:
///
///   backdrop blur  ->  translucent tint  ->  lit top face  ->  gradient rim
///
/// and two details that give it thickness, which is what separates a pane of glass from
/// a tinted sticker: a glint where the light first strikes it, and a second, fainter edge
/// just inside the rim.
///
/// Use glass to lift ONE thing off the page. A screen where every surface is glass has no
/// hierarchy, and it is exactly the template look the product is trying not to have.
library;

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_glass.dart';
import '../theme/app_spacing.dart';

/// A translucent, blurred, softly lit surface.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.blur = true,
    this.showShadow = true,
    this.tint,
    this.borderWidth = 1,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  /// Overrides the fill. A control that sits directly on the liquid field wants a
  /// thinner tint than a content card does, so more of the colour behind reads through
  /// it. Null uses the theme's tint.
  final Color? tint;

  /// Rim thickness. A control reads as a distinct object with a slightly heavier rim
  /// than a large card needs.
  final double borderWidth;

  /// Whether to apply a backdrop blur. Turn it off inside long scrolling lists: many
  /// simultaneous [BackdropFilter]s are the fastest way to make a mid-range Android
  /// device stutter.
  final bool blur;

  final bool showShadow;

  /// The shade that deepens toward the bottom of a pane, which is what makes it read as
  /// a thick block of glass rather than a sheet. Public so the contrast test includes it.
  static Color depthShade(Brightness brightness) =>
      brightness == Brightness.dark
      ? const Color(0x33000000)
      : const Color(0x0F1E1B6E);

  @override
  Widget build(BuildContext context) {
    final glass = context.vocaGlass;
    final shade = depthShade(Theme.of(context).brightness);
    final radius = borderRadius ?? BorderRadius.circular(glass.radius);

    // The pane itself: translucent fill, then a highlight that fades down the surface so
    // the top face reads as lit.
    //
    // These are two stacked decorations on purpose. BoxDecoration ignores `color` the
    // moment a `gradient` is set, so painting both in one decoration silently drops the
    // tint and leaves only the white highlight — which is exactly how a glass surface
    // ends up looking like a plain pale card, and how a coloured button loses its colour.
    Widget pane = DecoratedBox(
      decoration: BoxDecoration(
        color: tint ?? glass.tint,
        borderRadius: radius,
      ),
      // Depth: the lower half of the pane darkens slightly, as light passing down through
      // a thick piece of glass does.
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [shade.withValues(alpha: 0), shade],
            stops: const [0.5, 1],
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [glass.highlight, Colors.transparent],
              stops: const [0, 0.55],
            ),
          ),
          // The glint is painted behind the content and kept to the top edge, inside the
          // padding, so it never sits under a line of text. Passthrough keeps the content's
          // constraints exactly what they were without the stack.
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: _Glint(color: glass.borderTop)),
                ),
              ),
              Padding(
                padding: padding ?? const EdgeInsets.all(VocaSpacing.md),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );

    if (blur) {
      pane = BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: glass.blurSigma,
          sigmaY: glass.blurSigma,
        ),
        child: pane,
      );
    }

    // The rim, painted over the clipped pane. A gradient rather than a flat line: real
    // glass is bright where light enters and dim where it leaves, and that difference is
    // most of what makes an edge look like glass.
    // Passthrough, so a pane given a fixed size (a card stretched to match its neighbour)
    // fills it instead of shrinking to its content inside a full-size rim.
    final surface = Stack(
      fit: StackFit.passthrough,
      children: [
        ClipRRect(borderRadius: radius, child: pane),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                border: GradientBoxBorder(
                  width: borderWidth,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [glass.borderTop, glass.borderBottom],
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _InnerEdge(
                borderRadius: radius,
                inset: borderWidth + 1,
                color: glass.borderTop,
              ),
            ),
          ),
        ),
      ],
    );

    if (!showShadow) return surface;

    // The shadow is cast by a box behind the clip, so it is not blurred along with the
    // backdrop.
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: radius, boxShadow: glass.shadows),
      child: surface,
    );
  }
}

/// A border whose colour follows a gradient.
///
/// Flutter's [Border] takes a single colour per side, which cannot express a rim that
/// brightens toward the light. This paints the same inset ring with a shader instead.
class GradientBoxBorder extends BoxBorder {
  const GradientBoxBorder({required this.gradient, this.width = 1});

  final Gradient gradient;
  final double width;

  @override
  BorderSide get bottom => BorderSide.none;

  @override
  BorderSide get top => BorderSide.none;

  @override
  bool get isUniform => true;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(width);

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    TextDirection? textDirection,
    BoxShape shape = BoxShape.rectangle,
    BorderRadius? borderRadius,
  }) {
    final paint = Paint()
      ..strokeWidth = width
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke;

    // Inset by half the stroke so the ring sits inside the surface rather than straddling
    // its edge, which would soften the corner.
    final inner = rect.deflate(width / 2);

    if (borderRadius != null) {
      canvas.drawRRect(borderRadius.toRRect(inner), paint);
    } else {
      canvas.drawRect(inner, paint);
    }
  }

  @override
  ShapeBorder scale(double t) =>
      GradientBoxBorder(gradient: gradient, width: width * t);
}

/// The bright spot where light first strikes a pane: a soft oval along the top-left edge.
class _Glint extends CustomPainter {
  const _Glint({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final band = Rect.fromLTWH(
      size.width * 0.06,
      2.5,
      size.width * 0.5,
      math.min(10, size.height * 0.22),
    );
    canvas.drawOval(
      band,
      Paint()
        ..color = color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  @override
  bool shouldRepaint(_Glint old) => old.color != color;
}

/// A second, fainter line just inside the rim, bright along the top and gone a third of
/// the way down, with a dimmer return along the bottom where light that crossed the pane
/// comes out. Two edges a hair apart are what make a pane read as having thickness.
class _InnerEdge extends CustomPainter {
  const _InnerEdge({
    required this.borderRadius,
    required this.inset,
    required this.color,
  });

  final BorderRadius borderRadius;
  final double inset;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    if (rect.width <= inset * 2 || rect.height <= inset * 2) return;
    canvas.drawRRect(
      borderRadius.toRRect(rect).deflate(inset),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: color.a * 0.7),
            color.withValues(alpha: 0),
          ],
          stops: const [0, 0.35],
        ).createShader(rect),
    );
    canvas.drawRRect(
      borderRadius.toRRect(rect).deflate(inset),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0),
            color.withValues(alpha: color.a * 0.3),
          ],
          stops: const [0.8, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_InnerEdge old) =>
      old.borderRadius != borderRadius ||
      old.inset != inset ||
      old.color != color;
}

/// A glass surface with card padding. The default choice for grouped content.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(VocaSpacing.lg),
    this.onTap,
    this.blur = true,
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool blur;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final glass = context.vocaGlass;
    final radius = BorderRadius.circular(glass.radius);

    Widget card = GlassSurface(
      padding: padding,
      borderRadius: radius,
      blur: blur,
      child: child,
    );

    if (onTap != null) {
      card = Material(
        color: Colors.transparent,
        child: InkWell(onTap: onTap, borderRadius: radius, child: card),
      );
    }

    if (semanticLabel != null) {
      card = Semantics(
        label: semanticLabel,
        button: onTap != null,
        child: card,
      );
    }

    return card;
  }
}
