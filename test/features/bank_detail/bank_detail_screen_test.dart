import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:redclass/data/db/database.dart';
import 'package:redclass/features/bank_detail/presentation/bank_detail_screen.dart';
import 'package:redclass/routing/router.dart';

/// Helper: insert a bank and its questions into the in-memory test DB.
Future<void> _insertBankAndQuestions({
  required AppDatabase db,
  required String bankId,
  required String bankName,
  String source = '/home/user/test.docx',
  int questionCount = 3,
}) async {
  final now = DateTime.now();
  await db.into(db.questionBanks).insert(
    QuestionBanksCompanion.insert(
      id: bankId,
      name: bankName,
      source: source,
      questionCount: questionCount,
      createdAt: now,
      updatedAt: now,
    ),
  );
  for (var i = 0; i < questionCount; i++) {
    final optionsList = [
      {'key': 'A', 'text': '选项A'},
      {'key': 'B', 'text': '选项B'},
      {'key': 'C', 'text': '选项C'},
      {'key': 'D', 'text': '选项D'},
    ];
    await db.into(db.questions).insert(
      QuestionsCompanion.insert(
        id: 'q${bankId}_$i',
        bankId: bankId,
        type: i % 2 == 0 ? 'single' : 'multiple',
        stem: 'Question text $i',
        optionsJson: jsonEncode(optionsList),
        correctJson: jsonEncode([i % 2 == 0 ? 'A' : 'AB']),
        rawText: 'Question text $i',
        createdAt: now,
      ),
    );
  }
}

void main() {
  late AppDatabase db;

  setUp(() async {
    // GoRouter is a singleton — reset its location to prevent cross-test leaks
    appRouter.go('/');
    db = AppDatabase.openInMemoryDatabase();
  });

  tearDown(() async => await db.close());

  // ═══════════════════════════════════════════════════════════════
  // Test 1: BankDetailScreen renders bank name in AppBar
  // ═══════════════════════════════════════════════════════════════
  testWidgets('BankDetailScreen renders bank name in AppBar',
      (tester) async {
    await _insertBankAndQuestions(
      db: db,
      bankId: 'b1',
      bankName: '测试题库',
      questionCount: 3,
    );
    appRouter.go('/bank/b1');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((ref) async => db),
        ],
        child: MaterialApp.router(routerConfig: appRouter),
      ),
    );
    await tester.pumpAndSettle();

    // Bank name appears in both AppBar title and info card headlineSmall
    expect(find.text('测试题库'), findsAtLeast(1));
  });

  // ═══════════════════════════════════════════════════════════════
  // Test 2: BankDetailScreen shows question count in info card
  // ═══════════════════════════════════════════════════════════════
  testWidgets('BankDetailScreen shows question count in info card',
      (tester) async {
    await _insertBankAndQuestions(
      db: db,
      bankId: 'b1',
      bankName: '题库A',
      questionCount: 5,
    );
    appRouter.go('/bank/b1');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((ref) async => db),
        ],
        child: MaterialApp.router(routerConfig: appRouter),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('5 题'), findsOneWidget);
  });

  // ═══════════════════════════════════════════════════════════════
  // Test 3: BankDetailScreen shows source filename (basename only)
  // ═══════════════════════════════════════════════════════════════
  testWidgets('BankDetailScreen shows source filename', (tester) async {
    await _insertBankAndQuestions(
      db: db,
      bankId: 'b1',
      bankName: '题库A',
      source: '/home/user/考试题库.docx',
    );
    appRouter.go('/bank/b1');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((ref) async => db),
        ],
        child: MaterialApp.router(routerConfig: appRouter),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('考试题库.docx'), findsOneWidget);
  });

  // ═══════════════════════════════════════════════════════════════
  // Test 4: BankDetailScreen renders "导出 JSON" FilledButton
  // ═══════════════════════════════════════════════════════════════
  testWidgets('BankDetailScreen renders "导出 JSON" FilledButton',
      (tester) async {
    await _insertBankAndQuestions(
      db: db,
      bankId: 'b1',
      bankName: '题库A',
    );
    appRouter.go('/bank/b1');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((ref) async => db),
        ],
        child: MaterialApp.router(routerConfig: appRouter),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, '导出 JSON'), findsOneWidget);
  });

  // ═══════════════════════════════════════════════════════════════
  // Test 5: BankDetailScreen renders "开始复习" FilledButton
  // ═══════════════════════════════════════════════════════════════
  testWidgets('BankDetailScreen renders "开始复习" FilledButton',
      (tester) async {
    await _insertBankAndQuestions(
      db: db,
      bankId: 'b1',
      bankName: '题库A',
    );
    appRouter.go('/bank/b1');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((ref) async => db),
        ],
        child: MaterialApp.router(routerConfig: appRouter),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, '开始复习'), findsOneWidget);
  });

  // ═══════════════════════════════════════════════════════════════
  // Test 6: BankDetailScreen shows loading indicator when DB not yet ready
  // ═══════════════════════════════════════════════════════════════
  testWidgets(
      'BankDetailScreen shows loading indicator when DB not yet ready',
      (tester) async {
    final completer = Completer<AppDatabase>();
    appRouter.go('/bank/b1');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((ref) => completer.future),
        ],
        child: MaterialApp.router(routerConfig: appRouter),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  // ═══════════════════════════════════════════════════════════════
  // Test 7: BankDetailScreen shows error when bank not found
  // ═══════════════════════════════════════════════════════════════
  testWidgets('BankDetailScreen shows error when bank not found',
      (tester) async {
    appRouter.go('/bank/nonexistent');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((ref) async => db),
        ],
        child: MaterialApp.router(routerConfig: appRouter),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('题库不存在'), findsOneWidget);
  });

  // ═══════════════════════════════════════════════════════════════
  // Test 8: Tapping "开始复习" navigates to /quiz/pick/random
  // ═══════════════════════════════════════════════════════════════
  testWidgets('Tapping "开始复习" navigates to /quiz/pick/random',
      (tester) async {
    await _insertBankAndQuestions(
      db: db,
      bankId: 'b1',
      bankName: '题库A',
    );
    appRouter.go('/bank/b1');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((ref) async => db),
        ],
        child: MaterialApp.router(routerConfig: appRouter),
      ),
    );
    await tester.pumpAndSettle();

    // Tap the "开始复习" button
    await tester.tap(find.widgetWithText(FilledButton, '开始复习'));
    await tester.pumpAndSettle();

    // BankPickerScreen AppBar shows "选择题库"
    expect(find.text('选择题库'), findsOneWidget);
  });
}
