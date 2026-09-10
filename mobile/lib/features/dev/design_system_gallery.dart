/// A development-only gallery of the design system.
///
/// NOT A PRODUCT SCREEN. It is routed only in dev and staging builds and exists so the
/// tokens and primitives can be reviewed on a real device, in both themes, at any screen
/// size, before a single product screen depends on them.
///
/// It also serves as the honest answer to "does the foundation actually render?".
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_divider.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/glass_surface.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/section_header.dart';

class DesignSystemGallery extends StatelessWidget {
  const DesignSystemGallery({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final text = context.vocaText;

    return Scaffold(
      appBar: AppBar(title: const Text('Design system')),
      body: SafeArea(
        child: PageContainer(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: VocaSpacing.lg),
            children: [
              const SectionHeader(
                title: 'Typography',
                subtitle: 'Semantic styles, system font',
              ),
              Text('Display', style: text.display),
              Text('Headline', style: text.headline),
              Text('Title', style: text.title),
              Text('Subtitle', style: text.subtitle),
              Text('Body — the default reading style.', style: text.body),
              Text(
                'Caption',
                style: text.caption.copyWith(color: colors.textSecondary),
              ),
              const SizedBox(height: VocaSpacing.xl),

              const SectionHeader(
                title: 'Colour',
                subtitle: 'Semantic tokens only',
              ),
              Wrap(
                spacing: VocaSpacing.xs,
                runSpacing: VocaSpacing.xs,
                children: [
                  _Swatch('primary', colors.primary),
                  _Swatch('surface', colors.surface),
                  _Swatch('border', colors.border),
                  _Swatch('success', colors.success),
                  _Swatch('warning', colors.warning),
                  _Swatch('error', colors.error),
                ],
              ),
              const SizedBox(height: VocaSpacing.xl),

              const SectionHeader(title: 'Buttons', subtitle: 'All states'),
              PrimaryButton(label: 'Primary', onPressed: () {}),
              const SizedBox(height: VocaSpacing.xs),
              const PrimaryButton(label: 'Primary disabled'),
              const SizedBox(height: VocaSpacing.xs),
              const PrimaryButton(label: 'Loading', isLoading: true),
              const SizedBox(height: VocaSpacing.xs),
              SecondaryButton(label: 'Secondary', onPressed: () {}),
              const SizedBox(height: VocaSpacing.xs),
              Row(
                children: [
                  VocaTextButton(label: 'Text button', onPressed: () {}),
                  const Spacer(),
                  VocaIconButton(
                    icon: Icons.play_arrow_rounded,
                    semanticLabel: 'Play',
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: VocaSpacing.xl),

              const SectionHeader(title: 'Glass', subtitle: 'Used sparingly'),
              const GlassCard(
                child: Text('A glass card lifts one thing off the page.'),
              ),
              const SizedBox(height: VocaSpacing.xl),

              const SectionHeader(title: 'Badges'),
              const Wrap(
                spacing: VocaSpacing.xs,
                runSpacing: VocaSpacing.xs,
                children: [
                  AppBadge(label: 'Neutral'),
                  AppBadge(label: 'Primary', tone: BadgeTone.primary),
                  AppBadge(label: 'Success', tone: BadgeTone.success),
                  AppBadge(label: 'Warning', tone: BadgeTone.warning),
                  AppBadge(label: 'Error', tone: BadgeTone.error),
                ],
              ),
              const SizedBox(height: VocaSpacing.xl),

              const SectionHeader(title: 'Input'),
              const AppTextField(
                label: 'Label',
                hint: 'Placeholder text',
                helperText: 'Helper text',
              ),
              const SizedBox(height: VocaSpacing.sm),
              const AppTextField(
                label: 'With error',
                errorText: 'This field is required.',
              ),
              const SizedBox(height: VocaSpacing.xl),

              const SectionHeader(title: 'States'),
              const SizedBox(height: 120, child: LoadingView(message: 'Loading')),
              const AppDivider(),
              SizedBox(
                height: 240,
                child: ErrorView(
                  title: 'Something went wrong',
                  message: 'We could not reach the server.',
                  onRetry: () {},
                  requestId: 'req_example_0000',
                ),
              ),
              const AppDivider(),
              const SizedBox(
                height: 200,
                child: EmptyView(
                  title: 'Nothing here yet',
                  message: 'Practised words will appear here.',
                ),
              ),
              const SizedBox(height: VocaSpacing.xl),

              const SectionHeader(title: 'Skeleton'),
              const SkeletonBox(height: 20),
              const SizedBox(height: VocaSpacing.xs),
              const SkeletonBox(height: 20, width: 180),
              const SizedBox(height: VocaSpacing.huge),
            ],
          ),
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch(this.name, this.color);

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 44,
          width: 64,
          decoration: BoxDecoration(
            color: color,
            borderRadius: VocaRadius.smallAll,
            border: Border.all(color: context.vocaColors.border),
          ),
        ),
        const SizedBox(height: VocaSpacing.xxs),
        Text(name, style: context.vocaText.caption),
      ],
    );
  }
}
