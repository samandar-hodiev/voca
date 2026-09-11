/// Error state.
///
/// An error screen has one job: say what happened in plain language and offer the way
/// out. It is deliberately plain, because a beautifully illustrated failure is still a
/// failure and over-designing it wastes the reader's attention.
///
/// [requestId] is shown when present so a person can quote it in a support message; that
/// identifier maps straight to a backend log line (ARCHITECTURE.md 18.4).
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';
import 'liquid_drop.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.message,
    this.title,
    this.onRetry,
    this.retryLabel,
    this.requestId,
  });

  /// Plain-language explanation. Never a stack trace, never an error code alone.
  final String message;

  final String? title;

  /// Omit when retrying cannot help. An action that does nothing is worse than none.
  final VoidCallback? onRetry;

  final String? retryLabel;
  final String? requestId;

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final text = context.vocaText;

    return Semantics(
      liveRegion: true,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(VocaSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GlassBead(
                tint: colors.errorMuted.withValues(alpha: 0.6),
                padding: const EdgeInsets.all(VocaSpacing.sm),
                child: Icon(
                  Icons.error_outline_rounded,
                  color: colors.error,
                  size: 26,
                ),
              ),
              const SizedBox(height: VocaSpacing.md),
              if (title != null) ...[
                Text(title!, style: text.title, textAlign: TextAlign.center),
                const SizedBox(height: VocaSpacing.xs),
              ],
              Text(
                message,
                style: text.bodyMedium.copyWith(color: colors.textSecondary),
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: VocaSpacing.xl),
                SecondaryButton(
                  label: retryLabel ?? 'Retry',
                  onPressed: onRetry,
                  expand: false,
                ),
              ],
              if (requestId != null) ...[
                const SizedBox(height: VocaSpacing.md),
                SelectableText(
                  requestId!,
                  style: text.caption.copyWith(color: colors.textDisabled),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
