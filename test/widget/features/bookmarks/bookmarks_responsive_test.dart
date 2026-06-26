// test/widget/features/bookmarks/bookmarks_responsive_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:redclass/core/platform/platform_info.dart';
import 'package:redclass/core/platform/responsive.dart';
import 'package:redclass/features/bookmarks/presentation/bookmarks_screen.dart';

Widget _harness({required Size size, required AppPlatform platform}) {
  return MaterialApp(
    home: ResponsiveBuilder(
      info: PlatformInfo.forTesting(
        platform: platform,
        shortestSide: size.shortestSide,
      ),
      builder: (context, _) => MediaQuery(
        data: MediaQueryData(size: size),
        child: const BookmarksScreen(),
      ),
    ),
  );
}

bool _hasDescendantConstrainedBoxMaxWidth(
  WidgetTester tester,
  Finder startFinder,
  double targetMaxWidth,
) {
  final constrained = find.descendant(
    of: startFinder,
    matching: find.byType(ConstrainedBox),
  );
  if (constrained.evaluate().isEmpty) return false;
  for (final element in constrained.evaluate()) {
    final widget = element.widget as ConstrainedBox;
    if (widget.constraints.maxWidth == targetMaxWidth) return true;
  }
  return false;
}

void main() {
  testWidgets(
    'compact width (400x800) renders vertical layout key (no maxWidth ConstrainedBox)',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _harness(size: const Size(400, 800), platform: AppPlatform.android),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('bookmarks_vertical_layout')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('bookmarks_horizontal_layout')),
        findsNothing,
      );

      expect(
        find.descendant(
          of: find.byKey(const Key('bookmarks_vertical_layout')),
          matching: find.byType(ConstrainedBox),
        ),
        findsNothing,
      );
    },
  );

  testWidgets(
    'medium width (700x900) renders vertical layout key with 720-capped ConstrainedBox',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(700, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _harness(size: const Size(700, 900), platform: AppPlatform.android),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('bookmarks_vertical_layout')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('bookmarks_horizontal_layout')),
        findsNothing,
      );

      expect(
        _hasDescendantConstrainedBoxMaxWidth(
          tester,
          find.byKey(const Key('bookmarks_vertical_layout')),
          720,
        ),
        isTrue,
      );
    },
  );

  testWidgets(
    'expanded width (1500x1000) renders horizontal layout key with 960-capped ConstrainedBox',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1500, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _harness(size: const Size(1500, 1000), platform: AppPlatform.windows),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('bookmarks_horizontal_layout')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('bookmarks_vertical_layout')), findsNothing);

      expect(
        _hasDescendantConstrainedBoxMaxWidth(
          tester,
          find.byKey(const Key('bookmarks_horizontal_layout')),
          960,
        ),
        isTrue,
      );
    },
  );
}
