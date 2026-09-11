/// Glass surface primitives, after the iOS Liquid Glass material.
///
/// Two widgets, not a family: [GlassSurface] is the primitive and [GlassCard] is the
/// padded card everything else should reach for.
///
/// What makes glass read as glass on iOS is restraint rather than decoration:
///
///   backdrop blur + saturation  ->  thin tint  ->  soft top light  ->  hairline rim
///
/// * What shows through the pane is blurred AND made more saturated, so colour behind it
///   glows through instead of turning grey. That is most of the difference between a
///   material and a milky overlay.
/// * The tint is thin. Separation comes from the blur, the rim and a soft shadow.
/// * The rim is a hairline that catches the light: brightest along the top, a fainter
///   return along the bottom, like the edge of a lens.
/// * Light gathers just inside the rim and fades inward, the lensing that makes it liquid.
/// * No glints, blobs or coloured glows. Those turn glass into a cartoon of glass.
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

  /// Overrides the fill. A control that sits directly on the background wants a thinner
  /// tint than a content card does. Null uses the theme's tint.
  final Color? tint;

  /// Rim thickness.
  final double borderWidth;

  /// Whether to blur what is behind. Turn it off inside long scrolling lists: many
  /// simultaneous [BackdropFilter]s are the fastest way to make a mid-range Android
  /// device stutter.
  final bool blur;

  final bool showShadow;

  /// The saturation boost applied to what is seen through the pane (1.6), as a colour
  /// matrix that keeps luminance where it was.
  static const saturation = <double>[
    1.47244, -0.42912, -0.04332, 0, 0, //
    -0.12756, 1.17088, -0.04332, 0, 0, //
    -0.12756, -0.42912, 1.55668, 0, 0, //
    0, 0, 0, 1, 0, //
  ];

  /// [color] as it looks through the pane's saturation boost. Public so the contrast test
  /// uses exactly what the pane does.
  @visibleForTesting
  static Color saturate(Color color) {
    double channel(int row) =>
        (saturation[row * 5] * color.r +
                saturation[row * 5 + 1] * color.g +
                saturation[row * 5 + 2] * color.b)
            .clamp(0.0, 1.0);
    return Color.from(
      alpha: color.a,
      red: channel(0),
      green: channel(1),
      blue: channel(2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.vocaGlass;
    final radius = borderRadius ?? BorderRadius.circular(glass.radius);

    // The pane: a thin tint, then soft light fading down from the top edge.
    //
    // Two stacked decorations on purpose. BoxDecoration ignores `color` the moment a
    // `gradient` is set, so painting both in one decoration silently drops the tint.
    Widget pane = DecoratedBox(
      decoration: BoxDecoration(
        color: tint ?? glass.tint,
        borderRadius: radius,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [glass.highlight, glass.highlight.withValues(alpha: 0)],
            stops: const [0, 0.5],
          ),
        ),
        // Light gathering at the rim, painted behind the content.
        child: CustomPaint(
          painter: _EdgeLens(
            borderRadius: radius,
            color: glass.borderTop.withValues(alpha: glass.borderTop.a * 0.45),
          ),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(VocaSpacing.md),
            child: child,
          ),
        ),
      ),
    );

    if (blur) {
      pane = BackdropFilter(
        filter: ImageFilter.compose(
          outer: const ColorFilter.matrix(saturation),
          inner: ImageFilter.blur(
            sigmaX: glass.blurSigma,
            sigmaY: glass.blurSigma,
          ),
        ),
        child: pane,
      );
    }

    // The hairline rim, painted over the clipped pane. Passthrough, so a pane given a
    // fixed size (a card stretched to match its neighbour) fills it.
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
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      glass.borderTop,
                      glass.borderBottom.withValues(
                        alpha: glass.borderBottom.a * 0.4,
                      ),
                      glass.borderBottom,
                    ],
                    stops: const [0, 0.55, 1],
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _TopEdge(
                borderRadius: radius,
                inset: borderWidth + 0.5,
                color: glass.borderTop,
              ),
            ),
          ),
        ),
      ],
    );

    if (!showShadow) return surface;

    // The shadow is painted outside the pane only. Under translucent glass an ordinary
    // shadow shows through and turns the pane grey.
    return CustomPaint(
      painter: _OuterShadow(borderRadius: radius, shadows: glass.shadows),
      child: surface,
    );
  }
}

/// Light bending at the rim: a soft brightening just inside the edge that fades inward,
/// the way a thick piece of glass gathers light along its border. It is what makes a clear
/// pane read as liquid glass rather than a line drawing of one. Kept to the edge, inside
/// the padding, so it never sits behind text.
class _EdgeLens extends CustomPainter {
  const _EdgeLens({required this.borderRadius, required this.color});

  final BorderRadius borderRadius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final pane = borderRadius.toRRect(Offset.zero & size);
    canvas
      ..save()
      ..clipRRect(pane)
      ..drawRRect(
        pane,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..color = color
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_EdgeLens old) =>
      old.borderRadius != borderRadius || old.color != color;
}

/// Paints [shadows] around a pane and never under it.
class _OuterShadow extends CustomPainter {
  const _OuterShadow({required this.borderRadius, required this.shadows});

  final BorderRadius borderRadius;
  final List<BoxShadow> shadows;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final outside = Path.combine(
      PathOperation.difference,
      Path()..addRect(rect.inflate(200)),
      Path()..addRRect(borderRadius.toRRect(rect)),
    );
    canvas
      ..save()
      ..clipPath(outside);
    for (final shadow in shadows) {
      canvas.drawRRect(
        borderRadius.toRRect(
          rect.shift(shadow.offset).inflate(shadow.spreadRadius),
        ),
        Paint()
          ..color = shadow.color
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadow.blurSigma),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_OuterShadow old) =>
      old.borderRadius != borderRadius || old.shadows != shadows;
}

/// A second, fainter line just inside the rim along the top, gone by a third of the way
/// down. Two edges a hair apart are what give a pane its thickness.
class _TopEdge extends CustomPainter {
  const _TopEdge({
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
            color.withValues(alpha: color.a * 0.5),
            color.withValues(alpha: 0),
          ],
          stops: const [0, 0.3],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_TopEdge old) =>
      old.borderRadius != borderRadius ||
      old.inset != inset ||
      old.color != color;
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
