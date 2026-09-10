/// Responsive layout foundation.
///
/// Voca must read well from a small iPhone SE to a large Android phone and on to a
/// tablet. The rule this file encodes: NEVER branch on a device name, and never hardcode
/// a width. Branch on the space actually available.
///
/// Content is held to a maximum width so that on a wide screen a line of text does not
/// stretch to an unreadable length.
library;

import 'package:flutter/widgets.dart';

import '../theme/app_spacing.dart';

/// Width classes, named by available space rather than by device.
enum ScreenSize { compact, medium, expanded }

extension ResponsiveX on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;

  ScreenSize get screenSize {
    final w = screenWidth;
    if (w < 360) return ScreenSize.compact;
    if (w < 600) return ScreenSize.medium;
    return ScreenSize.expanded;
  }

  /// Horizontal page inset, tightened on the narrowest phones so content does not get
  /// squeezed into a thin column.
  double get pageInset => switch (screenSize) {
        ScreenSize.compact => VocaSpacing.md,
        ScreenSize.medium => VocaSpacing.lg,
        ScreenSize.expanded => VocaSpacing.xl,
      };

  /// Picks a value for the current width class.
  T responsive<T>({required T compact, T? medium, T? expanded}) =>
      switch (screenSize) {
        ScreenSize.compact => compact,
        ScreenSize.medium => medium ?? compact,
        ScreenSize.expanded => expanded ?? medium ?? compact,
      };
}

/// Constrains content to a comfortable reading width and applies the page inset.
///
/// Use this instead of a hardcoded [SizedBox] width. On a phone it fills the screen; on a
/// tablet it centres and stops growing.
class PageContainer extends StatelessWidget {
  const PageContainer({
    super.key,
    required this.child,
    this.maxWidth = 560,
    this.padding,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding ??
              EdgeInsets.symmetric(horizontal: context.pageInset),
          child: child,
        ),
      ),
    );
  }
}
