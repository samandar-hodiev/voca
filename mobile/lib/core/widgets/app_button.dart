/// Buttons.
///
/// Three levels of emphasis and one icon button. Every one of them:
///
/// * keeps a minimum 48x48 touch target, which is the accessibility floor on both
///   platforms regardless of how small the label is;
/// * shows a distinct pressed state, because a control that does not acknowledge a touch
///   feels broken;
/// * shows a distinct disabled state, so unavailable never looks merely quiet;
/// * can show a loading state that keeps its width, so the layout does not jump when a
///   request starts.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'glass_surface.dart';
import 'liquid_drop.dart';
import '../theme/app_glass.dart';
import 'glass_touch_light.dart';

enum _Emphasis { primary, secondary, text }

/// Filled button. One per screen: the single most likely next action.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  /// Fill the available width. True by default: on a phone, a primary action normally
  /// spans the content column.
  final bool expand;

  @override
  Widget build(BuildContext context) => _VocaButton(
    label: label,
    onPressed: onPressed,
    isLoading: isLoading,
    icon: icon,
    expand: expand,
    emphasis: _Emphasis.primary,
  );
}

/// Outlined button. A real but secondary choice.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) => _VocaButton(
    label: label,
    onPressed: onPressed,
    isLoading: isLoading,
    icon: icon,
    expand: expand,
    emphasis: _Emphasis.secondary,
  );
}

/// Text button. Lowest emphasis: dismiss, skip, learn more.
class VocaTextButton extends StatelessWidget {
  const VocaTextButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => _VocaButton(
    label: label,
    onPressed: onPressed,
    icon: icon,
    expand: false,
    emphasis: _Emphasis.text,
  );
}

/// Icon-only button.
///
/// [semanticLabel] is required, not optional: an icon with no accessible name is
/// invisible to a screen reader.
class VocaIconButton extends StatelessWidget {
  const VocaIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    this.onPressed,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final enabled = onPressed != null;

    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: VocaRadius.mediumAll),
        child: InkWell(
          onTap: onPressed,
          borderRadius: VocaRadius.mediumAll,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            child: Icon(
              icon,
              size: 22,
              color: enabled ? colors.textPrimary : colors.textDisabled,
            ),
          ),
        ),
      ),
    );
  }
}

class _VocaButton extends StatefulWidget {
  const _VocaButton({
    required this.label,
    required this.emphasis,
    required this.expand,
    this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  final String label;
  final _Emphasis emphasis;
  final bool expand;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  @override
  State<_VocaButton> createState() => _VocaButtonState();
}

class _VocaButtonState extends State<_VocaButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null && !widget.isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final text = context.vocaText;

    final (background, foreground, border) = _resolveColors(colors);

    final content = widget.isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: foreground,
            ),
          )
        : Row(
            mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 18, color: foreground),
                const SizedBox(width: VocaSpacing.xs),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  style: text.label.copyWith(color: foreground),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
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
        child: widget.emphasis == _Emphasis.primary
            // The primary action is a pane of light, premium green glass (_PrimaryGlass).
            ? SizedBox(
                width: widget.expand ? double.infinity : null,
                child: GlassTouchLight(
                  borderRadius: VocaRadius.largeAll,
                  enabled: _enabled,
                  child: _PrimaryGlass(
                    enabled: _enabled,
                    pressed: _pressed,
                    padding: const EdgeInsets.symmetric(
                      horizontal: VocaSpacing.lg,
                      vertical: VocaSpacing.sm,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 32),
                      child: Align(alignment: Alignment.center, child: content),
                    ),
                  ),
                ),
              )
            : widget.emphasis == _Emphasis.secondary
            ? _secondary(context, content)
            : AnimatedContainer(
                duration: VocaMotion.respectReducedMotion(
                  context,
                  VocaMotion.instant,
                ),
                curve: VocaMotion.standardCurve,
                // 48 is the accessible minimum touch target on both platforms.
                constraints: const BoxConstraints(minHeight: 48),
                width: widget.expand ? double.infinity : null,
                padding: const EdgeInsets.symmetric(
                  horizontal: VocaSpacing.lg,
                  vertical: VocaSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: VocaRadius.largeAll,
                  border: border == null ? null : Border.all(color: border),
                ),
                alignment: Alignment.center,
                child: content,
              ),
      ),
    );
  }

  /// Secondary is a pane of clear glass. Pressing thickens it, as a finger pressed
  /// against glass does.
  Widget _secondary(BuildContext context, Widget content) {
    final glass = context.vocaGlass;
    final fill = glass.controlOpacity + (_pressed ? 0.22 : 0);
    return SizedBox(
      width: widget.expand ? double.infinity : null,
      child: GlassTouchLight(
        borderRadius: VocaRadius.largeAll,
        enabled: _enabled,
        child: GlassSurface(
          edgeGlow: false,
          borderRadius: VocaRadius.mediumAll,
          tint: glass.tint.withValues(alpha: fill.clamp(0.0, 1.0)),
          borderWidth: 1.2,
          showShadow: _enabled && !_pressed,
          padding: const EdgeInsets.symmetric(
            horizontal: VocaSpacing.lg,
            vertical: VocaSpacing.sm,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 32),
            child: Align(alignment: Alignment.center, child: content),
          ),
        ),
      ),
    );
  }

  /// Returns background, foreground and optional border for the current state.
  (Color, Color, Color?) _resolveColors(VocaColors colors) {
    if (!_enabled) {
      return switch (widget.emphasis) {
        _Emphasis.primary => (colors.border, colors.textDisabled, null),
        _Emphasis.secondary => (
          Colors.transparent,
          colors.textDisabled,
          colors.border,
        ),
        _Emphasis.text => (Colors.transparent, colors.textDisabled, null),
      };
    }

    return switch (widget.emphasis) {
      // Deep green on the light green glass: white would not read on it.
      _Emphasis.primary => (
        _pressed ? colors.primaryPressed : colors.primary,
        PremiumGreen.label,
        null,
      ),
      // The darker brand tone: brand-coloured text on clear glass over the background
      // would fall below body contrast.
      _Emphasis.secondary => (Colors.transparent, colors.onPrimaryMuted, null),
      _Emphasis.text => (
        _pressed ? colors.primaryMuted : Colors.transparent,
        colors.primary,
        null,
      ),
    };
  }
}

/// The primary action: a pane of light, premium green glass.
///
/// What is behind it is blurred and made more saturated, as with every glass surface. The
/// body is a mint-to-emerald liquid, lit by a specular band across the top and a faint
/// caustic along the bottom, with a bright rim and a soft green glow beneath. Light and
/// clear rather than a dark slab of ink, so the one action a screen asks for reads as the
/// most precious object on it.
class _PrimaryGlass extends StatelessWidget {
  const _PrimaryGlass({
    required this.enabled,
    required this.pressed,
    required this.padding,
    required this.child,
  });

  final bool enabled;
  final bool pressed;
  final EdgeInsetsGeometry padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    const radius = VocaRadius.largeAll;
    final (start, end) = !enabled
        ? (colors.border, colors.border)
        : pressed
        ? (PremiumGreen.pressedStart, PremiumGreen.pressedEnd)
        : (PremiumGreen.start, PremiumGreen.end);

    final glass = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.compose(
          outer: const ColorFilter.matrix(GlassSurface.saturation),
          inner: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                start.withValues(alpha: PremiumGreen.alpha),
                end.withValues(alpha: PremiumGreen.alpha),
              ],
            ),
          ),
          // The liquid light: a specular band across the top that has faded before the
          // label, and a faint caustic along the bottom edge.
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: enabled ? 0.55 : 0.2),
                  Colors.white.withValues(alpha: 0),
                  Colors.white.withValues(alpha: 0),
                  Colors.white.withValues(alpha: enabled ? 0.28 : 0.1),
                ],
                stops: const [0, 0.38, 0.78, 1],
              ),
            ),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: enabled && !pressed
            ? [
                BoxShadow(
                  color: PremiumGreen.end.withValues(alpha: 0.45),
                  blurRadius: 22,
                  spreadRadius: -6,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      position: DecorationPosition.background,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          glass,
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  border: GradientBoxBorder(
                    width: 1.2,
                    gradient: specularRim(
                      Colors.white.withValues(alpha: 0.95),
                      Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
