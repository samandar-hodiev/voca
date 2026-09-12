// The states the mocks never produce: nothing practised yet, a goal already met, an empty
// set, and a screen that has to fit a short viewport.
//
// The dashboards are built against mock repositories with comfortable numbers, so the
// interesting states are the ones a real first-day account would see. Each test swaps in a
// repository that returns that state and checks the screen says something sensible instead
// of rendering a blank, a zero, or an overflow.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voca/features/home/domain/entities/home_summary.dart';
import 'package:voca/features/home/domain/repositories/home_repository.dart';
import 'package:voca/features/practice/domain/entities/word.dart';
import 'package:voca/features/practice/domain/repositories/practice_repository.dart';
import 'package:voca/features/practice/presentation/widgets/word_practice_sheet.dart';
import 'package:voca/features/progress/domain/entities/progress_summary.dart';
import 'package:voca/features/progress/domain/repositories/progress_repository.dart';

import '../helpers/app_harness.dart';
import '../helpers/pump_app.dart';

/// A fixed number of frames rather than pumpAndSettle: the tab drop and the reveal both
/// run on entry, and a test should say how long it lets them run.
Future<void> frames(WidgetTester tester, int count) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Finder nav(int i) => find.byKey(ValueKey('liquid-nav-$i'));

/// Scrolls a tab's own list to [target]. A ListView only builds what is near the screen,
/// and the other tabs stay alive offstage with lists of their own, so the scroll has to
/// name the list it means.
Future<void> scrollTo(WidgetTester tester, Key page, Finder target) async {
  final list = find
      .descendant(of: find.byKey(page), matching: find.byType(Scrollable))
      .first;
  await tester.scrollUntilVisible(target, 200, scrollable: list);
}

/// A learner on their first day: the goal is met, nothing else has happened yet.
const _firstDay = HomeSummary(
  wordsDoneToday: 10,
  dailyGoal: 10,
  streakDays: 0,
  latestScore: null,
  scoreDelta: 0,
  weakSounds: [],
  recommended: [],
);

class _FakeHomeRepository implements HomeRepository {
  const _FakeHomeRepository(this._value);

  final HomeSummary _value;

  @override
  Future<HomeSummary> summary({required int dailyGoal}) async => _value;
}

class _EmptyPracticeRepository implements PracticeRepository {
  const _EmptyPracticeRepository();

  @override
  Future<List<Word>> dailySet() async => const [];
}

class _BlankProgressRepository implements ProgressRepository {
  const _BlankProgressRepository();

  @override
  Future<ProgressSummary> summary() async => const ProgressSummary(
    overallScore: 0,
    scoreDelta: 0,
    wordsPracticed: 0,
    streakDays: 0,
    bestStreak: 0,
    week: [],
    weakSounds: [],
    recent: [],
  );
}

Future<void> openSignedIn(
  WidgetTester tester, {
  HomeRepository? home,
  PracticeRepository? practice,
  ProgressRepository? progress,
}) async {
  final (app, _) = buildApp(
    onboardingCompleted: true,
    signedIn: true,
    homeRepository: home,
    practiceRepository: practice,
    progressRepository: progress,
  );
  await tester.pumpWidget(app);
  await frames(tester, 30);
}

void main() {
  testWidgets('a met goal is congratulated, not shown as words remaining', (
    tester,
  ) async {
    await openSignedIn(tester, home: const _FakeHomeRepository(_firstDay));

    expect(find.text('Maqsad bajarildi'), findsOneWidget);
    expect(find.text('Bugungi maqsad'), findsNothing);
  });

  testWidgets('no weak sounds yet says so rather than leaving a gap', (
    tester,
  ) async {
    await openSignedIn(tester, home: const _FakeHomeRepository(_firstDay));

    final sentence = find.text('Hozircha zaif tovush aniqlanmadi.');
    await scrollTo(tester, const ValueKey('home-dashboard'), sentence);

    expect(sentence, findsOneWidget);
  });

  testWidgets('an empty practice set offers the way out of the filter', (
    tester,
  ) async {
    await openSignedIn(tester, practice: const _EmptyPracticeRepository());

    await tester.tap(nav(1));
    await frames(tester, 8);

    expect(find.text('Bu darajada so‘z yo‘q'), findsOneWidget);
    expect(find.text('Barchasini ko‘rsatish'), findsOneWidget);
  });

  testWidgets('progress with nothing recorded still renders', (tester) async {
    await openSignedIn(tester, progress: const _BlankProgressRepository());

    await tester.tap(nav(2));
    await frames(tester, 8);

    expect(find.byKey(const ValueKey('progress-page')), findsOneWidget);

    final sentence = find.text('Hali mashq qilinmagan.');
    await scrollTo(tester, const ValueKey('progress-page'), sentence);

    expect(sentence, findsOneWidget);
  });

  // 320 by 568 is the smallest phone the app claims to support. The hero stacks its ring
  // above the copy below 300 points of card width, and nothing may overflow.
  testWidgets('the dashboard fits a small phone', (tester) async {
    tester.view.physicalSize = const Size(960, 1704);
    tester.view.devicePixelRatio = 3;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await openSignedIn(tester);

    expect(find.byKey(const ValueKey('home-dashboard')), findsOneWidget);
  });

  // The sheet is taller than a short viewport, so it has to scroll rather than overflow.
  testWidgets('the practice sheet scrolls when the viewport is short', (
    tester,
  ) async {
    await tester.pumpWithTheme(
      Builder(
        builder: (context) => TextButton(
          onPressed: () => showWordPracticeSheet(
            context,
            const Word(
              id: 'w1',
              text: 'think',
              ipa: '/θɪŋk/',
              meaningUz: 'o‘ylamoq',
              level: 'A2',
              focusSound: 'θ',
            ),
          ),
          child: const Text('open'),
        ),
      ),
      surfaceSize: const Size(320, 420),
    );

    await tester.tap(find.text('open'));
    await frames(tester, 8);

    expect(find.text('think'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(SingleChildScrollView),
        matching: find.text('think'),
      ),
      findsOneWidget,
    );
  });
}
