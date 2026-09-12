/// The learner's dashboard: the first screen after signing in.
///
/// It answers "what should I do now" first, with the day's goal and one call to action,
/// and puts everything else below it in the order it is likely to change that answer. The
/// hero is the only glass on the page. The stat and list cards are solid, so the thing to
/// act on is the thing that floats.
///
/// The numbers come from a mock repository until a dashboard endpoint exists. The name is
/// real: it comes from the signed-in person's profile.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/glass_surface.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/press_scale.dart';
import '../../../../core/widgets/progress_visuals.dart';
import '../../../../core/widgets/reveal.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/sound_symbol.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../../../core/widgets/tab_scaffold.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../routing/routes.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import '../../domain/entities/home_summary.dart';
import '../controllers/home_controller.dart';
import '../../../../l10n/l10n.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  /// A stable anchor for "the signed-in person reached the product".
  static const dashboardKey = ValueKey('home-dashboard');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).valueOrNull;
    final summary = ref.watch(homeSummaryProvider);

    return KeyedSubtree(
      key: dashboardKey,
      child: TabScaffold(
        header: _Greeting(profile: profile),
        onRefresh: () async {
          ref.invalidate(profileProvider);
          ref.invalidate(homeSummaryProvider);
          try {
            await ref.read(homeSummaryProvider.future);
          } catch (_) {
            // The error state renders itself; the refresh gesture only has to end.
          }
        },
        children: summary.when(
          loading: () => const [_HomeLoading()],
          error: (_, __) => [
            SizedBox(
              height: 320,
              child: ErrorView(
                message: context.l10n.homeLoadFailed,
                onRetry: () => ref.invalidate(homeSummaryProvider),
              ),
            ),
          ],
          data: (s) => [
            Reveal(index: 0, child: _HeroCard(summary: s)),
            const SizedBox(height: VocaSpacing.md),
            Reveal(index: 1, child: _Stats(summary: s)),
            const SizedBox(height: VocaSpacing.xxl),
            Reveal(
              index: 2,
              child: SectionHeader(
                title: context.l10n.recommendedPractice,
                subtitle: context.l10n.recommendedPracticeHint,
              ),
            ),
            for (var i = 0; i < s.recommended.length; i++) ...[
              Reveal(
                index: 3 + i,
                child: _SuggestionTile(item: s.recommended[i]),
              ),
              const SizedBox(height: VocaSpacing.sm),
            ],
            const SizedBox(height: VocaSpacing.lg),
            Reveal(
              index: 6,
              child: SectionHeader(
                title: context.l10n.weakSounds,
                subtitle: context.l10n.weakSoundsHint,
              ),
            ),
            Reveal(index: 6, child: _WeakSounds(sounds: s.weakSounds)),
          ],
        ),
      ),
    );
  }
}

/// "Xayrli tong, Samandar", the question that frames the page, and the way to the profile.
class _Greeting extends StatelessWidget {
  const _Greeting({required this.profile});

  final Profile? profile;

  static String _salutation(AppLocalizations l, int hour) {
    if (hour < 12) return l.goodMorning;
    if (hour < 18) return l.goodAfternoon;
    return l.goodEvening;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final text = context.vocaText;

    // The name is optional. A greeting that waits for a network answer before it can say
    // hello is worse than one that says hello without a name.
    final name = profile?.firstName?.trim();
    final salutation = _salutation(context.l10n, DateTime.now().hour);
    final hello = (name == null || name.isEmpty)
        ? salutation
        : '$salutation, $name';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  hello,
                  style: text.headline.copyWith(color: colors.textPrimary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: VocaSpacing.xxs),
              Text(
                context.l10n.readyToPractise,
                style: text.body.copyWith(color: colors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(width: VocaSpacing.sm),
        PressScale(
          semanticLabel: context.l10n.openProfile,
          onTap: () => context.go(Routes.profile),
          child: ExcludeSemantics(
            child: UserAvatar(
              initials: profile?.initials ?? '·',
              imageUrl: profile?.avatarUrl,
              size: 48,
            ),
          ),
        ),
      ],
    );
  }
}

/// The day's goal and the one thing to do next. The only glass surface on the page.
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.summary});

  final HomeSummary summary;

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final text = context.vocaText;
    final s = summary;
    final remaining = (s.dailyGoal - s.wordsDoneToday).clamp(0, s.dailyGoal);

    final ring = Semantics(
      label: context.l10n.todayGoalSemantic(s.wordsDoneToday, s.dailyGoal),
      excludeSemantics: true,
      child: ProgressRing(
        value: s.goalProgress,
        size: 96,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${s.wordsDoneToday}/${s.dailyGoal}',
              style: text.title.copyWith(color: colors.textPrimary),
            ),
            Text(
              context.l10n.wordsUnit,
              style: text.caption.copyWith(color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );

    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.goalMet ? context.l10n.goalReached : context.l10n.todayGoal,
          style: text.subtitle.copyWith(color: colors.textPrimary),
        ),
        const SizedBox(height: VocaSpacing.xxs),
        Text(
          s.goalMet
              ? context.l10n.goalReachedNote
              : context.l10n.wordsLeft(remaining),
          style: text.body.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: VocaSpacing.md),
        PrimaryButton(
          label: context.l10n.startPractice,
          icon: Icons.mic_rounded,
          onPressed: () => context.go(Routes.practice),
        ),
      ],
    );

    return GlassCard(
      edgeGlow: true,
      padding: const EdgeInsets.all(VocaSpacing.lg),
      child: LayoutBuilder(
        builder: (context, box) {
          // Narrow phones stack the ring above the copy rather than squeezing the button.
          if (box.maxWidth < 300) {
            return Column(
              children: [
                ring,
                const SizedBox(height: VocaSpacing.md),
                copy,
              ],
            );
          }
          return Row(
            children: [
              ring,
              const SizedBox(width: VocaSpacing.lg),
              Expanded(child: copy),
            ],
          );
        },
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.summary});

  final HomeSummary summary;

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final s = summary;
    final score = s.latestScore;
    final up = s.scoreDelta >= 0;

    return StatPair(
      left: StatCard(
        label: context.l10n.streak,
        value: context.l10n.daysCount(s.streakDays),
        icon: Icons.local_fire_department_rounded,
        accent: colors.warning,
        caption: context.l10n.daysInARow,
      ),
      right: StatCard(
        label: context.l10n.latestScore,
        value: score == null ? '—' : '$score/100',
        // Direction is carried by the icon and the sign, not only by the colour.
        icon: up ? Icons.trending_up_rounded : Icons.trending_down_rounded,
        accent: up ? colors.success : colors.error,
        caption: score == null
            ? context.l10n.noPracticeYet
            : context.l10n.pointsThisWeek(up ? '+' : '-', s.scoreDelta.abs()),
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({required this.item});

  final PracticeSuggestion item;

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final text = context.vocaText;

    return PressScale(
      semanticLabel: context.l10n.practiseWordSemantic(item.word, item.level),
      onTap: () => context.go(Routes.practice),
      child: ExcludeSemantics(
        child: GlassSurface(
          blur: false,
          padding: const EdgeInsets.all(VocaSpacing.md),
          borderRadius: BorderRadius.circular(VocaRadius.large),
          child: Row(
            children: [
              SoundSymbol(symbol: item.focusSound),
              const SizedBox(width: VocaSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.word,
                      style: text.title.copyWith(color: colors.textPrimary),
                    ),
                    const SizedBox(height: VocaSpacing.xxs),
                    Text(
                      item.ipa,
                      style: text.bodyMedium.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              AppBadge(label: item.level, tone: BadgeTone.primary),
              const SizedBox(width: VocaSpacing.xs),
              Icon(Icons.chevron_right_rounded, color: colors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeakSounds extends StatelessWidget {
  const _WeakSounds({required this.sounds});

  final List<String> sounds;

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final text = context.vocaText;

    if (sounds.isEmpty) {
      return Text(
        context.l10n.noWeakSoundsYet,
        style: text.body.copyWith(color: colors.textSecondary),
      );
    }

    return Wrap(
      spacing: VocaSpacing.sm,
      runSpacing: VocaSpacing.sm,
      children: [
        for (final symbol in sounds)
          PressScale(
            semanticLabel: context.l10n.weakSoundOpen(symbol),
            onTap: () => context.go(Routes.progress),
            child: ExcludeSemantics(
              child: SoundSymbol(symbol: symbol, size: 56),
            ),
          ),
      ],
    );
  }
}

class _HomeLoading extends StatelessWidget {
  const _HomeLoading();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.loading,
      child: Column(
        children: [
          SkeletonBox(
            height: 150,
            borderRadius: BorderRadius.circular(VocaRadius.xlarge),
          ),
          const SizedBox(height: VocaSpacing.md),
          SkeletonBox(
            height: 104,
            borderRadius: BorderRadius.circular(VocaRadius.large),
          ),
          const SizedBox(height: VocaSpacing.md),
          for (var i = 0; i < 3; i++) ...[
            SkeletonBox(
              height: 72,
              borderRadius: BorderRadius.circular(VocaRadius.large),
            ),
            const SizedBox(height: VocaSpacing.sm),
          ],
        ],
      ),
    );
  }
}
