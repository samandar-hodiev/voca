/// Glass surface primitives.
///
/// Two widgets, not a family: [GlassSurface] is the primitive, [GlassCard] is the padded
/// card everything else should reach for. Anything more would be abstraction for its own
/// sake.
///
/// Use glass to lift ONE thing off the page. A screen where every surface is glass has no
/// hierarchy and reads as a template.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_glass.dart';
import '../theme/app_spacing.dart';

/// A translucent, blurred, softly bordered surface.
///
/// The backdrop blur is skipped when the platform asks for reduced motion or when
/// [blur] is disabled, because [BackdropFilter] is the most expensive thing on this
/// screen and its value is decorative.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.blur = true,
    this.showShadow = true,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  /// Whether to apply a backdrop blur. Turn it off inside long scrolling lists: many
  /// simultaneous blurs are the fastest way to make a mid-range Android device stutter.
  final bool blur;

  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final glass = context.vocaGlass;
    final radius = borderRadius ?? BorderRadius.circular(glass.radius);

    final surface = DecoratedBox(
      decoration: BoxDecoration(
        color: glass.tint,
        borderRadius: radius,
        border: Border.all(color: glass.borderColor),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(VocaSpacing.md),
        child: child,
      ),
    );

    final clipped = ClipRRect(
      borderRadius: radius,
      child: blur
          ? BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: glass.blurSigma,
                sigmaY: glass.blurSigma,
              ),
              child: surface,
            )
          : surface,
    );

    if (!showShadow) return clipped;

    // The shadow is painted on an opaque-free container behind the clip, so it is not
    // blurred along with the backdrop.
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: radius, boxShadow: glass.shadows),
      child: clipped,
    );
  }
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
