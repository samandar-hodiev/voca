/// Home data from a local mock.
///
/// There is no dashboard endpoint yet. This stands in for it with realistic numbers so the
/// screen can be built and judged properly; replacing it is a new implementation of
/// [HomeRepository] and nothing else changes.
library;

import '../../domain/entities/home_summary.dart';
import '../../domain/repositories/home_repository.dart';

class MockHomeRepository implements HomeRepository {
  const MockHomeRepository({this.latency = const Duration(milliseconds: 220)});

  final Duration latency;

  @override
  Future<HomeSummary> summary({required int dailyGoal}) async {
    await Future<void>.delayed(latency);
    final goal = dailyGoal <= 0 ? 10 : dailyGoal;
    return HomeSummary(
      wordsDoneToday: (goal * 0.7).round(),
      dailyGoal: goal,
      streakDays: 5,
      latestScore: 82,
      scoreDelta: 6,
      weakSounds: const ['θ', 'r', 'w', 'ð'],
      recommended: const [
        PracticeSuggestion(
          word: 'think',
          ipa: '/θɪŋk/',
          focusSound: 'θ',
          level: 'A2',
        ),
        PracticeSuggestion(
          word: 'world',
          ipa: '/wɜːld/',
          focusSound: 'w',
          level: 'B1',
        ),
        PracticeSuggestion(
          word: 'rarely',
          ipa: '/ˈreəli/',
          focusSound: 'r',
          level: 'B1',
        ),
      ],
    );
  }
}
