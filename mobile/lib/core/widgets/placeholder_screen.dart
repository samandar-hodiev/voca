/// A scaffolded placeholder for a route whose screen has not been built yet.
///
/// It exists so the shell can prove navigation, safe areas, theming and responsive
/// layout all work end to end before any product screen exists. Every one of these is
/// replaced by a real screen in a later task.
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/responsive.dart';
import 'app_badge.dart';
import 'glass_surface.dart';

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final text = context.vocaText;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      // SafeArea on all sides: notches, dynamic islands and gesture bars vary widely and
      // must never clip content.
      body: SafeArea(
        child: PageContainer(
          child: Center(
            child: GlassCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 32, color: colors.primary),
                  const SizedBox(height: VocaSpacing.md),
                  Text(title, style: text.headline, textAlign: TextAlign.center),
                  const SizedBox(height: VocaSpacing.xs),
                  Text(
                    description,
                    style: text.bodyMedium.copyWith(color: colors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: VocaSpacing.md),
                  const AppBadge(label: 'Not implemented yet', tone: BadgeTone.warning),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
