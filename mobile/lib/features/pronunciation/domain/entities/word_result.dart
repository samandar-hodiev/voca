/// One word inside an attempt, and how each of its sounds went.
library;

class PhonemeResult {
  const PhonemeResult({required this.phoneme, required this.accuracy});

  final String phoneme;
  final double accuracy;
}

class WordResult {
  const WordResult({
    required this.word,
    required this.accuracy,
    required this.error,
    required this.phonemes,
  });

  final String word;
  final double accuracy;

  /// The server's own diagnosis: none, mispronunciation, omission, insertion,
  /// unexpected_break, missing_break or monotone.
  final String error;

  final List<PhonemeResult> phonemes;

  bool get isProblem => error.isNotEmpty && error != 'none';
}
