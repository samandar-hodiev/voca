// A microphone and an assessment endpoint that no test has to reach for real.

import 'dart:io';

import 'package:voca/core/audio/audio_recorder.dart';
import 'package:voca/features/auth/domain/repositories/auth_repository.dart';
import 'package:voca/features/pronunciation/domain/entities/feedback.dart';
import 'package:voca/features/pronunciation/domain/entities/pronunciation_result.dart';
import 'package:voca/features/pronunciation/domain/entities/word_result.dart';
import 'package:voca/features/pronunciation/domain/repositories/pronunciation_repository.dart';

/// A microphone that writes a real file, so deletion can be observed.
class FakeRecorder implements Recorder {
  FakeRecorder({this.permitted = true, this.stopThrows});

  final bool permitted;
  final RecordingProblem? stopThrows;

  File? file;
  bool cancelled = false;
  void Function()? limit;

  @override
  Future<bool> hasPermission() async => permitted;

  @override
  Future<void> start({void Function()? onLimit}) async {
    if (!permitted) {
      throw const RecordingException(RecordingProblem.permissionDenied);
    }
    limit = onLimit;
    file = File(
      '${Directory.systemTemp.path}/fake_${DateTime.now().microsecondsSinceEpoch}.wav',
    )..writeAsBytesSync(List.filled(64, 0));
  }

  @override
  Future<RecordedClip> stop() async {
    if (stopThrows != null) throw RecordingException(stopThrows!);
    return RecordedClip(path: file!.path, durationMs: 900);
  }

  @override
  Future<void> cancel() async {
    cancelled = true;
    file?.deleteSync();
  }

  @override
  Future<void> dispose() async {}
}

class FakeRepository implements PronunciationRepository {
  FakeRepository(this._answer);

  final Result<PronunciationResult> Function() _answer;
  String? submittedPath;
  String? submittedText;
  int? submittedDuration;

  @override
  Future<Result<PronunciationResult>> submitAttempt({
    required String audioPath,
    required String referenceText,
    required String language,
    required int durationMs,
  }) async {
    submittedPath = audioPath;
    submittedText = referenceText;
    submittedDuration = durationMs;
    return _answer();
  }
}

/// A scored attempt with something wrong in it, so the chips and the advice have
/// something to render.
PronunciationResult sampleResult() => const PronunciationResult(
  id: 'a1',
  referenceText: 'think',
  recognizedText: 'sink',
  scores: PronunciationScores(
    accuracy: 82,
    fluency: 90,
    completeness: 100,
    overall: 86,
  ),
  words: [
    WordResult(
      word: 'think',
      accuracy: 58,
      error: 'mispronunciation',
      phonemes: [
        PhonemeResult(phoneme: 'θ', accuracy: 41),
        PhonemeResult(phoneme: 'ɪ', accuracy: 72),
      ],
    ),
  ],
  feedback: [
    PronunciationFeedback(
      messageKey: 'feedback.mispronunciation',
      word: 'think',
      phoneme: 'θ',
      tipKey: 'tip.tongue_between_teeth',
      priority: 10,
    ),
  ],
  audioDurationMs: 900,
);
