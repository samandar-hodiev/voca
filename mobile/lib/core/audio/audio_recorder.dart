// core/audio: recording, to a strict specification.
//
//   16-bit PCM WAV, mono, 16 kHz, max 15s (configurable), min about 0.4s, max 2 MB.
//
// Why fixed: it is what speech assessment engines want, it avoids server-side transcoding
// and lossy artefacts that unfairly depress scores, and it bounds cost and abuse.
//
// Writes to a TEMPORARY file and deletes it immediately after upload succeeds or fails. The
// app keeps no recording archive — MVP retains no user audio anywhere (ARCHITECTURE.md 12.1,
// 12.3).
//
// Also owns microphone permission handling with a clear denial state.
