// Loading, error and empty states.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voca/core/widgets/empty_view.dart';
import 'package:voca/core/widgets/error_view.dart';
import 'package:voca/core/widgets/loading_view.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('LoadingView shows a spinner and an optional message', (tester) async {
    await tester.pumpWithTheme(const LoadingView(message: 'Assessing'));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Assessing'), findsOneWidget);
  });

  group('ErrorView', () {
    testWidgets('shows the message and calls onRetry', (tester) async {
      var retries = 0;
      await tester.pumpWithTheme(
        ErrorView(message: 'No connection.', onRetry: () => retries++),
      );

      expect(find.text('No connection.'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(retries, 1);
    });

    // Retry must be absent when it cannot help; an action that does nothing is worse
    // than no action.
    testWidgets('offers no retry when none was given', (tester) async {
      await tester.pumpWithTheme(const ErrorView(message: 'Not available here.'));

      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('shows the request ID when present, so it can be quoted', (tester) async {
      await tester.pumpWithTheme(
        const ErrorView(message: 'Failed.', requestId: 'req_abc123'),
      );

      expect(find.text('req_abc123'), findsOneWidget);
    });
  });

  group('EmptyView', () {
    testWidgets('shows title, message and action', (tester) async {
      var tapped = 0;
      await tester.pumpWithTheme(
        EmptyView(
          title: 'Nothing yet',
          message: 'Practised words appear here.',
          actionLabel: 'Start practice',
          onAction: () => tapped++,
        ),
      );

      expect(find.text('Nothing yet'), findsOneWidget);
      expect(find.text('Practised words appear here.'), findsOneWidget);

      await tester.tap(find.text('Start practice'));
      await tester.pump();

      expect(tapped, 1);
    });

    testWidgets('renders without an action', (tester) async {
      await tester.pumpWithTheme(const EmptyView(title: 'Nothing yet'));

      expect(find.text('Nothing yet'), findsOneWidget);
    });
  });
}
