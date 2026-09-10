// First-launch setup: level, goal and daily goal.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voca/features/onboarding/presentation/controllers/setup_controller.dart';

void main() {
  group('the answers collected before an account exists', () {
    test('start empty and fill in independently', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(setupProvider.notifier);
      expect(container.read(setupProvider).isComplete, isFalse);

      notifier.setLevel('B1');
      notifier.setGoal('pronunciation');
      expect(container.read(setupProvider).isComplete, isFalse,
          reason: 'the daily goal is still missing');

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

  // The stored value is an identifier; the label is what a person reads. If the two were
  // the same value, a translation would silently change what is in the database.
  test('every level and goal option carries a stable identifier', () {
    const backendLevels = {'A1', 'A2', 'B1', 'B2', 'C1'};
    for (final level in cefrLevels) {
      expect(backendLevels, contains(level.code));
      expect(level.label, isNot(equals(level.code)),
          reason: 'the label must not be the identifier');
    }

    const backendGoals = {
      'pronunciation',
      'confidence',
      'ielts',
      'vocabulary',
      'work',
      'everyday',
    };
    for (final goal in learningGoals) {
      expect(backendGoals, contains(goal.id));
    }
  });

  test('the recommended daily goal is one of the options', () {
    expect(dailyGoalOptions, contains(recommendedDailyGoal));
  });
}
