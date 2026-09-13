/// Recording, to a strict specification.
///
///   16-bit PCM WAV, mono, 16 kHz, max 15s (configurable), min about 0.4s, max 2 MB.
///
/// Why fixed: it is what speech assessment engines want, it avoids server-side transcoding
/// and lossy artefacts that unfairly depress scores, and it bounds cost and abuse. The
/// backend validates the same numbers again — a rule that only exists in the app is not a
/// rule — so a mismatch here is caught rather than silently scored.
///
/// Writes to a TEMPORARY file and the caller deletes it immediately after upload succeeds
/// or fails. The app keeps no recording archive: MVP retains no user audio anywhere
/// (ARCHITECTURE.md 12.1, 12.3).
///
/// Also owns microphone permission, with a denial the caller can show rather than a crash.
library;

import 'dart:async';
import 'dart:io';

import 'package:record/record.dart';

/// What a finished recording is: a file on disk and how long it runs.
class RecordedClip {
  const RecordedClip({required this.path, required this.durationMs});

  final String path;
  final int durationMs;

  int get sizeBytes {
    final f = File(path);
    return f.existsSync() ? f.lengthSync() : 0;
  }

  /// Removes the file. Safe to call twice, and safe to call on a file that was never
  /// written: a failed upload must not leave audio on the device either.
  Future<void> delete() async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {
      // A temp file we cannot remove is the operating system's to clean up. Failing the
      // attempt over it would be worse than leaving it.
    }
  }
}

/// Why a recording could not start or finish.
enum RecordingProblem { permissionDenied, tooShort, failed }

class RecordingException implements Exception {
  const RecordingException(this.problem);
  final RecordingProblem problem;
}

/// What the app needs from a recorder, so a test can supply one that never touches a
/// microphone.
abstract interface class Recorder {
  Future<bool> hasPermission();
  Future<void> start({void Function()? onLimit});
  Future<RecordedClip> stop();
  Future<void> cancel();
  Future<void> dispose();
}

/// The one recorder in the app.
///
/// Named VoiceRecorder rather than AudioRecorder because the package already owns that
/// name, and two AudioRecorders in one file is how the wrong one gets constructed.
class VoiceRecorder implements Recorder {
  VoiceRecorder({AudioRecorder? recorder})
    : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;

  /// The format the assessment engine expects. The package defaults to AAC at 44.1 kHz in
  /// stereo, so every one of these three has to be stated.
  static const _config = RecordConfig(
    encoder: AudioEncoder.wav,
    sampleRate: 16000,
    numChannels: 1,
  );

  static const minDuration = Duration(milliseconds: 400);
  static const maxDuration = Duration(seconds: 15);

  DateTime? _startedAt;
  String? _path;
  Timer? _limit;

  bool get isRecording => _startedAt != null;

  /// Whether the microphone may be used, asking the person if they have not been asked.
  @override
  Future<bool> hasPermission() => _recorder.hasPermission();

  /// Starts recording into a temporary file.
  ///
  /// [onLimit] fires if the recording runs to [maxDuration], so the screen can stop it and
  /// say why rather than letting the file grow past what the server accepts.
  @override
  Future<void> start({void Function()? onLimit}) async {
    if (isRecording) return;

    if (!await _recorder.hasPermission()) {
      throw const RecordingException(RecordingProblem.permissionDenied);
    }

    final dir = Directory.systemTemp;
    final path =
        '${dir.path}/voca_${DateTime.now().microsecondsSinceEpoch}.wav';

    try {
      await _recorder.start(_config, path: path);
    } catch (_) {
      throw const RecordingException(RecordingProblem.failed);
    }

    _path = path;
    _startedAt = DateTime.now();
    _limit = Timer(maxDuration, () => onLimit?.call());
  }

  /// Stops and returns the clip, or throws when it is too short to assess.
  ///
  /// Too short is checked here as well as on the server because the round trip is the
  /// expensive part: an accidental tap should not become a request.
  @override
  Future<RecordedClip> stop() async {
    final startedAt = _startedAt;
    _limit?.cancel();
    _limit = null;
    _startedAt = null;

    String? path;
    try {
      path = await _recorder.stop();
    } catch (_) {
      throw const RecordingException(RecordingProblem.failed);
    }

    path ??= _path;
    _path = null;

    if (path == null || startedAt == null) {
      throw const RecordingException(RecordingProblem.failed);
    }

    final elapsed = DateTime.now().difference(startedAt);
    final clip = RecordedClip(path: path, durationMs: elapsed.inMilliseconds);

    if (elapsed < minDuration) {
      await clip.delete();
      throw const RecordingException(RecordingProblem.tooShort);
    }
    return clip;
  }

  /// Abandons a recording in progress and removes what was written.
  @override
  Future<void> cancel() async {
    _limit?.cancel();
    _limit = null;
    _startedAt = null;
    final path = _path;
    _path = null;
    try {
      await _recorder.cancel();
    } catch (_) {
      // Nothing to cancel is not a failure worth surfacing.
    }
    if (path != null) await RecordedClip(path: path, durationMs: 0).delete();
  }

  @override
  Future<void> dispose() async {
    _limit?.cancel();
    await _recorder.dispose();
  }
}
