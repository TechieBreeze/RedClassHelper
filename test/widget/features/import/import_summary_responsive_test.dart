// test/widget/features/import/import_summary_responsive_test.dart
// Task 17 — verifies ImportSummaryScreen renders the right layout per form factor.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:redclass/core/platform/platform_info.dart';
import 'package:redclass/core/platform/responsive.dart';
import 'package:redclass/features/import/parsing/llm/canonicalizer.dart';
import 'package:redclass/features/import/parsing/parse_candidate.dart';
import 'package:redclass/features/import/presentation/import_summary_screen.dart';
import 'package:redclass/features/import/providers/import_notifier.dart';
import 'package:redclass/features/import/providers/import_state.dart';

ImportState _seedState() {
  final candidates = List.generate(
    3,
    (i) => ParseCandidate(
      rawText: '题 ${i + 1} 正文',
      candidateType: CandidateType.singleChoice,
      options: const ['A', 'B', 'C', 'D'],
      answer: 'A',
      startLine: i,
      endLine: i,
    ),
  );
  return ImportState(
    jobId: 'job-summary-1',
    bankId: 'bank-1',
    bankName: '测试题库',
    files: [
      ImportFile.fromPath(
        path: '/tmp/test.txt',
        name: 'test.txt',
        sizeBytes: 1024,
      ),
    ],
    candidates: candidates,
    confirmedIndices: const {0, 1, 2},
    committedCount: 12,
    parseSources: const {0: ParseSource.llm, 1: ParseSource.fallback},
    phase: ImportPhase.done,
  );
}

Widget _harness({required Size size, required AppPlatform platform}) {
  final router = GoRouter(
    initialLocation: '/import/summary/job-summary-1',
    routes: [
      GoRoute(
        path: '/import/summary/:jobId',
        builder: (context, state) => const ImportSummaryScreen(),
      ),
    ],
  );

  return ProviderScope(
    overrides: [importNotifierProvider.overrideWithValue(_seedState())],
    child: ResponsiveBuilder(
      info: PlatformInfo.forTesting(
        platform: platform,
        shortestSide: size.shortestSide,
      ),
      builder: (context, _) => MediaQuery(
        data: MediaQueryData(size: size),
        child: MaterialApp.router(routerConfig: router),
      ),
    ),
  );
}

bool _hasDescendantConstrainedBoxMaxWidth(
  WidgetTester tester,
  Finder startFinder,
  double targetMaxWidth,
) {
  final matches = find
      .descendant(
        of: startFinder,
        matching: find.byWidgetPredicate(
          (w) =>
              w is ConstrainedBox && w.constraints.maxWidth == targetMaxWidth,
        ),
      )
      .evaluate();
  return matches.isNotEmpty;
}

void main() {
  testWidgets(
    'compact width (400x800) renders vertical layout key (no 600 ConstrainedBox)',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _harness(size: const Size(400, 800), platform: AppPlatform.android),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('import_summary_vertical_layout')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('import_summary_horizontal_layout')),
        findsNothing,
      );

      expect(
        _hasDescendantConstrainedBoxMaxWidth(
          tester,
          find.byKey(const Key('import_summary_vertical_layout')),
          600,
        ),
        isFalse,
      );
    },
  );

  testWidgets(
    'medium width (700x900) renders vertical layout key with 600 ConstrainedBox',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(700, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _harness(size: const Size(700, 900), platform: AppPlatform.android),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('import_summary_vertical_layout')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('import_summary_horizontal_layout')),
        findsNothing,
      );

      expect(
        _hasDescendantConstrainedBoxMaxWidth(
          tester,
          find.byKey(const Key('import_summary_vertical_layout')),
          600,
        ),
        isTrue,
      );
    },
  );

  testWidgets(
    'expanded width (1500x1000) renders horizontal layout key with 960 ConstrainedBox',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1500, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _harness(size: const Size(1500, 1000), platform: AppPlatform.windows),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('import_summary_horizontal_layout')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('import_summary_vertical_layout')),
        findsNothing,
      );

      expect(
        _hasDescendantConstrainedBoxMaxWidth(
          tester,
          find.byKey(const Key('import_summary_horizontal_layout')),
          960,
        ),
        isTrue,
      );
    },
  );
}
