// Responsive layout.
//
// Voca must read well from a small iPhone SE to a large Android phone. The rule under
// test: layout branches on available space, never on a device name or a fixed width.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voca/core/utils/responsive.dart';

import '../../helpers/pump_app.dart';

void main() {
  Future<ScreenSize> sizeAt(WidgetTester tester, Size surface) async {
    late ScreenSize result;
    await tester.pumpWithTheme(
      Builder(
        builder: (context) {
          result = context.screenSize;
          return const SizedBox.shrink();
        },
      ),
      surfaceSize: surface,
    );
    return result;
  }

  testWidgets('classifies widths into compact, medium and expanded', (tester) async {
    expect(await sizeAt(tester, const Size(320, 640)), ScreenSize.compact);
    expect(await sizeAt(tester, const Size(390, 844)), ScreenSize.medium);
    expect(await sizeAt(tester, const Size(834, 1112)), ScreenSize.expanded);
  });

  testWidgets('page inset grows with available width', (tester) async {
    late double narrow;
    late double wide;

    await tester.pumpWithTheme(
      Builder(builder: (c) {
        narrow = c.pageInset;
        return const SizedBox.shrink();
      }),
      surfaceSize: const Size(320, 640),
    );
    await tester.pumpWithTheme(
      Builder(builder: (c) {
        wide = c.pageInset;
        return const SizedBox.shrink();
      }),
      surfaceSize: const Size(834, 1112),
    );

    expect(wide, greaterThan(narrow));
  });

  // On a tablet a line of text must not stretch to an unreadable length.
  testWidgets('PageContainer caps content width on a wide screen', (tester) async {
    await tester.pumpWithTheme(
      const PageContainer(child: SizedBox(height: 10)),
      surfaceSize: const Size(1200, 800),
    );

    final box = tester.getSize(
      find.descendant(
        of: find.byType(PageContainer),
        matching: find.byType(ConstrainedBox),
      ).first,
    );
    expect(box.width, lessThanOrEqualTo(560));
  });

  // On a phone the container must not shrink content into a narrow column: it should
  // occupy the full width minus the page inset.
  testWidgets('content spans the phone width minus the inset', (tester) async {
    const width = 360.0;
    late double inset;

    const contentKey = Key('page-content');

    await tester.pumpWithTheme(
      Builder(
        builder: (context) {
          inset = context.pageInset;
          return const PageContainer(
            child: SizedBox(key: contentKey, height: 10, width: double.infinity),
          );
        },
      ),
      surfaceSize: const Size(width, 720),
    );

    // The content occupies the full width minus the inset on both sides: no arbitrary
    // maximum kicks in on a phone.
    final content = tester.getSize(find.byKey(contentKey));
    expect(content.width, width - inset * 2);
  });
}
