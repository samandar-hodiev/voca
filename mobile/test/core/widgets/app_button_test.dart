// Buttons: states and accessibility guarantees.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voca/core/widgets/app_button.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('PrimaryButton', () {
    testWidgets('renders its label and fires onPressed', (tester) async {
      var taps = 0;
      await tester.pumpWithTheme(
        PrimaryButton(label: 'Continue', onPressed: () => taps++),
      );

      expect(find.text('Continue'), findsOneWidget);

      await tester.tap(find.text('Continue'));
      await tester.pump();

      expect(taps, 1);
    });

    testWidgets('is inert when no callback is given', (tester) async {
      await tester.pumpWithTheme(const PrimaryButton(label: 'Continue'));

      // Tapping must not throw, and the button must carry no action.
      await tester.tap(find.text('Continue'));
      await tester.pump();

      final button = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('shows a progress indicator instead of the label while loading',
        (tester) async {
      await tester.pumpWithTheme(
        PrimaryButton(label: 'Submit', isLoading: true, onPressed: () {}),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Submit'), findsNothing);
    });

    testWidgets('does not fire while loading', (tester) async {
      var taps = 0;
      await tester.pumpWithTheme(
        PrimaryButton(label: 'Submit', isLoading: true, onPressed: () => taps++),
      );

      await tester.tap(find.byType(PrimaryButton));
      await tester.pump();

      expect(taps, 0, reason: 'a loading button must not submit twice');
    });

    // 48 logical pixels is the accessible minimum touch target on both platforms.
    testWidgets('keeps a 48px minimum touch target', (tester) async {
      await tester.pumpWithTheme(
        PrimaryButton(label: 'x', onPressed: () {}, expand: false),
      );

      expect(
        tester.getSize(find.byType(PrimaryButton)).height,
        greaterThanOrEqualTo(48),
      );
    });
  });

  group('VocaIconButton', () {
    testWidgets('exposes its semantic label', (tester) async {
      await tester.pumpWithTheme(
        VocaIconButton(
          icon: Icons.play_arrow,
          semanticLabel: 'Play pronunciation',
          onPressed: () {},
        ),
      );

      expect(find.bySemanticsLabel('Play pronunciation'), findsOneWidget);
    });

    testWidgets('keeps a 48px minimum touch target', (tester) async {
      await tester.pumpWithTheme(
        VocaIconButton(
          icon: Icons.play_arrow,
          semanticLabel: 'Play',
          onPressed: () {},
        ),
      );

      final size = tester.getSize(find.byType(VocaIconButton));
      expect(size.height, greaterThanOrEqualTo(48));
      expect(size.width, greaterThanOrEqualTo(48));
    });
  });

  group('SecondaryButton', () {
    testWidgets('renders and responds', (tester) async {
      var taps = 0;
      await tester.pumpWithTheme(
        SecondaryButton(label: 'Later', onPressed: () => taps++),
      );

      await tester.tap(find.text('Later'));
      await tester.pump();

      expect(taps, 1);
    });
  });
}
