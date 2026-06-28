// test/widget/features/import/import_save_error_test.dart
// Regression: when commitToDatabase fails (DB exception, etc.), the preview
// screen used to silently swallow the error — user saw "点保存没反应" with
// no SnackBar or visible feedback. The fix must surface state.error as a
// SnackBar so the user knows what went wrong.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:redclass/core/theme.dart';
import 'package:redclass/features/import/parsing/llm/canonicalizer.dart';
import 'package:redclass/features/import/parsing/parse_candidate.dart';
import 'package:redclass/features/import/presentation/import_preview_screen.dart';
import 'package:redclass/features/import/providers/import_notifier.dart';
import 'package:redclass/features/import/providers/import_state.dart';
import 'package:redclass/routing/router.dart';

ParseCandidate _stubCandidate(int i) => ParseCandidate(
  rawText: '题 $i 正文',
  candidateType: CandidateType.singleChoice,
  options: const ['A', 'B', 'C', 'D'],
  answer: 'A',
  startLine: i,
  endLine: i,
);

ImportState _seedEditingState() {
  final candidates = List.generate(3, _stubCandidate);
  return ImportState(
    jobId: 'job-error-1',
    bankName: '失败测试题库',
    files: [
      ImportFile.fromPath(
        path: 'C:/tmp/fake.docx',
        name: 'fake.docx',
        sizeBytes: 1024,
      ),
    ],
    candidates: candidates,
    confirmedIndices: const {0, 1, 2},
    phase: ImportPhase.editing,
  );
}

/// A `commitToDatabase` replacement that mirrors the real
/// `ImportNotifier.commitToDatabase` failure path exactly: enter
/// committing, attempt work, throw on the inner Exception, and reset
/// phase + set error the same way the production code does. The whole
/// point of this test is to verify the **screen** surfaces the error,
/// not the notifier itself.
class _ThrowingImportNotifier extends ImportNotifier {
  @override
  Future<void> commitToDatabase() async {
    state = state.copyWith(phase: ImportPhase.committing, progress: 0.0);
    try {
      // Simulate a real DB-level failure: drift throws SqliteException
      // (which extends Exception) — the same kind that the real
      // commitToDatabase's `on Exception catch` swallows.
      throw Exception('disk full: simulated DB write failure');
    } on Exception catch (e) {
      state = state.copyWith(
        phase: ImportPhase.editing,
        error: '保存失败: ${e.toString()}',
      );
    }
  }
}

void main() {
  testWidgets(
    'commitToDatabase throws Exception → preview screen surfaces state.error as SnackBar',
    (tester) async {
      appRouter.go('/banks');
      await tester.pumpAndSettle();

      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final container = ProviderContainer(
        overrides: [
          importNotifierProvider.overrideWith(_ThrowingImportNotifier.new),
        ],
      );
      addTearDown(container.dispose);

      // Seed the notifier state directly so the preview screen sees editing
      // phase with confirmed candidates.
      container.read(importNotifierProvider.notifier).state =
          _seedEditingState();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: buildAppTheme(Brightness.light, null),
            routerConfig: appRouter,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to the preview screen.
      appRouter.push('/import/preview/job-error-1');
      await tester.pumpAndSettle();

      expect(find.byType(ImportPreviewScreen), findsOneWidget);

      // Tap 保存. Our overridden commitToDatabase will throw.
      await tester.tap(find.widgetWithText(FilledButton, '保存'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // After failure, the screen must NOT auto-navigate to summary.
      expect(find.byType(ImportPreviewScreen), findsOneWidget,
          reason:
              'Failed commit must keep user on the preview screen so they '
              'can see the error and retry.');

      // After failure, the user MUST see the error message — this is the
      // regression: nothing showed up because state.error was set but
      // nobody read it.
      expect(
        find.textContaining('保存失败'),
        findsOneWidget,
        reason:
            'Failed commit must surface state.error as a visible message '
            '(SnackBar or in-screen widget). User previously reported '
            '"点保存没反应" because the error was silently swallowed.',
      );

      expect(tester.takeException(), isNull);
    },
  );
}