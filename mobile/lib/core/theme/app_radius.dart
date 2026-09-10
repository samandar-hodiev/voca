/// Corner radius tokens.
///
/// The visual direction is moderately rounded. Fully rounded surfaces read as playful and
/// pull the product toward the colourful language-learning look Voca is deliberately not.
/// [pill] exists for genuinely pill-shaped controls such as chips and small badges, not
/// for cards.
library;

import 'package:flutter/widgets.dart';

abstract final class VocaRadius {
  /// 8 — inputs, small chips.
  static const double small = 8;

  /// 12 — buttons, list rows.
  static const double medium = 12;

  /// 20 — cards and glass surfaces.
  static const double large = 20;

  /// 28 — sheets and large focal surfaces.
  static const double xlarge = 28;

  /// 999 — genuinely pill-shaped controls only.
  static const double pill = 999;

  static const BorderRadius smallAll = BorderRadius.all(Radius.circular(small));
  static const BorderRadius mediumAll = BorderRadius.all(Radius.circular(medium));
  static const BorderRadius largeAll = BorderRadius.all(Radius.circular(large));
  static const BorderRadius xlargeAll = BorderRadius.all(Radius.circular(xlarge));
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));
}
