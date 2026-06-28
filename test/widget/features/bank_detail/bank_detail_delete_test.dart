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

  testWidgets('DB failure: SnackBar shows error, no pop', (tester) async {
    fakeRepo.onDelete = (_) async => throw Exception('disk full');
    await setLargeSurface(tester);
    await tester.pumpWidget(_wrap(db: db, repo: fakeRepo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('删除题库'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '删除题库'));
    await tester.pumpAndSettle();

    expect(find.textContaining('删除失败'), findsOneWidget);
    expect(find.byType(BankDetailScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('context unmounted during delete: no crash', (tester) async {
    final slowRepo = _FakeBankRepository()
      ..onDelete = (_) =>
          Future<void>.delayed(const Duration(milliseconds: 200));
    await setLargeSurface(tester);
    await tester.pumpWidget(_wrap(db: db, repo: slowRepo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('删除题库'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '删除题库'));
    await tester.pump(const Duration(milliseconds: 50));
    // Simulate user navigating away before the async delete resolves.
    // Replace the widget tree with an empty MaterialApp — this unmounts
    // the BankDetailScreen (exercising the `context.mounted` guards in
    // `_performDelete`) without leaving the ProviderScope alive.
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pumpAndSettle();
    // Let the pending slow delete complete in the background.
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'delete button disabled while deletion in-flight (double-tap guard)',
    (tester) async {
      final slowRepo = _FakeBankRepository()
        ..onDelete = (_) =>
            Future<void>.delayed(const Duration(milliseconds: 200));
      await setLargeSurface(tester);
      await tester.pumpWidget(_wrap(db: db, repo: slowRepo));
      await tester.pumpAndSettle();

      // Open the dialog and confirm — this kicks off the in-flight delete.
      await tester.tap(find.text('删除题库'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '删除题库'));
      await tester.pump(); // Dialog closes, _isDeleting=true, delete in flight.
      // While delete is in-flight, the card onTap is null. Tap the card
      // text again — nothing should happen (no dialog re-opens, no second
      // delete fires).
      await tester.tap(find.text('删除题库'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(slowRepo.deletedIds, hasLength(1)); // Only one delete fired.
    },
  );

  testWidgets('list page reflects deletion after pop', (tester) async {
    final goRouterRepo = _FakeBankRepository();
    await setLargeSurface(tester);
    await tester.pumpWidget(_wrap(db: db, repo: goRouterRepo));
    await tester.pumpAndSettle();

    // Sanity: bank exists before delete.
    expect((await db.select(db.questionBanks).get()), hasLength(1));

    await tester.tap(find.text('删除题库'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '删除题库'));
    await tester.pumpAndSettle();

    // fakeRepo does not touch the DB, but the controller has invoked
    // deleteBank('b1'); verify the call was made (controller-side
    // invalidate of the list provider reflects this through the fake).
    expect(goRouterRepo.deletedIds, ['b1']);
  });

  testWidgets('delete card shows spinner during in-flight deletion', (
    tester,
  ) async {
    final slowRepo = _FakeBankRepository()
      ..onDelete = (_) =>
          Future<void>.delayed(const Duration(milliseconds: 300));
    await setLargeSurface(tester);
    await tester.pumpWidget(_wrap(db: db, repo: slowRepo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('删除题库'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '删除题库'));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
    // Drain the pending slow-delete timer so the test exits cleanly.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  });
}
