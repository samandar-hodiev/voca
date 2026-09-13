/// Where the practice screen gets its words.
///
/// Stands in for the content endpoint and the recommendation step, neither of which exists
/// yet. Pronunciation scoring is not simulated here: it belongs to the assessment feature.
library;

import '../../domain/entities/practice_session.dart';
import '../../domain/entities/word.dart';
import '../../domain/repositories/practice_repository.dart';
import '../datasources/practice_remote_data_source.dart';
import '../models/practice_session_dto.dart';

class MockPracticeRepository implements PracticeRepository {
  const MockPracticeRepository({
    this.latency = const Duration(milliseconds: 220),
  });

  final Duration latency;

  @override
  Future<PracticeSession> currentSession() async => PracticeSession(
    id: 'mock-session',
    status: 'in_progress',
    itemCount: (await dailySet()).length,
    completedItemCount: 0,
    averageScore: null,
    passScore: 80,
    passed: false,
    day: DateTime.now(),
    words: await dailySet(),
  );

  @override
  Future<List<PracticeDay>> week() async => [
    for (var i = 0; i < 7; i++)
      PracticeDay(
        day: DateTime.now().add(Duration(days: i)),
        status: i == 0 ? PracticeDayStatus.available : PracticeDayStatus.locked,
        unlocked: i == 0,
        wordCount: 0,
        completedCount: 0,
        averageScore: null,
      ),
  ];

  @override
  Future<PracticeSession> complete(String sessionId) async => currentSession();

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

/// The real day's set, decided by the server.
///
/// No fallback to the mock when the request fails. A set of invented words would let
/// somebody practise all day and change nothing, which is worse than an error they can
/// retry.
class PracticeRepositoryImpl implements PracticeRepository {
  const PracticeRepositoryImpl(this._remote);

  final PracticeRemoteDataSource _remote;

  @override
  Future<PracticeSession> currentSession() async {
    final json = await _remote.currentSession();
    return PracticeSessionDto.fromJson(json).toDomain();
  }

  /// The word list the practice screen shows is simply the current session's words, so
  /// the list and the day can never disagree about what is being practised.
  @override
  Future<List<Word>> dailySet() async => (await currentSession()).words;

  @override
  Future<List<PracticeDay>> week() async {
    final json = await _remote.week();
    final days = (json['days'] as List<dynamic>?) ?? const [];
    return [
      for (final d in days.whereType<Map<String, dynamic>>())
        PracticeDayDto.fromJson(d).toDomain(),
    ];
  }

  @override
  Future<PracticeSession> complete(String sessionId) async {
    final json = await _remote.complete(sessionId);
    return PracticeSessionDto.fromJson(json).toDomain();
  }
}
