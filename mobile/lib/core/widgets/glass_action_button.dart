/// A full-width glass action button.
///
/// Used for the sign-in choices. They are glass rather than filled because they are
/// alternatives to one another, not a hierarchy: making one solid would say it is the
/// right answer, and it is not.
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

    final foreground = _enabled ? colors.textPrimary : colors.textDisabled;

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      child: GestureDetector(
        onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: _enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: _enabled ? () => setState(() => _pressed = false) : null,
        onTap: _enabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: VocaMotion.respectReducedMotion(context, VocaMotion.instant),
          curve: VocaMotion.standardCurve,
          constraints: const BoxConstraints(minHeight: 56),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: VocaSpacing.md,
            vertical: VocaSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: _pressed ? colors.primaryMuted : glass.tint,
            borderRadius: BorderRadius.circular(VocaRadius.large),
            border: Border.all(
              color: _enabled ? glass.borderBottom : colors.border,
            ),
            boxShadow: _enabled && !_pressed ? glass.shadows : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isLoading)
                SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.2, color: colors.primary),
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
                          style: text.caption.copyWith(color: colors.textDisabled),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
