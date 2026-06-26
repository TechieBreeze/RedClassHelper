// integration_test/flows/mobile_import_flow_test.dart
// Task 19 — end-to-end mobile import flow on Android/iOS device or emulator.
//
// Runtime execution deferred: integration_test requires a connected device,
// Android emulator, or iOS simulator (not available in current Windows
// environment or CI). The test is authored + committed; developer runs
// `flutter test integration_test/` on a connected device to verify.
//
// Strategy: Option A from the brief — bypass the extraction/parsing pipeline
// by seeding `importNotifierProvider` directly with an `ImportState` that
// already contains `ImportPhase.editing` + a `ParseCandidate` list. This
// exercises the navigation + UI flow (preview → progress → summary) without
// invoking the real Pandoc / heuristic / LLM pipeline, which would require
// on-device file I/O and a live LLM endpoint.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';

import 'package:redclass/core/platform/platform_info.dart';
import 'package:redclass/core/platform/responsive.dart';
import 'package:redclass/data/file_picker/file_picker_models.dart';
import 'package:redclass/features/import/presentation/import_preview_screen.dart';
import 'package:redclass/features/import/presentation/import_progress_screen.dart';
import 'package:redclass/features/import/presentation/import_summary_screen.dart';
import 'package:redclass/features/import/providers/import_notifier.dart';
import 'package:redclass/features/import/providers/import_state.dart';
import 'package:redclass/features/import/parsing/parse_candidate.dart';

/// Build a minimal in-memory fixture ParseCandidate for a single-choice
/// question. Real questions come from the extraction pipeline; this is
/// enough to drive the UI through all three import screens.
ParseCandidate _fixtureCandidate() {
  return const ParseCandidate(
    title: '1. 中国的首都是哪里？',
    options: ['北京', '上海', '广州', '深圳'],
    answer: 'A',
    candidateType: CandidateType.singleChoice,
    rawText: '1. 中国的首都是哪里？\nA. 北京\nB. 上海\nC. 广州\nD. 深圳',
    confidence: 0.95,
  );
}

/// Build the seeded `ImportState` that the import flow expects when
/// entering the preview screen: `phase == editing` with at least one
/// candidate that is auto-confirmed.
ImportState _seededEditingState() {
  final candidate = _fixtureCandidate();
  return ImportState(
    jobId: 'integration-test-job',
    phase: ImportPhase.editing,
    files: [
      ImportFile.fromPicked(
        PickedBytesFile(name: 'sample.json', bytes: Uint8List(0)),
      ),
    ],
    bankName: '示例题库',
    candidates: [candidate],
    confirmedIndices: const {0},
  );
}

/// Render-only harness: bypasses the real `appRouter` (which depends on
/// `appDatabaseProvider` for the redirect-guard) and renders a single
/// import screen with a seeded `ImportState`. This is the same
/// `overrideWithValue` pattern Tasks 15-17 used for unit tests; we use
/// it here for the same reason — the real `commitToDatabase()` would
/// require a live `drift` connection that integration_test does not wire.
Widget _harnessFor({
  required String route,
  required ImportState state,
  required AppPlatform platform,
  required double shortestSide,
  required Widget child,
}) {
  final router = GoRouter(
    initialLocation: route,
    routes: [GoRoute(path: route, builder: (context, _) => child)],
  );

  return ProviderScope(
    overrides: [importNotifierProvider.overrideWithValue(state)],
    child: ResponsiveBuilder(
      info: PlatformInfo.forTesting(
        platform: platform,
        shortestSide: shortestSide,
      ),
      builder: (context, _) => MaterialApp.router(routerConfig: router),
    ),
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // We force `AppPlatform.android` for all three steps. The point of the
  // test is to exercise the compact mobile layout (shortestSide=400);
  // form-factor selection is the mobile-specific code path.

  testWidgets(
    'Mobile import: preview screen renders seeded candidates in compact layout',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _harnessFor(
          route: '/import/preview/integration-test-job',
          state: _seededEditingState(),
          platform: AppPlatform.android,
          shortestSide: 400,
          child: const ImportPreviewScreen(),
        ),
      );
      // No pumpAndSettle — preview has no infinite animations but be
      // defensive; two frames are enough for first paint.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      // Compact form factor → vertical layout key is present, horizontal is not.
      expect(
        find.byKey(const Key('import_preview_vertical_layout')),
        findsOneWidget,
        reason: 'Mobile (400-wide) must render preview vertical layout',
      );
      expect(
        find.byKey(const Key('import_preview_horizontal_layout')),
        findsNothing,
      );

      // Bank name from seeded state is rendered as the editable field.
      expect(find.text('示例题库'), findsWidgets);
    },
  );

  testWidgets(
    'Mobile import: progress screen renders committing phase compact layout',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final state = _seededEditingState().copyWith(
        phase: ImportPhase.committing,
        progress: 0.4,
      );

      await tester.pumpWidget(
        _harnessFor(
          route: '/import/progress',
          state: state,
          platform: AppPlatform.android,
          shortestSide: 400,
          child: const ImportProgressScreen(),
        ),
      );
      // CRITICAL: ImportProgressScreen has indeterminate progress animations
      // during LLM phases. `pumpAndSettle` would block forever. Use explicit
      // pump durations.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(
        find.byKey(const Key('import_progress_vertical_layout')),
        findsOneWidget,
        reason: 'Mobile (400-wide) must render progress vertical layout',
      );
      expect(
        find.byKey(const Key('import_progress_horizontal_layout')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'Mobile import: summary screen renders done state with committed count',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Task 17 redirect-guard: summary renders when
      // `state.isDone && state.committedCount > 0`.
      final state = _seededEditingState().copyWith(
        phase: ImportPhase.done,
        committedCount: 1,
        progress: 1.0,
        bankId: 'integration-test-bank',
      );

      await tester.pumpWidget(
        _harnessFor(
          route: '/import/summary/integration-test-job',
          state: state,
          platform: AppPlatform.android,
          shortestSide: 400,
          child: const ImportSummaryScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      expect(
        find.byKey(const Key('import_summary_vertical_layout')),
        findsOneWidget,
        reason: 'Mobile (400-wide) must render summary vertical layout',
      );
      expect(
        find.byKey(const Key('import_summary_horizontal_layout')),
        findsNothing,
      );

      // The summary AppBar title is "导入完成 ✓".
      expect(find.text('导入完成 ✓'), findsOneWidget);
    },
  );
}
