/// The signed-in person's account.
///
/// Who they are, how they practise, their plan, and the way out. Sign-out is always shown,
/// even when the profile fails to load: somebody who wants to leave must never be stuck
/// behind a network error.
///
/// Level and goal labels come from the onboarding lists that collected them, so the words
/// on this screen are the words the person chose from.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/glass_surface.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/press_scale.dart';
import '../../../../core/widgets/reveal.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/tab_scaffold.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../routing/routes.dart';
import '../../../auth/presentation/widgets/sign_out_button.dart';
import '../../../onboarding/presentation/controllers/setup_controller.dart';
import '../../domain/entities/profile.dart';
import '../controllers/profile_controller.dart';
import '../../../../l10n/l10n.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  static const pageKey = ValueKey('profile-page');

  static String _level(AppLocalizations l, String? code) =>
      code != null && cefrLevels.contains(code)
      ? '$code · ${l.cefrLevelName(code)}'
      : l.notChosen;

  static String _goal(AppLocalizations l, String? id) =>
      id != null && learningGoals.contains(id)
      ? l.learningGoalName(id)
      : l.notChosen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);

    return KeyedSubtree(
      key: pageKey,
      child: TabScaffold(
        title: context.l10n.navProfile,
        onRefresh: () async {
          ref.invalidate(profileProvider);
          try {
            await ref.read(profileProvider.future);
          } catch (_) {
            // The error state renders itself; the refresh gesture only has to end.
          }
        },
        children: [
          ...profile.when(
            loading: () => [
              SkeletonBox(
                height: 210,
                borderRadius: BorderRadius.circular(VocaRadius.xlarge),
              ),
              const SizedBox(height: VocaSpacing.xl),
              SkeletonBox(
                height: 170,
                borderRadius: BorderRadius.circular(VocaRadius.large),
              ),
            ],
            error: (_, __) => [
              SizedBox(
                height: 300,
                child: ErrorView(
                  message: context.l10n.profileLoadFailed,
                  onRetry: () => ref.invalidate(profileProvider),
                ),
              ),
            ],
            data: (p) => [
              Reveal(index: 0, child: _IdentityCard(profile: p)),
              const SizedBox(height: VocaSpacing.xxl),
              Reveal(
                index: 1,
                child: SectionHeader(title: context.l10n.learningSettings),
              ),
              Reveal(
                index: 1,
                child: _Group(
                  rows: [
                    _Row(
                      icon: Icons.school_outlined,
                      label: context.l10n.levelLabel,
                      value: _level(context.l10n, p.cefrLevel),
                    ),
                    _Row(
                      icon: Icons.flag_outlined,
                      label: context.l10n.goalLabel,
                      value: _goal(context.l10n, p.learningGoal),
                    ),
                    _Row(
                      icon: Icons.today_outlined,
                      label: context.l10n.dailyGoalLabel,
                      value: p.dailyGoalWords == null
                          ? context.l10n.notChosen
                          : context.l10n.wordsCount(p.dailyGoalWords!),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: VocaSpacing.xxl),
              Reveal(
                index: 2,
                child: SectionHeader(title: context.l10n.subscription),
              ),
              const Reveal(index: 2, child: _Subscription()),
              const SizedBox(height: VocaSpacing.xxl),
              Reveal(
                index: 3,
                child: SectionHeader(title: context.l10n.appSection),
              ),
              Reveal(
                index: 3,
                child: _Group(
                  rows: [
                    _Row(
                      icon: Icons.settings_outlined,
                      label: context.l10n.settingsTitle,
                      onTap: () => context.push(Routes.settings),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: VocaSpacing.xl),
          const SignOutButton(),
        ],
      ),
    );
  }
}

/// Picture, name and how the account was made. The page's one glass surface.
class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final text = context.vocaText;
    final p = profile;
    final name = p.isGuest
        ? context.l10n.guest
        : (p.displayName.isEmpty ? context.l10n.noName : p.displayName);
    final via = switch (p.provider) {
      'google' => context.l10n.viaGoogle,
      'guest' => context.l10n.guestMode,
      _ => context.l10n.viaEmail,
    };

    return GlassCard(
      edgeGlow: true,
      padding: const EdgeInsets.all(VocaSpacing.xl),
      child: Column(
        children: [
          UserAvatar(initials: p.initials, imageUrl: p.avatarUrl, size: 88),
          const SizedBox(height: VocaSpacing.md),
          Semantics(
            header: true,
            child: Text(
              name,
              style: text.headline.copyWith(color: colors.textPrimary),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (p.email != null) ...[
            const SizedBox(height: VocaSpacing.xxs),
            Text(
              p.email!,
              style: text.body.copyWith(color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: VocaSpacing.md),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: VocaSpacing.xs,
            runSpacing: VocaSpacing.xs,
            children: [
              AppBadge(label: via, tone: BadgeTone.primary),
              if (p.isGuest)
                AppBadge(
                  label: context.l10n.progressNotSaved,
                  tone: BadgeTone.warning,
                  icon: Icons.info_outline_rounded,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Subscription extends StatelessWidget {
  const _Subscription();

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final text = context.vocaText;

    return GlassSurface(
      blur: false,
      padding: const EdgeInsets.all(VocaSpacing.md),
      borderRadius: BorderRadius.circular(VocaRadius.large),
      child: Row(
        children: [
          Icon(Icons.workspace_premium_outlined, color: colors.primary),
          const SizedBox(width: VocaSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.freePlan,
                  style: text.subtitle.copyWith(color: colors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.premiumSoon,
                  style: text.caption.copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ),
          AppBadge(
            label: context.l10n.active,
            tone: BadgeTone.success,
            icon: Icons.check_rounded,
          ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.rows});

  final List<_Row> rows;

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;

    return GlassSurface(
      blur: false,
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(VocaRadius.large),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                indent: VocaSpacing.md + 24 + VocaSpacing.md,
                color: colors.border,
              ),
            rows[i],
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, this.value, this.onTap});

  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final text = context.vocaText;

    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: VocaSpacing.md),
        child: Row(
          children: [
            Icon(icon, size: 24, color: colors.textSecondary),
            const SizedBox(width: VocaSpacing.md),
            Expanded(
              child: Text(
                label,
                style: text.body.copyWith(color: colors.textPrimary),
              ),
            ),
            if (value != null)
              Flexible(
                child: Text(
                  value!,
                  style: text.bodyMedium.copyWith(color: colors.textSecondary),
                  textAlign: TextAlign.end,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (onTap != null) ...[
              const SizedBox(width: VocaSpacing.xs),
              Icon(Icons.chevron_right_rounded, color: colors.textSecondary),
            ],
          ],
        ),
      ),
    );

    if (onTap == null) {
      return Semantics(
        label: value == null ? label : '$label: $value',
        excludeSemantics: true,
        child: row,
      );
    }
    return PressScale(
      semanticLabel: label,
      onTap: onTap,
      child: ExcludeSemantics(child: row),
    );
  }
}
