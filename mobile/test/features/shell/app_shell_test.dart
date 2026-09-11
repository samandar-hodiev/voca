import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';

/// The liquid background animates forever, so pumpAndSettle never settles. A fixed number
/// of frames is the supported way to drive an app with a continuous animation.
Future<void> frames(WidgetTester tester, int count) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> openSignedIn(WidgetTester tester) async {
  final (app, _) = buildApp(onboardingCompleted: true, signedIn: true);
  await tester.pumpWidget(app);
  // The splash holds for a minimum duration before it routes anywhere.
  await frames(tester, 30);
}

Finder nav(int i) => find.byKey(ValueKey('liquid-nav-$i'));

void main() {
  testWidgets('a signed-in person lands on the dashboard with the bar', (
    tester,
  ) async {
    await openSignedIn(tester);

    expect(find.byKey(const ValueKey('home-dashboard')), findsOneWidget);
    for (var i = 0; i < 4; i++) {
      expect(
        nav(i),
        findsOneWidget,
        reason: 'destination $i should be in the bar',
      );
    }
  });

  testWidgets('the bar moves between the four tabs', (tester) async {
    await openSignedIn(tester);

    await tester.tap(nav(1));
    await frames(tester, 8);
    expect(find.byKey(const ValueKey('practice-page')), findsOneWidget);

    await tester.tap(nav(2));
    await frames(tester, 8);
    expect(find.byKey(const ValueKey('progress-page')), findsOneWidget);

    await tester.tap(nav(3));
    await frames(tester, 8);
    expect(find.byKey(const ValueKey('profile-page')), findsOneWidget);

    await tester.tap(nav(0));
    await frames(tester, 8);
    expect(find.byKey(const ValueKey('home-dashboard')), findsOneWidget);
  });

  testWidgets('the greeting uses the first name from the profile', (
    tester,
  ) async {
    await openSignedIn(tester);
    expect(find.textContaining('Test'), findsWidgets);
  });

  testWidgets('profile shows the account and offers sign out', (tester) async {
    await openSignedIn(tester);
    await tester.tap(nav(3));
    await frames(tester, 8);

    expect(find.text('test@voca.dev'), findsOneWidget);

    // Sign-out sits at the end of a list the viewport does not reach, and a ListView only
    // builds what is near the screen. Scroll the profile's own list to it: the other tabs
    // stay alive offstage and have lists of their own.
    final profileList = find
        .descendant(
          of: find.byKey(const ValueKey('profile-page')),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text('Hisobdan chiqish'),
      200,
      scrollable: profileList,
    );
    expect(find.text('Hisobdan chiqish'), findsOneWidget);
  });
}
