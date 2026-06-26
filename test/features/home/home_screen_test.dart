import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redclass/data/db/database.dart';
import 'package:redclass/features/home/presentation/home_screen.dart';
import 'package:redclass/features/quiz/providers/bank_pick_provider.dart';
import 'package:redclass/routing/router.dart';

/// Helper: provides a default empty bank list so the home screen
/// shows the empty-state card (rather than loading or error) when a
/// test does not supply its own [bankPickListProvider] override.
List<Override> _emptyBankListOverrides() => [
  bankPickListProvider.overrideWith((ref) async => <BankPickItem>[]),
];

void main() {
  setUp(() {
    // GoRouter 是全局单例,前一个测试的导航状态会泄露。
    // 每个测试前强制回到 / 路由。
    appRouter.go('/');
  });
  testWidgets('HomeScreen renders all sections per UI-SPEC (UI-02)', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _emptyBankListOverrides(),
        child: MaterialApp.router(routerConfig: appRouter),
      ),
    );
    await tester.pumpAndSettle();

    // App bar
    expect(find.text('红课复习'), findsOneWidget);

    // Section headers
    expect(find.text('题库'), findsOneWidget);
    expect(find.text('复习模式'), findsOneWidget);
    // '数据统计' appears in section header AND stats entry tile → 2 occurrences
    expect(find.text('数据统计'), findsNWidgets(2));

    // Bank empty state
    expect(find.text('还没有题库'), findsOneWidget);
    expect(find.textContaining('导入一份 .docx'), findsOneWidget);

    // 3 mode tiles
    expect(find.text('乱序抽题'), findsOneWidget);
    expect(find.text('错题复习'), findsOneWidget);
    expect(find.text('错题抽查'), findsOneWidget);
    expect(find.text('随机抽题，立刻判分'), findsOneWidget);
    expect(find.text('从错题本复习，答对即掌握'), findsOneWidget);
    expect(find.text('从错题本随机抽 10 题自测'), findsOneWidget);

    // Stats entry
    expect(find.text('查看正确率与错题分布'), findsOneWidget);

    // Settings gear icon
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
  });

  testWidgets('Tapping mode tile navigates to /quiz/new/<mode>', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _emptyBankListOverrides(),
        child: MaterialApp.router(routerConfig: appRouter),
      ),
    );
    await tester.pumpAndSettle();

    // Tap the 乱序抽题 tile (the InkWell wraps the entire Card)
    await tester.tap(find.text('乱序抽题'));
    await tester.pumpAndSettle();

    expect(find.text('答题'), findsOneWidget);
    expect(find.textContaining('bankId=new'), findsOneWidget);
    expect(find.textContaining('mode=random'), findsOneWidget);
  });

  testWidgets('Tapping stats entry navigates to /stats', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _emptyBankListOverrides(),
        child: MaterialApp.router(routerConfig: appRouter),
      ),
    );
    await tester.pumpAndSettle();

    // Tap the stats entry tile using the descriptive text below the title
    final statsTile = find.text('查看正确率与错题分布');
    await tester.ensureVisible(statsTile);
    await tester.pumpAndSettle();

    await tester.tap(statsTile);
    await tester.pumpAndSettle();

    // StatsScreen AppBar title (only one "数据统计" on this screen)
    expect(find.text('数据统计'), findsOneWidget);
  });

  testWidgets('Disabled buttons are present', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _emptyBankListOverrides(),
        child: MaterialApp.router(routerConfig: appRouter),
      ),
    );
    await tester.pumpAndSettle();

    // 3 mode tiles + 1 import button = 4 disabled buttons
    expect(find.text('开始'), findsNWidgets(3));
    expect(find.text('导入题库'), findsOneWidget);
  });

  testWidgets('Tapping bank empty state navigates to /import', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _emptyBankListOverrides(),
        child: MaterialApp.router(routerConfig: appRouter),
      ),
    );
    await tester.pumpAndSettle();

    // Tap the bank empty state card
    await tester.tap(find.text('还没有题库'));
    await tester.pumpAndSettle();

    expect(find.text('导入题库'), findsOneWidget); // app bar on ImportScreen
  });

  testWidgets('HomeScreen shows real bank cards when banks exist', (
    tester,
  ) async {
    final testBanks = [
      BankPickItem(
        bank: QuestionBank(
          id: 'b1',
          name: '题库A',
          source: '/path/a.docx',
          questionCount: 30,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        totalQuestions: 30,
        activeWrongCount: 5,
      ),
      BankPickItem(
        bank: QuestionBank(
          id: 'b2',
          name: '题库B',
          source: '/path/b.docx',
          questionCount: 50,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        totalQuestions: 50,
        activeWrongCount: 0,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bankPickListProvider.overrideWith((ref) async => testBanks),
        ],
        child: MaterialApp.router(routerConfig: appRouter),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('题库A'), findsOneWidget);
    expect(find.text('题库B'), findsOneWidget);
    expect(find.textContaining('30题'), findsOneWidget);
    expect(find.textContaining('50题'), findsOneWidget);
  });

  testWidgets('HomeScreen shows empty state when bank list is empty', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bankPickListProvider.overrideWith((ref) async => <BankPickItem>[]),
        ],
        child: MaterialApp.router(routerConfig: appRouter),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('还没有题库'), findsOneWidget);
  });

  testWidgets('HomeScreen shows loading state while bank list loads', (
    tester,
  ) async {
    final completer = Completer<List<BankPickItem>>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bankPickListProvider.overrideWith((ref) => completer.future),
        ],
        child: MaterialApp.router(routerConfig: appRouter),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsAtLeast(1));
  });

  testWidgets('HomeScreen shows error state when bank list fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bankPickListProvider.overrideWith((ref) async {
            throw Exception('connection failed');
          }),
        ],
        child: MaterialApp.router(routerConfig: appRouter),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('加载题库列表失败'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
  });

  testWidgets('Tapping bank card navigates to /bank/:id', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bankPickListProvider.overrideWith(
            (ref) async => [
              BankPickItem(
                bank: QuestionBank(
                  id: 'bank-123',
                  name: '测试题库',
                  source: '/path/test.docx',
                  questionCount: 10,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ),
                totalQuestions: 10,
                activeWrongCount: 0,
              ),
            ],
          ),
        ],
        child: MaterialApp.router(routerConfig: appRouter),
      ),
    );
    await tester.pumpAndSettle();

    // Tap the bank card to navigate
    await tester.tap(find.text('测试题库'));
    await tester.pumpAndSettle();

    // Verify we navigated to bank detail screen
    expect(find.text('题库详情'), findsOneWidget);
  });
}
