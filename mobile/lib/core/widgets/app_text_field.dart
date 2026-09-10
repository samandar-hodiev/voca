/// Text input.
///
/// A thin wrapper over [TextField] that applies the theme's input decoration and adds the
/// label, helper and error affordances every form needs, so no screen has to reassemble
/// them.
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.enabled = true,
    this.maxLines = 1,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.autofocus = false,
    this.prefixIcon,
    this.suffixIcon,
  });

  final String? label;
  final String? hint;
  final String? helperText;

  /// When set, the field renders its error state and the message is announced.
  final String? errorText;

  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool enabled;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;
  final bool autofocus;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final text = context.vocaText;
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: text.label.copyWith(
              color: enabled ? colors.textPrimary : colors.textDisabled,
            ),
          ),
          const SizedBox(height: VocaSpacing.xs),
        ],
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          enabled: enabled,
          maxLines: obscureText ? 1 : maxLines,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          textInputAction: textInputAction,
          autofocus: autofocus,
          style: text.body.copyWith(
            color: enabled ? colors.textPrimary : colors.textDisabled,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: VocaSpacing.md,
              vertical: VocaSpacing.sm,
            ),
          ),
        ),
        if (hasError || helperText != null) ...[
          const SizedBox(height: VocaSpacing.xxs),
          Semantics(
            liveRegion: hasError,
            child: Text(
              errorText ?? helperText!,
              style: text.caption.copyWith(
                color: hasError ? colors.error : colors.textSecondary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
