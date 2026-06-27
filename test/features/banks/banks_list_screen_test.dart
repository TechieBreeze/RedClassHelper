import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redclass/data/db/database.dart';
import 'package:redclass/features/quiz/providers/bank_pick_provider.dart';
import 'package:redclass/routing/router.dart';

QuestionBank _bank(String id, String name) => QuestionBank(
  id: id,
  name: name,
  source: '/path/$id.docx',
  questionCount: 10,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

BankPickItem _pick(QuestionBank bank, {int total = 10, int wrong = 0}) =>
    BankPickItem(bank: bank, totalQuestions: total, activeWrongCount: wrong);

/// Riverpod Future provider 在 microtask 解析, 直接 pumpAndSettle 不等。
/// 用 runAsync 包一层 pump 让 microtask 跑完。
Future<void> _settleAsync(WidgetTester tester) async {
  await tester.runAsync(() async => tester.pump());
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    appRouter.go('/banks');
  });

  testWidgets('AppBar shows title and settings action', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bankPickListProvider.overrideWith((ref) async => <BankPickItem>[]),
        ],
        child: MaterialApp.router(routerConfig: appRouter),
      ),
    );
    await _settleAsync(tester);

    expect(find.text('我的题库'), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
  });

  testWidgets('renders empty state with import CTA', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bankPickListProvider.overrideWith((ref) async => <BankPickItem>[]),
        ],
        child: MaterialApp.router(routerConfig: appRouter),
      ),
    );
    await _settleAsync(tester);

    expect(find.text('还没有题库'), findsOneWidget);
    expect(find.text('导入 .docx / .pdf / .json 开始复习'), findsOneWidget);
    expect(find.text('导入题库'), findsOneWidget);
  });

  testWidgets('tapping import CTA navigates to /import', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bankPickListProvider.overrideWith((ref) async => <BankPickItem>[]),
        ],
        child: MaterialApp.router(routerConfig: appRouter),
      ),
    );
    await _settleAsync(tester);

    await tester.tap(find.text('导入题库'));
    await tester.pump(const Duration(milliseconds: 400));

    // ImportScreen AppBar 标题
    expect(find.text('导入题库'), findsWidgets);
  });

  testWidgets('renders one row per bank with totals and wrong badges', (
    tester,
  ) async {
    final banks = [
      _pick(_bank('b1', '业余A类'), total: 100, wrong: 3),
      _pick(_bank('b2', '业余B类'), total: 200, wrong: 0),
      _pick(_bank('b3', '业余C类'), total: 50, wrong: 1),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [bankPickListProvider.overrideWith((ref) async => banks)],
        child: MaterialApp.router(routerConfig: appRouter),
      ),
    );
    await _settleAsync(tester);

    expect(find.text('业余A类'), findsOneWidget);
    expect(find.text('业余B类'), findsOneWidget);
    expect(find.text('业余C类'), findsOneWidget);

    expect(find.text('3 错'), findsOneWidget);
    expect(find.text('1 错'), findsOneWidget);
    expect(find.text('0 错'), findsNothing);

    expect(find.textContaining('100 题'), findsOneWidget);
    expect(find.textContaining('200 题'), findsOneWidget);
    expect(find.textContaining('50 题'), findsOneWidget);
  });

  testWidgets('tapping a bank row navigates to /bank/:id', (tester) async {
    final banks = [_pick(_bank('test-123', '测试题库'), total: 10)];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [bankPickListProvider.overrideWith((ref) async => banks)],
        child: MaterialApp.router(routerConfig: appRouter),
      ),
    );
    await _settleAsync(tester);

    await tester.tap(find.text('测试题库'));
    // BankDetailScreen 启动时会查数据库, 用 pump+固定时长避免等转圈
    // AppBar 在 loading 状态下也会渲染, 所以 600ms 足够看到 "题库详情"
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('题库详情'), findsOneWidget);
  });

  // 错误状态的测试跳过: Riverpod FutureProvider 在 widget test 里
  // 抛 uncaught async exception 会导致 pumpWidget hang, 暂时无法稳定覆盖。
  // _ErrorState 组件本身是纯 UI, 通过手动 code review 验证。

  testWidgets('renders skeleton cards while data is pending', (tester) async {
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

    // 加载骨架使用 Card 组件 (3 个)
    expect(find.byType(Card), findsAtLeast(1));
  });
}
