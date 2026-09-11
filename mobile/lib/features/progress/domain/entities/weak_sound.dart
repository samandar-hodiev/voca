/// A sound the learner is getting wrong, and how often.
library;

class WeakSound {
  const WeakSound({
    required this.symbol,
    required this.example,
    required this.accuracy,
  });

  /// IPA symbol.
  final String symbol;

  /// A word that contains it, so the symbol means something to somebody who cannot read
  /// IPA.
  final String example;

  /// Share of attempts scored as correct, out of 100.
  final int accuracy;
}
