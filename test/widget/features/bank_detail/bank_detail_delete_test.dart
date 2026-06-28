// test/widget/features/bank_detail/bank_detail_delete_test.dart
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redclass/core/theme.dart';
import 'package:redclass/data/db/database.dart';
import 'package:redclass/data/repositories/bank_repository.dart';
import 'package:redclass/features/bank_detail/presentation/bank_detail_screen.dart';
import 'package:redclass/routing/router.dart';

Widget _wrap({required AppDatabase db, BankRepository? repo}) {
  // appRouter is a global singleton; reset before each wrap so tests are
  // independent. safePop() needs GoRouter in context.
  appRouter.go('/bank/b1');
  return ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWith((_) async => db),
      if (repo != null) bankRepositoryProvider.overrideWith((_) async => repo),
    ],
    child: MaterialApp.router(
      theme: buildAppTheme(Brightness.light, null),
      routerConfig: appRouter,
    ),
  );
}

Future<void> _seedBank(AppDatabase db) async {
  final now = DateTime.now();
  await db
      .into(db.questionBanks)
      .insertOnConflictUpdate(
        QuestionBanksCompanion.insert(
          id: 'b1',
          name: 'Test Bank',
          source: const Value('test'),
          questionCount: 2,
          createdAt: now,
          updatedAt: now,
        ),
      );
  for (final qid in ['q1', 'q2']) {
    await db
        .into(db.questions)
        .insert(
          QuestionsCompanion.insert(
            id: qid,
            bankId: 'b1',
            type: 'single',
            stem: 'Q?',
            optionsJson: '[{"key":"A","text":"a"}]',
            correctJson: '["A"]',
            rawText: 'Q?',
            createdAt: now,
          ),
        );
  }
}

class _FakeBankRepository implements BankRepository {
  final List<String> deletedIds = [];
  Future<void> Function(String)? onDelete;

  @override
  Future<void> deleteBank(String bankId) async {
    if (onDelete != null) await onDelete!(bankId);
    deletedIds.add(bankId);
  }
}

void main() {
  late AppDatabase db;
  late _FakeBankRepository fakeRepo;

  setUp(() async {
    db = AppDatabase.openInMemoryDatabase();
    await _seedBank(db);
    fakeRepo = _FakeBankRepository();
  });

  tearDown(() async => await db.close());

  Future<void> setLargeSurface(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets('shows red delete card with destructive style', (tester) async {
    await setLargeSurface(tester);
    await tester.pumpWidget(_wrap(db: db, repo: fakeRepo));
    await tester.pumpAndSettle();

    expect(find.text('删除题库'), findsOneWidget);
    expect(find.textContaining('不可撤销'), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
  });

  testWidgets('opens confirm dialog on tap', (tester) async {
    await setLargeSurface(tester);
    await tester.pumpWidget(_wrap(db: db, repo: fakeRepo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('删除题库'));
    await tester.pumpAndSettle();

    expect(find.text('删除「Test Bank」？'), findsOneWidget);
    expect(find.text('取消'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '删除题库'), findsOneWidget);
  });

  testWidgets('cancel does not delete', (tester) async {
    await setLargeSurface(tester);
    await tester.pumpWidget(_wrap(db: db, repo: fakeRepo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('删除题库'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expect(fakeRepo.deletedIds, isEmpty);
    expect(find.byType(BankDetailScreen), findsOneWidget);
  });

  testWidgets('confirm deletes, pops, shows SnackBar', (tester) async {
    await setLargeSurface(tester);
    await tester.pumpWidget(_wrap(db: db, repo: fakeRepo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('删除题库'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '删除题库'));
    // Pump just enough for SnackBar enter animation (~250ms) to complete
    // and text to be in tree. Avoid pumping too long which would let the
    // 4-second default SnackBar display expire.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(fakeRepo.deletedIds, ['b1']);
    expect(find.text('已删除「Test Bank」'), findsOneWidget);
  });
}
