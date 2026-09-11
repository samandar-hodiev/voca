// Application shell smoke test.
//
// Proves the foundation actually works end to end: the app boots, the theme resolves,
// the router mounts, and navigation between routes succeeds. This is the test that would
// catch a broken shell before anyone opens a simulator.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voca/app.dart';
import 'package:voca/core/config/flavor.dart';
import 'package:voca/core/theme/app_colors.dart';
import 'package:voca/routing/routes.dart';

import 'helpers/app_harness.dart';

/// Builds the app and hands back the container, so tests can read the router directly.
///
/// Reading GoRouter from a screen's BuildContext breaks as soon as that screen is
/// disposed by the navigation under test; the container outlives every route.
/// The signed-in shell carries the liquid background, whose animation repeats forever, so
/// pumpAndSettle never settles there. A fixed number of frames is the supported way to
/// drive a screen with a continuous animation; four seconds of them covers the splash and
/// the first data load.
Future<void> frames(WidgetTester tester, [int count = 40]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('the app boots and lands on the home route', (tester) async {
    final (app, _) = buildApp(onboardingCompleted: true, signedIn: true);
    await tester.pumpWidget(app);
    await frames(tester);

    expect(find.byKey(const ValueKey('home-dashboard')), findsWidgets);
  });

  testWidgets('navigates between routes', (tester) async {
    final (app, container) = buildApp(
      onboardingCompleted: true,
      signedIn: true,
    );
    await tester.pumpWidget(app);
    await frames(tester);

    final router = container.read(routerProvider);

    router.go(Routes.practice);
    await frames(tester);
    expect(find.byKey(const ValueKey('practice-page')), findsOneWidget);

    router.go(Routes.progress);
    await frames(tester);
    expect(find.byKey(const ValueKey('progress-page')), findsOneWidget);
  });

  testWidgets(
    'an unknown route renders the error screen rather than crashing',
    (tester) async {
      final (app, container) = buildApp(
        onboardingCompleted: true,
        signedIn: true,
      );
      await tester.pumpWidget(app);
      await frames(tester);

      container.read(routerProvider).go('/definitely-not-a-route');
      await frames(tester);

      expect(find.text('Not found'), findsWidgets);
    },
  );

  testWidgets('the Voca theme extensions resolve', (tester) async {
    final (app, _) = buildApp(onboardingCompleted: true, signedIn: true);
    await tester.pumpWidget(app);
    await frames(tester);

    final context = tester.element(find.byType(Scaffold).first);
    expect(
      Theme.of(context).extension<VocaColors>(),
      isNotNull,
      reason: 'semantic colours must be attached to the theme',
    );
    expect(context.vocaColors.primary, VocaColors.light.primary);
  });

  // The design-system gallery is a development tool and must never be reachable in a
  // production build.
  testWidgets('the design gallery is not routed in production', (tester) async {
    final (app, container) = buildApp(
      flavor: Flavor.prod,
      onboardingCompleted: true,
      signedIn: true,
    );
    await tester.pumpWidget(app);
    await frames(tester);

    container.read(routerProvider).go(Routes.designSystem);
    await frames(tester);

    expect(find.text('Design system'), findsNothing);
    expect(find.text('Not found'), findsWidgets);
  });

  testWidgets('the design gallery renders in development', (tester) async {
    final (app, container) = buildApp(
      onboardingCompleted: true,
      signedIn: true,
    );
    await tester.pumpWidget(app);
    await frames(tester);

    container.read(routerProvider).go(Routes.designSystem);

    // pumpAndSettle would time out here: the gallery contains a SkeletonBox, whose pulse
    // repeats forever by design. Pumping a fixed number of frames is the right tool for
    // a screen that is never "settled".
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Design system'), findsWidgets);
  });
}
