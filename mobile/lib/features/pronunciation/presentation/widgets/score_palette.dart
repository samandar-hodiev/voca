/// Which colour a score wears, decided once.
///
/// The ring, the chips and the word rows all band the same numbers, and a learner
/// comparing them would notice immediately if 62 were amber in one place and green in
/// another. Colour is never the only signal: every caller pairs it with the number itself.
library;

import 'package:flutter/widgets.dart';

import '../../../../core/theme/app_colors.dart';

enum ScoreBand { good, fair, poor }

/// The thresholds the backend's analyzer already uses: below 60 is a problem worth
/// reporting, 80 and up is good. Keeping the same numbers means the ring never looks
/// content about a word the feedback list is complaining about.
ScoreBand bandFor(double score) => switch (score) {
  >= 80 => ScoreBand.good,
  >= 60 => ScoreBand.fair,
  _ => ScoreBand.poor,
};

/// The foreground: the arc, an icon, the number.
Color bandColor(VocaColors colors, ScoreBand band) => switch (band) {
  ScoreBand.good => colors.success,
  ScoreBand.fair => colors.warning,
  ScoreBand.poor => colors.error,
};

/// The quiet fill behind it.
Color bandFill(VocaColors colors, ScoreBand band) => switch (band) {
  ScoreBand.good => colors.successMuted,
  ScoreBand.fair => colors.warningMuted,
  ScoreBand.poor => colors.errorMuted,
};

/// Text placed on that fill; the status colour itself does not always clear 4.5:1 on it.
Color bandOnFill(VocaColors colors, ScoreBand band) => switch (band) {
  ScoreBand.good => colors.onSuccessMuted,
  ScoreBand.fair => colors.onWarningMuted,
  ScoreBand.poor => colors.onErrorMuted,
};
