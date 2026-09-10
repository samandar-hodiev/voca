/// A heading above a group of content, with an optional trailing action.
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final text = context.vocaText;

    return Padding(
      padding: const EdgeInsets.only(bottom: VocaSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Marked as a heading so screen readers can navigate between sections.
                Semantics(
                  header: true,
                  child: Text(title, style: text.title),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: VocaSpacing.xxs),
                  Text(
                    subtitle!,
                    style: text.bodyMedium.copyWith(color: colors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: VocaSpacing.sm),
            trailing!,
          ],
        ],
      ),
    );
  }
}
