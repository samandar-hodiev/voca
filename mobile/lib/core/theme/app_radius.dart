/// Corner radius tokens.
///
/// The visual direction is moderately rounded. Fully rounded surfaces read as playful and
/// pull the product toward the colourful language-learning look Voca is deliberately not.
/// [pill] exists for genuinely pill-shaped controls such as chips and small badges, not
/// for cards.
library;

import 'package:flutter/widgets.dart';

abstract final class VocaRadius {
  /// One radius for every element: cards, buttons, fields, wells and chips all share it.
  /// The older names stay so no call site has to change. An element shorter than twice
  /// this comes out as a capsule, because a corner larger than half a side is scaled to
  /// fit. Only the tab bar and its pill are capsules by design.
  static const double element = 20;

  /// 8 — inputs, small chips.
  static const double small = element;

  /// 12 — buttons, list rows.
  static const double medium = element;

  /// 20 — cards and glass surfaces.
  static const double large = element;

  /// 28 — sheets and large focal surfaces.
  static const double xlarge = element;

  /// 999 — genuinely pill-shaped controls only.
  static const double pill = 999;

  static const BorderRadius smallAll = BorderRadius.all(Radius.circular(small));
  static const BorderRadius mediumAll = BorderRadius.all(
    Radius.circular(medium),
  );
  static const BorderRadius largeAll = BorderRadius.all(Radius.circular(large));
  static const BorderRadius xlargeAll = BorderRadius.all(
    Radius.circular(xlarge),
  );
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));
}
