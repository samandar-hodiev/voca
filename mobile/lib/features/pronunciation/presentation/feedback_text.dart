/// Turns the server's feedback KEYS into sentences in the reader's language.
///
/// The backend deliberately sends keys, not prose: the same attempt has to read in
/// English, Uzbek or Russian without a server deployment, and a learner practising English
/// is not necessarily reading the app in English. This is the one place that mapping
/// lives, so an unknown key degrades to nothing shown rather than to a raw
/// "feedback.mispronunciation" on screen.
library;

import '../../../l10n/l10n.dart';

/// The advice sentence for a message key, or null if this build does not know the key —
/// a server that has learned a new diagnosis before the app has.
String? feedbackMessage(AppLocalizations l10n, String key, String word) =>
    switch (key) {
      'feedback.mispronunciation' => l10n.feedbackMispronunciation(word),
      'feedback.omission' => l10n.feedbackOmission(word),
      'feedback.insertion' => l10n.feedbackInsertion(word),
      'feedback.unexpected_break' => l10n.feedbackUnexpectedBreak(word),
      'feedback.missing_break' => l10n.feedbackMissingBreak(word),
      'feedback.monotone' => l10n.feedbackMonotone(word),
      _ => null,
    };

/// How the sound is physically made, for a tip key. Null when the key is unknown, or when
/// the advice was about the utterance rather than one sound.
String? feedbackTip(AppLocalizations l10n, String? key) => switch (key) {
  'tip.tongue_between_teeth' => l10n.tipTongueBetweenTeeth,
  'tip.tongue_between_teeth_voiced' => l10n.tipTongueBetweenTeethVoiced,
  'tip.round_lips' => l10n.tipRoundLips,
  'tip.teeth_on_lip' => l10n.tipTeethOnLip,
  'tip.curl_tongue_back' => l10n.tipCurlTongueBack,
  'tip.tongue_tip_to_ridge' => l10n.tipTongueTipToRidge,
  'tip.back_of_tongue' => l10n.tipBackOfTongue,
  'tip.open_jaw_wide' => l10n.tipOpenJawWide,
  'tip.short_relaxed_vowel' => l10n.tipShortRelaxedVowel,
  'tip.long_tense_vowel' => l10n.tipLongTenseVowel,
  _ => null,
};
