/// Onboarding.
///
/// Three slides, shown once. The splash decides whether to come here or go straight to
/// the product, so this screen never has to check anything itself.
///
/// Both ways out — finishing and skipping — record the same thing. Someone who skips has
/// made a decision, and showing it to them again on the next launch would override that.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/glass_surface.dart';
import '../../../../core/widgets/liquid_background.dart';
import '../../../../routing/routes.dart';
import '../controllers/onboarding_controller.dart';
import '../widgets/page_indicator.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _controller = PageController();
  int _index = 0;

  bool get _isLast => _index == onboardingSlides.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(onboardingRepositoryProvider).markCompleted();
    // Setup follows onboarding: level, goal, then daily goal. Skipping onboarding skips
    // the slides, not the questions, because the answers shape every later screen.
    if (mounted) context.go(Routes.level);
  }

  void _next() {
    if (_isLast) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: VocaMotion.respectReducedMotion(context, VocaMotion.standard),
      curve: VocaMotion.standardCurve,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LiquidBackground(
        intensity: 1.0,
        child: SafeArea(
          // The page inset is applied to the header and the footer, but NOT around the
          // PageView. A padded viewport makes the next slide appear from inside the page
          // rather than from the edge of the screen, and it leaves adjacent slides
          // touching mid-swipe because each one fills the viewport exactly. The PageView
          // therefore runs edge to edge and each slide carries its own inset, which also
          // opens a gutter of twice that inset between neighbours.
          child: Column(
            children: [
              // Skip stays available on every slide, including the last, so the way out
              // never moves.
              PageContainer(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: VocaTextButton(
                    label: 'O‘tkazib yuborish',
                    onPressed: _finish,
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: onboardingSlides.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) => _Slide(index: i),
                ),
              ),
              PageContainer(
                child: Column(
                  children: [
                    PageIndicator(count: onboardingSlides.length, index: _index),
                    const SizedBox(height: VocaSpacing.xl),
                    PrimaryButton(
                      label: _isLast ? 'Boshlash' : 'Keyingi',
                      onPressed: _next,
                    ),
                    const SizedBox(height: VocaSpacing.lg),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final slide = onboardingSlides[index];
    final colors = context.vocaColors;
    final text = context.vocaText;

    // The inset lives here rather than around the PageView, so the card keeps its margin
    // from the screen edge while the slide itself still spans the full width.
    return PageContainer(
      child: Center(
        child: SingleChildScrollView(
          child: GlassCard(
            padding: const EdgeInsets.symmetric(
              horizontal: VocaSpacing.xl,
              vertical: VocaSpacing.xxl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  slide.title,
                  style: text.headline.copyWith(color: colors.textPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: VocaSpacing.sm),
                Text(
                  slide.body,
                  style: text.body.copyWith(color: colors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
