// test/widget/features/import/import_progress_responsive_test.dart
// Task 16 — verifies ImportProgressScreen renders the right layout per form factor.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:redclass/core/platform/platform_info.dart';
import 'package:redclass/core/platform/responsive.dart';
import 'package:redclass/features/import/presentation/import_progress_screen.dart';
import 'package:redclass/features/import/providers/import_notifier.dart';
import 'package:redclass/features/import/providers/import_state.dart';

ImportState _seedState({ImportPhase phase = ImportPhase.extracting}) {
  return ImportState(phase: phase, progress: 0.5);
}

Widget _harness({
  required Size size,
  required AppPlatform platform,
  required ImportPhase phase,
}) {
  // ImportProgressScreen reads file path from GoRouterState.of(context).extra.
  // For tests we wrap it inside a GoRouter so the screen can resolve its extra.
  final router = GoRouter(
    initialLocation: '/import/progress',
    routes: [
      GoRoute(
        path: '/import/progress',
        builder: (context, state) => const ImportProgressScreen(),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      importNotifierProvider.overrideWithValue(_seedState(phase: phase)),
    ],
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
        _harness(
          size: const Size(400, 800),
          platform: AppPlatform.android,
          phase: ImportPhase.extracting,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('import_progress_vertical_layout')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('import_progress_horizontal_layout')),
        findsNothing,
      );

      expect(
        _hasDescendantConstrainedBoxMaxWidth(
          tester,
          find.byKey(const Key('import_progress_vertical_layout')),
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
        _harness(
          size: const Size(700, 900),
          platform: AppPlatform.android,
          phase: ImportPhase.parsing,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('import_progress_vertical_layout')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('import_progress_horizontal_layout')),
        findsNothing,
      );

      expect(
        _hasDescendantConstrainedBoxMaxWidth(
          tester,
          find.byKey(const Key('import_progress_vertical_layout')),
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
        _harness(
          size: const Size(1500, 1000),
          platform: AppPlatform.windows,
          phase: ImportPhase.llmParsing,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('import_progress_horizontal_layout')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('import_progress_vertical_layout')),
        findsNothing,
      );

      expect(
        _hasDescendantConstrainedBoxMaxWidth(
          tester,
          find.byKey(const Key('import_progress_horizontal_layout')),
          960,
        ),
        isTrue,
      );
    },
  );
}
