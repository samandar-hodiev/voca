// The splash screen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voca/app.dart';
import 'package:voca/core/config/app_config.dart';
import 'package:voca/core/config/flavor.dart';
import 'package:voca/core/di/providers.dart';
import 'package:voca/core/widgets/glass_surface.dart';
import 'package:voca/core/widgets/liquid_background.dart';
import 'package:voca/features/splash/presentation/pages/splash_page.dart';
import 'package:voca/routing/routes.dart';

(Widget, ProviderContainer) _app() {
  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(AppConfig.forFlavor(Flavor.dev)),
      platformProvider.overrideWithValue('test'),
    ],
  );
  return (
    UncontrolledProviderScope(container: container, child: const VocaApp()),
    container,
  );
}

void main() {
  testWidgets('the app opens on the splash, not on a product screen', (tester) async {
    final (app, _) = _app();
    await tester.pumpWidget(app);
    await tester.pump();

    expect(find.byType(SplashPage), findsOneWidget);
    expect(find.text('Voca'), findsOneWidget);
    expect(find.text('Home'), findsNothing);

    // Let the pending navigation resolve so the test does not end mid-timer.
    await tester.pumpAndSettle();
  });

  testWidgets('the splash uses the liquid and glass layers', (tester) async {
    final (app, _) = _app();
    await tester.pumpWidget(app);
    await tester.pump();

    expect(find.byType(LiquidBackground), findsOneWidget);
    expect(find.byType(GlassSurface), findsOneWidget);

    await tester.pumpAndSettle();
  });

  testWidgets('it hands over to home once startup work finishes', (tester) async {
    final (app, _) = _app();
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    expect(find.byType(SplashPage), findsNothing);
    expect(find.text('Home'), findsWidgets);
  });

  // The splash is a transition, not a destination: it must not be reachable by going
  // back from the first real screen.
  testWidgets('the splash is replaced, not pushed', (tester) async {
    final (app, container) = _app();
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    final router = container.read(routerProvider);
    expect(router.canPop(), isFalse,
        reason: 'nothing should remain beneath the first real screen');
  });

  testWidgets('the splash route is the initial location', (tester) async {
    final (app, container) = _app();
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
  testWidgets('it renders and hands over with reduced motion', (tester) async {
    final (app, _) = _app();
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
