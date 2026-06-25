// test/widget/features/stats/stats_responsive_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:redclass/core/platform/platform_info.dart';
import 'package:redclass/core/platform/responsive.dart';
import 'package:redclass/data/db/database.dart';
import 'package:redclass/features/stats/providers/stats_provider.dart';
import 'package:redclass/features/stats/presentation/stats_screen.dart';

List<BankStats> _mockStats() {
  final bank1 = QuestionBank(
    id: 'bank-1',
    name: '测试题库 A',
    source: '/tmp/a.docx',
    questionCount: 10,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
  final bank2 = QuestionBank(
    id: 'bank-2',
    name: '测试题库 B',
    source: '/tmp/b.docx',
    questionCount: 20,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
  return [
    BankStats(
      bank: bank1,
      totalQuestions: 10,
      totalAttempts: 50,
      correctCount: 35,
      activeLedgerCount: 5,
      modes: const [
        ModeBreakdown(mode: 'random', attempts: 30, correctCount: 20),
        ModeBreakdown(mode: 'review', attempts: 15, correctCount: 12),
      ],
    ),
    BankStats(
      bank: bank2,
      totalQuestions: 20,
      totalAttempts: 100,
      correctCount: 80,
      activeLedgerCount: 0,
      modes: const [
        ModeBreakdown(mode: 'random', attempts: 100, correctCount: 80),
      ],
    ),
  ];
}

Widget _harness({
  required Size size,
  required AppPlatform platform,
  required List<BankStats> stats,
}) {
  return ProviderScope(
    overrides: [bankStatsListProvider.overrideWith((ref) async => stats)],
    child: MaterialApp(
      home: ResponsiveBuilder(
        info: PlatformInfo.forTesting(
          platform: platform,
          shortestSide: size.shortestSide,
        ),
        builder: (context, _) => MediaQuery(
          data: MediaQueryData(size: size),
          child: const StatsScreen(),
        ),
      ),
    ),
  );
}

/// True iff any [ConstrainedBox] descendant of [startFinder] has
/// `maxWidth` equal to [maxWidth]. Distinguishes the medium branch
/// (Center > ConstrainedBox(maxWidth: 720) > ListView) from the compact
/// branch (bare ListView with no width cap). Other `ConstrainedBox`
/// widgets (e.g. from icon `Container` sizes) are ignored.
bool _hasDescendantConstrainedBoxMaxWidth(Finder startFinder, double maxWidth) {
  final matches = find
      .descendant(
        of: startFinder,
        matching: find.byWidgetPredicate(
          (w) => w is ConstrainedBox && w.constraints.maxWidth == maxWidth,
        ),
      )
      .evaluate();
  return matches.isNotEmpty;
}

void main() {
  testWidgets(
    'compact width (400x800) renders vertical layout key (no maxWidth ConstrainedBox)',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _harness(
          size: const Size(400, 800),
          platform: AppPlatform.android,
          stats: _mockStats(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('stats_vertical_layout')), findsOneWidget);
      expect(find.byKey(const Key('stats_horizontal_layout')), findsNothing);

      // Compact: no 720-cap (icon Container ConstrainedBoxes ignored)
      expect(
        _hasDescendantConstrainedBoxMaxWidth(
          find.byKey(const Key('stats_vertical_layout')),
          720,
        ),
        isFalse,
      );
    },
  );

  testWidgets(
    'medium width (700x900) renders vertical layout key with 720-centered ConstrainedBox',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(700, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _harness(
          size: const Size(700, 900),
          platform: AppPlatform.android,
          stats: _mockStats(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('stats_vertical_layout')), findsOneWidget);
      expect(find.byKey(const Key('stats_horizontal_layout')), findsNothing);

      // Verify the 720-cap is active in medium
      expect(
        _hasDescendantConstrainedBoxMaxWidth(
          find.byKey(const Key('stats_vertical_layout')),
          720,
        ),
        isTrue,
      );
    },
  );

  testWidgets(
    'expanded width (1500x1000) renders horizontal layout key (grid for bank cards)',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1500, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _harness(
          size: const Size(1500, 1000),
          platform: AppPlatform.windows,
          stats: _mockStats(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('stats_horizontal_layout')), findsOneWidget);
      expect(find.byKey(const Key('stats_vertical_layout')), findsNothing);

      // Verify the bank cards are inside a Wrap (grid layout)
      expect(
        find.descendant(
          of: find.byKey(const Key('stats_horizontal_layout')),
          matching: find.byType(Wrap),
        ),
        findsOneWidget,
      );
    },
  );
}
