// test/widget/features/bank_detail/bank_detail_responsive_test.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:redclass/core/platform/platform_info.dart';
import 'package:redclass/core/platform/responsive.dart';
import 'package:redclass/data/db/database.dart';
import 'package:redclass/features/bank_detail/presentation/bank_detail_screen.dart';
import 'package:drift/drift.dart' show Value;

Future<void> _insertBankAndQuestions({
  required AppDatabase db,
  required String bankId,
  required String bankName,
  int questionCount = 4,
}) async {
  final now = DateTime(2026, 1, 1);
  await db
      .into(db.questionBanks)
      .insert(
        QuestionBanksCompanion.insert(
          id: bankId,
          name: bankName,
          source: const Value('/home/user/test.docx'),
          questionCount: questionCount,
          createdAt: now,
          updatedAt: now,
        ),
      );
  for (var i = 0; i < questionCount; i++) {
    await db
        .into(db.questions)
        .insert(
          QuestionsCompanion.insert(
            id: 'q${bankId}_$i',
            bankId: bankId,
            type: i % 2 == 0 ? 'single' : 'multiple',
            stem: 'Question $i',
            optionsJson: jsonEncode([
              {'key': 'A', 'text': 'A'},
              {'key': 'B', 'text': 'B'},
            ]),
            correctJson: jsonEncode([i % 2 == 0 ? 'A' : 'AB']),
            rawText: 'Question $i',
            createdAt: now,
          ),
        );
  }
}

Widget _harness({
  required Size size,
  required AppPlatform platform,
  required AppDatabase db,
}) {
  return ProviderScope(
    overrides: [appDatabaseProvider.overrideWith((ref) async => db)],
    child: MaterialApp(
      home: ResponsiveBuilder(
        info: PlatformInfo.forTesting(
          platform: platform,
          shortestSide: size.shortestSide,
        ),
        builder: (context, _) => MediaQuery(
          data: MediaQueryData(size: size),
          child: const BankDetailScreen(bankId: 'b1'),
        ),
      ),
    ),
  );
}

/// True iff any [ConstrainedBox] descendant of [startFinder] has
/// `maxWidth` equal to [maxWidth]. This distinguishes the medium branch
/// (Center > ConstrainedBox(maxWidth: 720) > ListView) from the compact
/// branch (bare ListView with no width cap).
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
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.openInMemoryDatabase();
  });

  tearDown(() async => await db.close());

  testWidgets('compact width (400x800) renders vertical layout key', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _insertBankAndQuestions(
      db: db,
      bankId: 'b1',
      bankName: '测试题库',
      questionCount: 4,
    );

    await tester.pumpWidget(
      _harness(
        size: const Size(400, 800),
        platform: AppPlatform.android,
        db: db,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('bank_detail_vertical_layout')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('bank_detail_horizontal_layout')),
      findsNothing,
    );

    // Compact: no 720-cap
    expect(
      _hasDescendantConstrainedBoxMaxWidth(
        find.byKey(const Key('bank_detail_vertical_layout')),
        720,
      ),
      isFalse,
    );
  });

  testWidgets(
    'medium width (700x900) renders vertical layout key with 720-centered ConstrainedBox ancestor',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(700, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _insertBankAndQuestions(
        db: db,
        bankId: 'b1',
        bankName: '测试题库',
        questionCount: 4,
      );

      await tester.pumpWidget(
        _harness(
          size: const Size(700, 900),
          platform: AppPlatform.android,
          db: db,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('bank_detail_vertical_layout')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('bank_detail_horizontal_layout')),
        findsNothing,
      );

      // Medium: 720-cap active
      expect(
        _hasDescendantConstrainedBoxMaxWidth(
          find.byKey(const Key('bank_detail_vertical_layout')),
          720,
        ),
        isTrue,
      );
    },
  );

  testWidgets('expanded width (1500x1000) renders horizontal layout key', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1500, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _insertBankAndQuestions(
      db: db,
      bankId: 'b1',
      bankName: '测试题库',
      questionCount: 4,
    );

    await tester.pumpWidget(
      _harness(
        size: const Size(1500, 1000),
        platform: AppPlatform.windows,
        db: db,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('bank_detail_horizontal_layout')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('bank_detail_vertical_layout')), findsNothing);
  });
}
