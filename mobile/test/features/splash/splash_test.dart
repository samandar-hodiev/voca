// The splash screen.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voca/app.dart';
import 'package:voca/core/widgets/glass_surface.dart';
import 'package:voca/core/widgets/liquid_background.dart';
import 'package:voca/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:voca/features/splash/presentation/controllers/splash_controller.dart';
import 'package:voca/features/splash/presentation/pages/splash_page.dart';
import 'package:voca/routing/routes.dart';

import '../../helpers/app_harness.dart';

/// The signed-in shell carries the liquid background, whose animation repeats forever, so
/// pumpAndSettle never settles once the splash hands over to it. A fixed number of frames
/// covers the splash minimum and the first data load.
Future<void> frames(WidgetTester tester, [int count = 40]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('the app opens on the splash, not on a product screen', (
    tester,
  ) async {
    final (app, _) = buildApp(onboardingCompleted: true, signedIn: true);
    await tester.pumpWidget(app);
    await tester.pump();

    expect(find.byType(SplashPage), findsOneWidget);
    expect(find.text('Voca'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-dashboard')), findsNothing);

    // Let the pending navigation resolve so the test does not end mid-timer.
    await frames(tester);
  });

  testWidgets('the splash uses the liquid and glass layers', (tester) async {
    final (app, _) = buildApp(onboardingCompleted: true, signedIn: true);
    await tester.pumpWidget(app);
    await tester.pump();

    expect(find.byType(LiquidBackground), findsOneWidget);
    expect(find.byType(GlassSurface), findsOneWidget);

    await frames(tester);
  });

  testWidgets('it hands over to home once startup work finishes', (
    tester,
  ) async {
    final (app, _) = buildApp(onboardingCompleted: true, signedIn: true);
    await tester.pumpWidget(app);
    await frames(tester);

    expect(find.byType(SplashPage), findsNothing);
    expect(find.byKey(const ValueKey('home-dashboard')), findsWidgets);
  });

  // The splash is a transition, not a destination: it must not be reachable by going
  // back from the first real screen.
  testWidgets('the splash is replaced, not pushed', (tester) async {
    final (app, container) = buildApp(
      onboardingCompleted: true,
      signedIn: true,
    );
    await tester.pumpWidget(app);
    await frames(tester);

    final router = container.read(routerProvider);
    expect(
      router.canPop(),
      isFalse,
      reason: 'nothing should remain beneath the first real screen',
    );
  });

  testWidgets('the splash route is the initial location', (tester) async {
    final (app, container) = buildApp(
      onboardingCompleted: true,
      signedIn: true,
    );
    await tester.pumpWidget(app);
    await tester.pump();

    expect(
      container
          .read(routerProvider)
          .routerDelegate
          .currentConfiguration
          .uri
          .path,
      Routes.splash,
    );

    await frames(tester);
  });

  // Accessibility: with reduce-motion the entry animation is skipped. What matters is
  // the outcome, not which widget wraps what, so this asserts behaviour: the screen
  // renders its content and still completes its handover.
  // First run: with no stored flag the splash must hand over to ONBOARDING, not to the
  // product. This is the path a new install takes.
  testWidgets('on a first run it hands over to onboarding', (tester) async {
    final (app, _) = buildApp(onboardingCompleted: false);
    await tester.pumpWidget(app);

    // pumpAndSettle would time out here: onboarding carries the liquid background, whose
    // drift repeats forever by design. Pump past the splash minimum instead.
    await tester.pump();
    await tester.pump(
      splashMinimumDuration + const Duration(milliseconds: 400),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(OnboardingPage), findsOneWidget);
    expect(find.byKey(const ValueKey('home-dashboard')), findsNothing);
  });

  testWidgets('once onboarding is completed it goes straight to the product', (
    tester,
  ) async {
    final (app, _) = buildApp(onboardingCompleted: true, signedIn: true);
    await tester.pumpWidget(app);
    await frames(tester);

    expect(find.byType(OnboardingPage), findsNothing);
    expect(find.byKey(const ValueKey('home-dashboard')), findsWidgets);
  });

  testWidgets('it renders and hands over with reduced motion', (tester) async {
    final (app, _) = buildApp(onboardingCompleted: true, signedIn: true);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: app,
      ),
    );
    await tester.pump();

    expect(find.text('Voca'), findsOneWidget);
    expect(find.byType(GlassSurface), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('home-dashboard')), findsWidgets);
  });
}
