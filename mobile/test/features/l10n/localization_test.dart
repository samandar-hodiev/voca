// The app in each language: English with no choice made, and whatever was chosen.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voca/core/l10n/locale_controller.dart';
import 'package:voca/core/storage/key_value_store.dart';
import 'package:voca/l10n/app_localizations.dart';

import '../../helpers/app_harness.dart';

Future<void> frames(WidgetTester tester, int count) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> openShell(WidgetTester tester, {String? language}) async {
  final (app, _) = buildApp(
    onboardingCompleted: true,
    signedIn: true,
    store: InMemoryKeyValueStore({
      'onboarding.completed.v1': true,
      localeStorageKey: ?language,
    }),
  );
  await tester.pumpWidget(app);
  await frames(tester, 30);
}

void main() {
  testWidgets('with no choice made the app is in English', (tester) async {
    await openShell(tester);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('a chosen language is used everywhere', (tester) async {
    await openShell(tester, language: 'ru');
    expect(find.text('Главная'), findsOneWidget);
    expect(find.text('Профиль'), findsOneWidget);
  });

  testWidgets('changing the language switches the app at once', (tester) async {
    final (app, container) = buildApp(
      onboardingCompleted: true,
      signedIn: true,
      store: InMemoryKeyValueStore({'onboarding.completed.v1': true}),
    );
    await tester.pumpWidget(app);
    await frames(tester, 30);
    expect(find.text('Home'), findsOneWidget);

    await container.read(localeProvider.notifier).select('uz');
    await frames(tester, 5);
    expect(find.text('Bosh sahifa'), findsOneWidget);
  });

  // Counts read naturally in each language: Russian has three plural forms, English
  // two, and Uzbek does not inflect the noun after a number.
  test('counts use each language’s plural forms', () {
    final ru = lookupAppLocalizations(const Locale('ru'));
    expect(ru.daysCount(1), '1 день');
    expect(ru.daysCount(2), '2 дня');
    expect(ru.daysCount(5), '5 дней');
    expect(ru.daysCount(21), '21 день');

    final en = lookupAppLocalizations(const Locale('en'));
    expect(en.wordsCount(1), '1 word');
    expect(en.wordsCount(3), '3 words');

    final uz = lookupAppLocalizations(const Locale('uz'));
    expect(uz.daysCount(3), '3 kun');
    expect(uz.wordsCount(1), '1 ta so‘z');
  });
}
