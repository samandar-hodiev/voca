/// Empty state.
///
/// Empty is not an error. It says what would appear here and, when there is one, offers
/// the action that fills it. An icon is enough; a full illustration would over-dress a
/// moment the reader passes through quickly.
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';
import 'liquid_drop.dart';

class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final text = context.vocaText;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(VocaSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GlassBead(
              tint: colors.primaryMuted.withValues(alpha: 0.6),
              padding: const EdgeInsets.all(VocaSpacing.sm),
              child: Icon(icon, color: colors.primary, size: 26),
            ),
            const SizedBox(height: VocaSpacing.md),
            Text(title, style: text.title, textAlign: TextAlign.center),
            if (message != null) ...[
              const SizedBox(height: VocaSpacing.xs),
              Text(
                message!,
                style: text.bodyMedium.copyWith(color: colors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: VocaSpacing.xl),
              PrimaryButton(
                label: actionLabel!,
                onPressed: onAction,
                expand: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
