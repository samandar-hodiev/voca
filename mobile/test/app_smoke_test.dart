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
void main() {
  testWidgets('the app boots and lands on the home route', (tester) async {
    final (app, _) = buildApp(onboardingCompleted: true, signedIn: true);
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsWidgets);
  });

  testWidgets('navigates between routes', (tester) async {
    final (app, container) = buildApp(onboardingCompleted: true, signedIn: true);
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    final router = container.read(routerProvider);

    router.go(Routes.practice);
    await tester.pumpAndSettle();
    expect(find.text('Practice'), findsWidgets);

    router.go(Routes.progress);
    await tester.pumpAndSettle();
    expect(find.text('Progress'), findsWidgets);
  });

  testWidgets('an unknown route renders the error screen rather than crashing',
      (tester) async {
    final (app, container) = buildApp(onboardingCompleted: true, signedIn: true);
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    container.read(routerProvider).go('/definitely-not-a-route');
    await tester.pumpAndSettle();

    expect(find.text('Not found'), findsWidgets);
  });

  testWidgets('the Voca theme extensions resolve', (tester) async {
    final (app, _) = buildApp(onboardingCompleted: true, signedIn: true);
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold).first);
    expect(Theme.of(context).extension<VocaColors>(), isNotNull,
        reason: 'semantic colours must be attached to the theme');
    expect(context.vocaColors.primary, VocaColors.light.primary);
  });

  // The design-system gallery is a development tool and must never be reachable in a
  // production build.
  testWidgets('the design gallery is not routed in production', (tester) async {
    final (app, container) = buildApp(flavor: Flavor.prod, onboardingCompleted: true, signedIn: true);
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    container.read(routerProvider).go(Routes.designSystem);
    await tester.pumpAndSettle();

    expect(find.text('Design system'), findsNothing);
    expect(find.text('Not found'), findsWidgets);
  });

  testWidgets('the design gallery renders in development', (tester) async {
    final (app, container) = buildApp(onboardingCompleted: true, signedIn: true);
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    container.read(routerProvider).go(Routes.designSystem);

    // pumpAndSettle would time out here: the gallery contains a SkeletonBox, whose pulse
    // repeats forever by design. Pumping a fixed number of frames is the right tool for
    // a screen that is never "settled".
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Design system'), findsWidgets);
  });
}
