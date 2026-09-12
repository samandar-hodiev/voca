// The word sheet opens over the floating bar, not under it.
//
// The shell paints the bar in the Scaffold's bottomNavigationBar slot, above everything
// in the body. A sheet pushed onto the tab's own navigator lives in that body, so the bar
// covers its lower half and swallows taps meant for the close button. Tapping Close and
// checking the sheet actually goes away is what catches that: with the bar on top the tap
// lands on the bar, the tab switches, and the sheet stays.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';

Future<void> frames(WidgetTester tester, int n) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Finder nav(int i) => find.byKey(ValueKey('liquid-nav-$i'));

void main() {
  testWidgets('the word sheet opens above the bar and closes from its button', (
    tester,
  ) async {
    final (app, _) = buildApp(onboardingCompleted: true, signedIn: true);
    await tester.pumpWidget(app);
    await frames(tester, 30);

    await tester.tap(nav(1));
    await frames(tester, 10);
    expect(find.byKey(const ValueKey('practice-page')), findsOneWidget);

    await tester.tap(find.text('think').first);
    await frames(tester, 12);

    // The sheet is up: the word is shown large and the control is named.
    expect(find.text('Yopish'), findsOneWidget);

    await tester.tap(find.text('Yopish'));
    await frames(tester, 12);

    // Gone, and the tab did not change underneath it.
    expect(find.text('Yopish'), findsNothing);
    expect(find.byKey(const ValueKey('practice-page')), findsOneWidget);
  });
}
