/// Practice content from a local mock.
///
/// Stands in for the content endpoint and the recommendation step, neither of which exists
/// yet. Pronunciation scoring is not simulated here: it belongs to the assessment feature.
library;

import '../../domain/entities/word.dart';
import '../../domain/repositories/practice_repository.dart';

class MockPracticeRepository implements PracticeRepository {
  const MockPracticeRepository({
    this.latency = const Duration(milliseconds: 220),
  });

  final Duration latency;

  @override
  Future<List<Word>> dailySet() async {
    await Future<void>.delayed(latency);
    return const [
      Word(
        id: 'w1',
        text: 'think',
        ipa: '/θɪŋk/',
        meaningUz: 'o‘ylamoq',
        level: 'A2',
        focusSound: 'θ',
        status: PronunciationStatus.needsWork,
        bestScore: 58,
      ),
      Word(
        id: 'w2',
        text: 'world',
        ipa: '/wɜːld/',
        meaningUz: 'dunyo',
        level: 'B1',
        focusSound: 'w',
        status: PronunciationStatus.good,
        bestScore: 79,
      ),
      Word(
        id: 'w3',
        text: 'rarely',
        ipa: '/ˈreəli/',
        meaningUz: 'kamdan-kam',
        level: 'B1',
        focusSound: 'r',
        status: PronunciationStatus.needsWork,
        bestScore: 61,
      ),
      Word(
        id: 'w4',
        text: 'weather',
        ipa: '/ˈweðə/',
        meaningUz: 'ob-havo',
        level: 'A2',
        focusSound: 'ð',
        status: PronunciationStatus.notStarted,
      ),
      Word(
        id: 'w5',
        text: 'three',
        ipa: '/θriː/',
        meaningUz: 'uch',
        level: 'A1',
        focusSound: 'θ',
        status: PronunciationStatus.mastered,
        bestScore: 94,
      ),
      Word(
        id: 'w6',
        text: 'comfortable',
        ipa: '/ˈkʌmftəbl/',
        meaningUz: 'qulay',
        level: 'B2',
        focusSound: 'ʌ',
        status: PronunciationStatus.notStarted,
      ),
    ];
  }
}
