// The startup state machine.
//
// Three branches, and all three must be covered: the one a new install takes, the one a
// returning-but-signed-out person takes, and the one a returning signed-in person takes.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voca/features/auth/presentation/pages/auth_entry_page.dart';
import 'package:voca/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:voca/features/splash/presentation/controllers/splash_controller.dart';

import '../../helpers/app_harness.dart';

void main() {
  // Onboarding and the auth screens both carry the liquid background, whose drift repeats
  // forever by design, so pumpAndSettle would never return. Pumping past the splash
  // minimum is the right tool for a screen that is never "settled".
  Future<void> pumpPastSplash(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(
      splashMinimumDuration + const Duration(milliseconds: 400),
    );
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('a new install goes to onboarding', (tester) async {
    final (app, _) = buildApp(onboardingCompleted: false, signedIn: false);
    await tester.pumpWidget(app);
    await pumpPastSplash(tester);

    expect(find.byType(OnboardingPage), findsOneWidget);
  });

  testWidgets('onboarded but signed out goes to the auth entry', (
    tester,
  ) async {
    final (app, _) = buildApp(onboardingCompleted: true, signedIn: false);
    await tester.pumpWidget(app);
    await pumpPastSplash(tester);

    expect(find.byType(AuthEntryPage), findsOneWidget);
    expect(
      find.byType(OnboardingPage),
      findsNothing,
      reason: 'onboarding must not reappear once it has been completed',
    );
  });

  testWidgets('a returning signed-in person goes straight to the product', (
    tester,
  ) async {
    final (app, _) = buildApp(onboardingCompleted: true, signedIn: true);
    await tester.pumpWidget(app);
    await pumpPastSplash(tester);

    expect(find.byKey(const ValueKey('home-dashboard')), findsWidgets);
    expect(find.byType(AuthEntryPage), findsNothing);
    expect(find.byType(OnboardingPage), findsNothing);
  });

  // The splash is shown on every launch, whichever branch follows it.
  testWidgets('the splash appears on every launch', (tester) async {
    for (final signedIn in [true, false]) {
      final (app, _) = buildApp(onboardingCompleted: true, signedIn: signedIn);
      await tester.pumpWidget(app);
      await tester.pump();

      expect(
        find.text('Voca'),
        findsOneWidget,
        reason: 'signedIn=$signedIn should still show the splash',
      );

      await pumpPastSplash(tester);
    }
  });
}
