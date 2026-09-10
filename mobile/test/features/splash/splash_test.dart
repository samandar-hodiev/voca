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

void main() {
  testWidgets('the app opens on the splash, not on a product screen', (tester) async {
    final (app, _) = buildApp(onboardingCompleted: true, signedIn: true);
    await tester.pumpWidget(app);
    await tester.pump();

    expect(find.byType(SplashPage), findsOneWidget);
    expect(find.text('Voca'), findsOneWidget);
    expect(find.text('Home'), findsNothing);

    // Let the pending navigation resolve so the test does not end mid-timer.
    await tester.pumpAndSettle();
  });

  testWidgets('the splash uses the liquid and glass layers', (tester) async {
    final (app, _) = buildApp(onboardingCompleted: true, signedIn: true);
    await tester.pumpWidget(app);
    await tester.pump();

    expect(find.byType(LiquidBackground), findsOneWidget);
    expect(find.byType(GlassSurface), findsOneWidget);

    await tester.pumpAndSettle();
  });

  testWidgets('it hands over to home once startup work finishes', (tester) async {
    final (app, _) = buildApp(onboardingCompleted: true, signedIn: true);
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    expect(find.byType(SplashPage), findsNothing);
    expect(find.text('Home'), findsWidgets);
  });

  // The splash is a transition, not a destination: it must not be reachable by going
  // back from the first real screen.
  testWidgets('the splash is replaced, not pushed', (tester) async {
    final (app, container) = buildApp(onboardingCompleted: true, signedIn: true);
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    final router = container.read(routerProvider);
    expect(router.canPop(), isFalse,
        reason: 'nothing should remain beneath the first real screen');
  });

  testWidgets('the splash route is the initial location', (tester) async {
    final (app, container) = buildApp(onboardingCompleted: true, signedIn: true);
    await tester.pumpWidget(app);
    await tester.pump();

    expect(
      container.read(routerProvider).routerDelegate.currentConfiguration.uri.path,
      Routes.splash,
    );

    await tester.pumpAndSettle();
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
    await tester.pump(splashMinimumDuration + const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(OnboardingPage), findsOneWidget);
    expect(find.text('Home'), findsNothing);
  });

  testWidgets('once onboarding is completed it goes straight to the product',
      (tester) async {
    final (app, _) = buildApp(onboardingCompleted: true, signedIn: true);
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingPage), findsNothing);
    expect(find.text('Home'), findsWidgets);
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
    expect(find.text('Home'), findsWidgets);
  });
}
