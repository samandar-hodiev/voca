/// One attempt at saying a word, and where it is in its lifecycle.
///
/// The recording and scoring behind this belong to the pronunciation assessment feature,
/// which is not built yet. The state machine is defined now so the practice screens are
/// already shaped around it, and the assessment only has to drive it.
library;

import 'word.dart';

/// Ready, then recording, then assessing, then either scored or failed.
enum AttemptPhase { ready, recording, assessing, scored, failed }

class PracticeAttempt {
  const PracticeAttempt({
    required this.word,
    this.phase = AttemptPhase.ready,
    this.score,
  });

  final Word word;
  final AttemptPhase phase;

  /// Out of 100, present only once [phase] is [AttemptPhase.scored].
  final int? score;
}
