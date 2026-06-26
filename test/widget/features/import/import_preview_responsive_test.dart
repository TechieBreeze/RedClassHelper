// test/widget/features/import/import_preview_responsive_test.dart
// Task 15 — verifies ImportPreviewScreen renders the right layout per form factor.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:redclass/core/platform/platform_info.dart';
import 'package:redclass/core/platform/responsive.dart';
import 'package:redclass/features/import/parsing/llm/canonicalizer.dart';
import 'package:redclass/features/import/parsing/parse_candidate.dart';
import 'package:redclass/features/import/presentation/import_preview_screen.dart';
import 'package:redclass/features/import/providers/import_notifier.dart';
import 'package:redclass/features/import/providers/import_state.dart';

ParseCandidate _stubCandidate(int i) => ParseCandidate(
      rawText: '题 $i 正文',
      candidateType: CandidateType.singleChoice,
      options: const ['A', 'B', 'C', 'D'],
      answer: 'A',
      startLine: i,
      endLine: i,
    );

ImportState _seedState() {
  final candidates = List.generate(6, _stubCandidate);
  return ImportState(
    jobId: 'job-1',
    bankName: '测试题库',
    candidates: candidates,
    confirmedIndices: const {0, 1, 2},
    parseSources: const {
      0: ParseSource.llm,
      1: ParseSource.heuristic,
      2: ParseSource.fallback,
    },
    phase: ImportPhase.editing,
  );
}

Widget _harness({required Size size, required AppPlatform platform}) {
  return ProviderScope(
    overrides: [
      importNotifierProvider.overrideWithValue(_seedState()),
    ],
    child: MaterialApp(
      home: ResponsiveBuilder(
        info: PlatformInfo.forTesting(
          platform: platform,
          shortestSide: size.shortestSide,
        ),
        builder: (context, _) => MediaQuery(
          data: MediaQueryData(size: size),
          child: const ImportPreviewScreen(),
        ),
      ),
    ),
  );
}

bool _hasDescendantConstrainedBoxMaxWidth(
    WidgetTester tester, Finder startFinder, double targetMaxWidth) {
  final matches = find
      .descendant(
        of: startFinder,
        matching: find.byWidgetPredicate(
          (w) => w is ConstrainedBox && w.constraints.maxWidth == targetMaxWidth,
        ),
      )
      .evaluate();
  return matches.isNotEmpty;
}

void main() {
  testWidgets(
    'compact width (400x800) renders vertical layout key (no 720 ConstrainedBox)',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_harness(
        size: const Size(400, 800),
        platform: AppPlatform.android,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('import_preview_vertical_layout')),
          findsOneWidget);
      expect(find.byKey(const Key('import_preview_horizontal_layout')),
          findsNothing);

      expect(
        _hasDescendantConstrainedBoxMaxWidth(
            tester, find.byKey(const Key('import_preview_vertical_layout')), 720),
        isFalse,
      );
    },
  );

  testWidgets(
    'medium width (700x900) renders vertical layout key with 720 ConstrainedBox',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(700, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_harness(
        size: const Size(700, 900),
        platform: AppPlatform.android,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('import_preview_vertical_layout')),
          findsOneWidget);
      expect(find.byKey(const Key('import_preview_horizontal_layout')),
          findsNothing);

      expect(
        _hasDescendantConstrainedBoxMaxWidth(
            tester, find.byKey(const Key('import_preview_vertical_layout')), 720),
        isTrue,
      );
    },
  );

  testWidgets(
    'expanded width (1500x1000) renders horizontal layout key with 960 ConstrainedBox + Wrap',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1500, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_harness(
        size: const Size(1500, 1000),
        platform: AppPlatform.windows,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('import_preview_horizontal_layout')),
          findsOneWidget);
      expect(find.byKey(const Key('import_preview_vertical_layout')),
          findsNothing);

      expect(
        _hasDescendantConstrainedBoxMaxWidth(
            tester, find.byKey(const Key('import_preview_horizontal_layout')), 960),
        isTrue,
      );

      expect(
        find.descendant(
          of: find.byKey(const Key('import_preview_horizontal_layout')),
          matching: find.byType(Wrap),
        ),
        findsOneWidget,
      );
    },
  );
}
