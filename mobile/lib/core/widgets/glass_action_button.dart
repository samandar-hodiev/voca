/// A full-width glass action button.
///
/// Used for the sign-in choices. They are glass rather than filled because they are
/// alternatives to one another, not a hierarchy: making one solid would say it is the
/// right answer, and it is not.
///
/// The button is built from [GlassSurface], not from a plain container with a pale fill.
/// That distinction is the whole point: a rounded box filled with 65% white on a light
/// page is a white pill, while the surface below it puts a backdrop blur, a lit top face
/// and a gradient rim under the same fill, and only then does it read as glass. The tint
/// here is thinner than a card's so the liquid field behind actually shows through.
///
/// A disabled button still renders, greyed and labelled, when a method exists but is not
/// available yet. Hiding it would leave people wondering whether it is coming; showing it
/// as tappable would be a lie.
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_glass.dart';
import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'glass_surface.dart';
import 'glass_touch_light.dart';

class GlassActionButton extends StatefulWidget {
  const GlassActionButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.unavailableNote,
  });

  final String label;

  /// Drawn at the leading edge. A widget rather than an IconData so a brand mark can be
  /// painted rather than borrowed from the icon font.
  final Widget? icon;

  final VoidCallback? onPressed;
  final bool isLoading;

  /// Shown under the label when the method exists but cannot be used yet.
  final String? unavailableNote;

  @override
  State<GlassActionButton> createState() => _GlassActionButtonState();
}

class _GlassActionButtonState extends State<GlassActionButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null && !widget.isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final glass = context.vocaGlass;
    final text = context.vocaText;

    // Disabled uses the secondary text colour, not the disabled one. Over a saturated
    // liquid field a very light grey stops being legible, and a method someone is being
    // asked to wait for still has to be readable.
    final foreground = _enabled ? colors.textPrimary : colors.textSecondary;

    // Thinner than the card tint so the liquid field reads through the control. Pressing
    // thickens it, which is what a pane of glass does when you push a finger against it.
    // Disabled goes thinner still: less present, without disappearing.
    // The base comes from the theme because the right thinness is not the same in both:
    // on a dark page a fill this thin would vanish into the background.
    final base = glass.controlOpacity;
    final double fillAlpha = _pressed ? (base + 0.22).clamp(0.0, 1.0) : base;
    final tint = glass.tint.withValues(alpha: fillAlpha);

    final surface = GlassSurface(
      edgeGlow: false,
      borderRadius: VocaRadius.largeAll,
      tint: tint,
      borderWidth: _enabled ? 1.4 : 1,
      // No shadow. These buttons are always stacked a few points apart, and at that
      // spacing each one's shadow reaches into the gaps on both sides; the overlapping
      // shadows join into a single darker block that reads as a container drawn around
      // the group rather than as separate buttons. The rim and the tint are what make
      // the button read as glass.
      showShadow: false,
      padding: const EdgeInsets.symmetric(
        horizontal: VocaSpacing.md,
        vertical: VocaSpacing.sm,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 40),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.isLoading)
              SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: colors.primary,
                ),
              )
            else ...[
              if (widget.icon != null) ...[
                Opacity(opacity: _enabled ? 1 : 0.4, child: widget.icon),
                const SizedBox(width: VocaSpacing.sm),
              ],
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.label,
                      style: text.subtitle.copyWith(color: foreground),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.unavailableNote != null)
                      Text(
                        widget.unavailableNote!,
                        style: text.caption.copyWith(
                          color: colors.textDisabled,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      child: GestureDetector(
        onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: _enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: _enabled ? () => setState(() => _pressed = false) : null,
        onTap: _enabled ? widget.onPressed : null,
        // A press shrinks the pane very slightly. Glass does not depress like a rubber
        // key, so the movement is small enough to feel rather than watch.
        child: AnimatedScale(
          scale: _pressed ? 0.985 : 1,
          duration: VocaMotion.respectReducedMotion(
            context,
            VocaMotion.instant,
          ),
          curve: VocaMotion.standardCurve,
          child: SizedBox(
            width: double.infinity,
            child: GlassTouchLight(
              borderRadius: VocaRadius.largeAll,
              enabled: _enabled,
              child: surface,
            ),
          ),
        ),
      ),
    );
  }
}
