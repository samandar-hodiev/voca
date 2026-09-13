// The record → assess → result loop, without a microphone or a server.
//
// The case worth protecting is the recording being deleted: the app promises to keep no
// audio, and the delete sits after an await that a failed request could plausibly skip.
// Both outcomes are checked for it.

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voca/core/audio/audio_recorder.dart';
import 'package:voca/core/error/failure.dart';
import 'package:voca/features/auth/domain/repositories/auth_repository.dart';
import 'package:voca/features/pronunciation/domain/entities/pronunciation_result.dart';
import 'package:voca/features/pronunciation/domain/repositories/pronunciation_repository.dart';
import 'package:voca/features/pronunciation/presentation/controllers/recording_controller.dart';

import '../../helpers/pronunciation_fakes.dart';

PronunciationResult _result() => const PronunciationResult(
  id: 'a1',
  referenceText: 'think',
  recognizedText: 'think',
  scores: PronunciationScores(
    accuracy: 82,
    fluency: 90,
    completeness: 100,
    overall: 86,
  ),
  words: [],
  feedback: [],
  audioDurationMs: 900,
);

ProviderContainer containerWith(
  Recorder recorder,
  PronunciationRepository repository,
) {
  final c = ProviderContainer(
    overrides: [
      recorderProvider.overrideWithValue(recorder),
      pronunciationRepositoryProvider.overrideWithValue(repository),
    ],
  );
  // The controller is autoDispose: in the app a widget listens to it for the whole life
  // of the sheet, but a bare container drops it at the first await inside toggle() and
  // the next read builds a fresh one in the idle state. Listening here is what the
  // widget does, not a workaround.
  c.listen(attemptControllerProvider, (_, _) {});
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('records, submits, scores, and deletes the recording', () async {
    final recorder = FakeRecorder();
    final repository = FakeRepository(() => Ok(_result()));
    final c = containerWith(recorder, repository);
    final controller = c.read(attemptControllerProvider.notifier);

    await controller.toggle('think');
    expect(c.read(attemptControllerProvider).status, AttemptStatus.recording);

    await controller.toggle('think');
    final state = c.read(attemptControllerProvider);

    expect(state.status, AttemptStatus.scored);
    expect(state.result!.scores.overall, 86);
    expect(repository.submittedText, 'think');
    expect(repository.submittedDuration, 900);
    expect(File(repository.submittedPath!).existsSync(), isFalse);
  });

  test('deletes the recording even when the request fails', () async {
    final recorder = FakeRecorder();
    final repository = FakeRepository(
      () => const Err(NetworkFailure(message: 'offline')),
    );
    final c = containerWith(recorder, repository);
    final controller = c.read(attemptControllerProvider.notifier);

    await controller.toggle('think');
    await controller.toggle('think');

    final state = c.read(attemptControllerProvider);
    expect(state.status, AttemptStatus.failed);
    expect(state.failure, isA<NetworkFailure>());
    expect(File(repository.submittedPath!).existsSync(), isFalse);
  });

  test('a refused microphone is a state, not a crash', () async {
    final recorder = FakeRecorder(permitted: false);
    final repository = FakeRepository(() => Ok(_result()));
    final c = containerWith(recorder, repository);

    await c.read(attemptControllerProvider.notifier).toggle('think');

    final state = c.read(attemptControllerProvider);
    expect(state.status, AttemptStatus.failed);
    expect(state.problem, RecordingProblem.permissionDenied);
  });

  test('a clip too short to score never reaches the server', () async {
    final recorder = FakeRecorder(stopThrows: RecordingProblem.tooShort);
    final repository = FakeRepository(() => Ok(_result()));
    final c = containerWith(recorder, repository);
    final controller = c.read(attemptControllerProvider.notifier);

    await controller.toggle('think');
    await controller.toggle('think');

    expect(
      c.read(attemptControllerProvider).problem,
      RecordingProblem.tooShort,
    );
    expect(repository.submittedPath, isNull);
    recorder.file!.deleteSync();
  });

  test('reset cancels a recording in progress', () async {
    final recorder = FakeRecorder();
    final repository = FakeRepository(() => Ok(_result()));
    final c = containerWith(recorder, repository);
    final controller = c.read(attemptControllerProvider.notifier);

    await controller.toggle('think');
    await controller.reset();

    expect(recorder.cancelled, isTrue);
    expect(c.read(attemptControllerProvider).status, AttemptStatus.idle);
  });
}
