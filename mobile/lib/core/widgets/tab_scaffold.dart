/// The frame every tab in the signed-in app shares.
///
/// A scrolling column with a header, the page width limit, pull to refresh, and clearance
/// at the bottom for the floating navigation bar. Every tab needs all of it, so it lives
/// here once instead of being rebuilt, slightly differently, in four pages.
///
/// It is not a Scaffold. The shell owns the one Scaffold and the liquid field behind it;
/// a Scaffold per tab would paint its own background over the field and hide it.
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/responsive.dart';

class TabScaffold extends StatelessWidget {
  const TabScaffold({
    super.key,
    required this.children,
    this.title,
    this.subtitle,
    this.header,
    this.onRefresh,
  });

  final List<Widget> children;

  /// Used when [header] is null.
  final String? title;
  final String? subtitle;

  /// Replaces the title block, for a tab like Home whose top is a greeting.
  final Widget? header;

  final Future<void> Function()? onRefresh;

  /// Room the floating bar needs below the last item, so nothing scrolls out of reach
  /// underneath it.
  static double bottomClearance(BuildContext context) =>
      MediaQuery.paddingOf(context).bottom + 104;

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final text = context.vocaText;

    final top =
        header ??
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null)
              Semantics(
                header: true,
                child: Text(
                  title!,
                  style: text.headline.copyWith(color: colors.textPrimary),
                ),
              ),
            if (subtitle != null) ...[
              const SizedBox(height: VocaSpacing.xxs),
              Text(
                subtitle!,
                style: text.body.copyWith(color: colors.textSecondary),
              ),
            ],
          ],
        );

    Widget list = ListView(
      // Always scrollable so pull to refresh works even when the content is short.
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: EdgeInsets.only(
        top: VocaSpacing.md,
        bottom: bottomClearance(context),
      ),
      children: [
        PageContainer(child: top),
        const SizedBox(height: VocaSpacing.lg),
        for (final child in children) PageContainer(child: child),
      ],
    );

    if (onRefresh != null) {
      list = RefreshIndicator(
        onRefresh: onRefresh!,
        color: colors.primary,
        child: list,
      );
    }

    return Material(
      type: MaterialType.transparency,
      child: SafeArea(bottom: false, child: list),
    );
  }
}
