// Test harness.
//
// Wraps a widget in the real theme and a ProviderScope, so a widget test exercises the
// tokens the app actually ships with rather than Material defaults.
//
// [surfaceSize] sets an explicit MediaQuery rather than resizing the test surface. It is
// deterministic and states plainly what the test is varying: the space available to the
// widget.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voca/core/theme/app_theme.dart';

extension PumpApp on WidgetTester {
  Future<void> pumpWithTheme(
    Widget widget, {
    Brightness brightness = Brightness.light,
    Size? surfaceSize,
    List<Override> overrides = const [],
  }) async {
    Widget app = MaterialApp(
      theme: brightness == Brightness.light ? VocaTheme.light() : VocaTheme.dark(),
      home: Scaffold(body: widget),
    );

    if (surfaceSize != null) {
      // Both halves matter. MediaQuery is what the responsive helpers read; the SizedBox
      // is what actually constrains layout. Setting only the first would let a widget
      // report "compact" while still laying out against the full test surface.
      app = MediaQuery(
        data: MediaQueryData(size: surfaceSize),
        child: Center(
          child: SizedBox(
            width: surfaceSize.width,
            height: surfaceSize.height,
            child: app,
          ),
        ),
      );
    }

    await pumpWidget(ProviderScope(overrides: overrides, child: app));
  }
}
