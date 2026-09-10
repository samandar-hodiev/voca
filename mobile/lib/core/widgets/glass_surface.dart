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
/// Use glass to lift ONE thing off the page. A screen where every surface is glass has no
/// hierarchy, and it is exactly the template look the product is trying not to have.
library;

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

  @override
  Widget build(BuildContext context) {
    final glass = context.vocaGlass;
    final radius = borderRadius ?? BorderRadius.circular(glass.radius);

    // The pane itself: translucent fill, then a highlight that fades down the surface so
    // the top face reads as lit.
    Widget pane = DecoratedBox(
      decoration: BoxDecoration(
        color: tint ?? glass.tint,
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [glass.highlight, Colors.transparent],
          stops: const [0, 0.55],
        ),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(VocaSpacing.md),
        child: child,
      ),
    );

    if (blur) {
      pane = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: glass.blurSigma, sigmaY: glass.blurSigma),
        child: pane,
      );
    }

    // The rim, painted over the clipped pane. A gradient rather than a flat line: real
    // glass is bright where light enters and dim where it leaves, and that difference is
    // most of what makes an edge look like glass.
    final surface = Stack(
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
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: card,
        ),
      );
    }

    if (semanticLabel != null) {
      card = Semantics(label: semanticLabel, button: onTap != null, child: card);
    }

    return card;
  }
}
