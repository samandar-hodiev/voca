/// The frame every first-launch screen shares.
///
/// Liquid background, safe areas, a scrolling content column and a pinned primary action.
///
/// The action is pinned rather than scrolled with the content so it stays reachable with
/// one thumb, and the content scrolls when the keyboard opens so an input is never hidden
/// behind it.
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/responsive.dart';
import 'app_button.dart';
import 'liquid_background.dart';

class SetupScaffold extends StatelessWidget {
  const SetupScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.primaryLabel,
    this.onPrimary,
    this.isBusy = false,
    this.footer,
    this.showBack = true,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  final String? primaryLabel;

  /// Null disables the button. A screen whose requirement is unmet passes null rather
  /// than showing an action that would fail.
  final VoidCallback? onPrimary;

  final bool isBusy;
  final Widget? footer;
  final bool showBack;

  /// An action at the top right, such as skip.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final text = context.vocaText;

    return Scaffold(
      // The background must not jump when the keyboard appears.
      resizeToAvoidBottomInset: true,
      body: LiquidBackground(
        intensity: 0.75,
        child: SafeArea(
          child: PageContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 48,
                  child: Row(
                    children: [
                      if (showBack && Navigator.of(context).canPop())
                        VocaIconButton(
                          icon: Icons.arrow_back_rounded,
                          semanticLabel: 'Orqaga',
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                      const Spacer(),
                      if (trailing != null) trailing!,
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: VocaSpacing.lg),
                    children: [
                      const SizedBox(height: VocaSpacing.sm),
                      Semantics(
                        header: true,
                        child: Text(title, style: text.headline),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: VocaSpacing.xs),
                        Text(
                          subtitle!,
                          style: text.body.copyWith(color: colors.textSecondary),
                        ),
                      ],
                      const SizedBox(height: VocaSpacing.xl),
                      child,
                    ],
                  ),
                ),
                if (primaryLabel != null)
                  PrimaryButton(
                    label: primaryLabel!,
                    onPressed: onPrimary,
                    isLoading: isBusy,
                  ),
                if (footer != null) ...[
                  const SizedBox(height: VocaSpacing.sm),
                  Center(child: footer!),
                ],
                const SizedBox(height: VocaSpacing.md),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
