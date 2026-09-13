/// The record → assess → result state machine, and the wiring behind it.
///
/// One place owns the whole loop so the sheet stays a view: it renders the state and sends
/// two intents (start, stop). Everything that can go wrong — permission refused, a clip too
/// short to score, an unreachable server — arrives as state, not as an exception the widget
/// has to catch.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/audio/audio_recorder.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/error/failure.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../data/datasources/pronunciation_remote_data_source.dart';
import '../../data/repositories/pronunciation_repository_impl.dart';
import '../../domain/entities/pronunciation_result.dart';
import '../../domain/repositories/pronunciation_repository.dart';
import '../../domain/usecases/submit_pronunciation_attempt.dart';

/// The microphone. Held by the provider rather than the controller so it is disposed once,
/// and so a test can put a fake in its place.
final recorderProvider = Provider<Recorder>((ref) {
  final recorder = VoiceRecorder();
  ref.onDispose(recorder.dispose);
  return recorder;
});

final pronunciationRepositoryProvider = Provider<PronunciationRepository>((
  ref,
) {
  return PronunciationRepositoryImpl(
    PronunciationRemoteDataSource(ref.watch(dioProvider)),
  );
});

final submitPronunciationAttemptProvider = Provider<SubmitPronunciationAttempt>(
  (ref) =>
      SubmitPronunciationAttempt(ref.watch(pronunciationRepositoryProvider)),
);

/// Where an attempt is. [scored] and the two failures are terminal until the learner
/// starts again.
enum AttemptStatus { idle, recording, assessing, scored, failed }

class AttemptState {
  const AttemptState({
    this.status = AttemptStatus.idle,
    this.result,
    this.failure,
    this.problem,
  });

  final AttemptStatus status;

  /// Present only when [status] is [AttemptStatus.scored].
  final PronunciationResult? result;

  /// Why the request failed, when the failure came from the network or the server.
  final Failure? failure;

  /// Why the recording failed, when it never left the device. Kept apart from [failure]
  /// because the two need different words: one is about the phone, the other about us.
  final RecordingProblem? problem;

  bool get isBusy =>
      status == AttemptStatus.recording || status == AttemptStatus.assessing;
}

class AttemptController extends StateNotifier<AttemptState> {
  AttemptController(this._recorder, this._submit) : super(const AttemptState());

  final Recorder _recorder;
  final SubmitPronunciationAttempt _submit;

  /// The language being assessed — not the interface language. A learner reading the app
  /// in Uzbek is still practising English.
  static const assessedLanguage = 'en-US';

  /// Starts recording, or stops and submits if already recording. The mic button is one
  /// control, so it is one method: two entry points would let the view get out of step
  /// with what the microphone is actually doing.
  Future<void> toggle(String referenceText) async {
    if (state.status == AttemptStatus.recording) {
      await _stopAndSubmit(referenceText);
      return;
    }
    if (state.status == AttemptStatus.assessing) return;
    await _start(referenceText);
  }

  Future<void> _start(String referenceText) async {
    state = const AttemptState(status: AttemptStatus.recording);
    try {
      // Fires only if the learner never stops: the clip would grow past what the server
      // accepts, so it is stopped and submitted at the limit rather than rejected later.
      await _recorder.start(onLimit: () => _stopAndSubmit(referenceText));
    } on RecordingException catch (e) {
      state = AttemptState(status: AttemptStatus.failed, problem: e.problem);
    }
  }

  Future<void> _stopAndSubmit(String referenceText) async {
    if (state.status != AttemptStatus.recording) return;
    state = const AttemptState(status: AttemptStatus.assessing);

    RecordedClip clip;
    try {
      clip = await _recorder.stop();
    } on RecordingException catch (e) {
      state = AttemptState(status: AttemptStatus.failed, problem: e.problem);
      return;
    }

    final result = await _submit(
      audioPath: clip.path,
      referenceText: referenceText,
      language: assessedLanguage,
      durationMs: clip.durationMs,
    );

    if (mounted) {
      state = switch (result) {
        Ok(value: final r) => AttemptState(
          status: AttemptStatus.scored,
          result: r,
        ),
        Err(failure: final f) => AttemptState(
          status: AttemptStatus.failed,
          failure: f,
        ),
      };
    }

    // Cleanup comes after the result is on screen, not before it: the learner should not
    // wait on a file deletion to see their score. The recording leaves the device and is
    // then gone from it whether or not the request succeeded — the app keeps no audio
    // (ARCHITECTURE.md 12.3).
    await clip.delete();
  }

  /// Back to the beginning, for "try again" and for closing the sheet.
  Future<void> reset() async {
    if (state.status == AttemptStatus.recording) await _recorder.cancel();
    state = const AttemptState();
  }
}

/// Auto-disposed: the sheet is the attempt's whole lifetime, and a score left in memory
/// would greet the next word that opens.
final attemptControllerProvider =
    StateNotifierProvider.autoDispose<AttemptController, AttemptState>((ref) {
      return AttemptController(
        ref.watch(recorderProvider),
        ref.watch(submitPronunciationAttemptProvider),
      );
    });
