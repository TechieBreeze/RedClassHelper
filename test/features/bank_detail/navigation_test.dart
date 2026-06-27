import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redclass/core/nav/safe_nav.dart';
import 'package:redclass/core/widgets/hoverable_card.dart';
import 'package:redclass/data/db/database.dart';
import 'package:redclass/features/quiz/providers/quiz_settings_provider.dart';
import 'package:redclass/routing/router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stage C nav tests for BankDetailScreen: the "开始复习" HoverableCard
/// pushes /quiz/{bankId}/random (skips BankPicker by design) and back
/// returns to the bank detail page.

String _topLocation(dynamic router) =>
    router.routerDelegate.currentConfiguration.matches.last.matchedLocation;
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;

  Future<void> insertBank({
    required String bankId,
    required String bankName,
  }) async {
    final now = DateTime.now();
    await db.into(db.questionBanks).insert(
          QuestionBanksCompanion.insert(
            id: bankId,
            name: bankName,
            questionCount: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
    await db.into(db.questions).insert(
          QuestionsCompanion.insert(
            id: 'q_$bankId',
            bankId: bankId,
            type: 'single',
            stem: 'q',
            optionsJson: jsonEncode([
              {'key': 'A', 'text': 'a'},
              {'key': 'B', 'text': 'b'},
            ]),
            correctJson: jsonEncode(['A']),
            rawText: 'q',
            createdAt: now,
          ),
        );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    NavGuard.resetForTest();
    appRouter.go('/');
    db = AppDatabase.openInMemoryDatabase();
  });

  tearDown(() async => await db.close());

  testWidgets(
    'tap "开始复习" pushes /quiz/{bankId}/random (skips BankPicker)',
    (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await insertBank(bankId: 'b1', bankName: '题库A');
      appRouter.go('/bank/b1');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWith((ref) async => db),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp.router(routerConfig: appRouter),
        ),
      );
      await tester.pumpAndSettle();

      expect(_topLocation(appRouter), '/bank/b1');

      await tester.tap(find.widgetWithText(HoverableCard, '开始复习'));
      await tester.pumpAndSettle();

      expect(_topLocation(appRouter), '/quiz/b1/random');
    },
  );

  testWidgets(
    'back from /quiz/{bankId}/random returns to /bank/{bankId}',
    (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await insertBank(bankId: 'b1', bankName: '题库A');
      appRouter.go('/bank/b1');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWith((ref) async => db),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp.router(routerConfig: appRouter),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(HoverableCard, '开始复习'));
      await tester.pumpAndSettle();
      expect(_topLocation(appRouter), '/quiz/b1/random');

      appRouter.pop();
      await tester.pumpAndSettle();

      expect(_topLocation(appRouter), '/bank/b1');
    },
  );
}