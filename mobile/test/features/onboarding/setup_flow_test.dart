// First-launch setup: level, goal and daily goal.

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voca/features/onboarding/presentation/controllers/setup_controller.dart';
import 'package:voca/l10n/app_localizations.dart';

void main() {
  group('the answers collected before an account exists', () {
    test('start empty and fill in independently', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(setupProvider.notifier);
      expect(container.read(setupProvider).isComplete, isFalse);

      notifier.setLevel('B1');
      notifier.setGoal('pronunciation');
      expect(
        container.read(setupProvider).isComplete,
        isFalse,
        reason: 'the daily goal is still missing',
      );

      notifier.setDailyGoal(10);
      expect(container.read(setupProvider).isComplete, isTrue);
    });

    test('changing one answer leaves the others alone', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(setupProvider.notifier);
      notifier.setLevel('A2');
      notifier.setGoal('ielts');
      notifier.setDailyGoal(15);

      notifier.setLevel('C1');

      final answers = container.read(setupProvider);
      expect(answers.level, 'C1');
      expect(answers.goal, 'ielts');
      expect(answers.dailyGoalWords, 15);
    });
  });

  // The stored value is an identifier; the name is what a person reads, in their own
  // language. If the two were the same value, a translation would silently change what
  // is in the database.
  test('every level and goal option is a stable identifier', () {
    const backendLevels = {'A1', 'A2', 'B1', 'B2', 'C1'};
    expect(cefrLevels.toSet(), backendLevels);

    const backendGoals = {
      'pronunciation',
      'confidence',
      'ielts',
      'vocabulary',
      'work',
      'everyday',
    };
    expect(learningGoals.toSet(), backendGoals);
  });

  test('every level and goal has a name in every language', () {
    for (final language in ['en', 'uz', 'ru']) {
      final l = lookupAppLocalizations(Locale(language));
      for (final level in cefrLevels) {
        expect(
          l.cefrLevelName(level),
          isNot(level),
          reason: '$language $level',
        );
        expect(
          l.cefrLevelHint(level),
          isNot(level),
          reason: '$language $level',
        );
      }
      for (final goal in learningGoals) {
        expect(
          l.learningGoalName(goal),
          isNot(goal),
          reason: '$language $goal',
        );
      }
    }
  });

  test('the recommended daily goal is one of the options', () {
    expect(dailyGoalOptions, contains(recommendedDailyGoal));
  });
}
