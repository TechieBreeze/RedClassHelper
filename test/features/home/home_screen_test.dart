import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redclass/data/db/database.dart';
import 'package:redclass/features/quiz/providers/bank_pick_provider.dart';
import 'package:redclass/routing/router.dart';

/// Helper: provides a default empty bank list so the home screen
/// shows "导入题库开始复习" subtitle (rather than crashing) when a
/// test does not supply its own [bankPickListProvider] override.
List<Override> _emptyBankListOverrides() => [
  bankPickListProvider.overrideWith((ref) async => <BankPickItem>[]),
];

/// 在 [tester.pumpAndSettle] 之前先让异步微任务跑完 (Riverpod Future provider
/// 的解析在 microtask 里完成,直接 pumpAndSettle 不会等)。
Future<void> _settleAsync(WidgetTester tester) async {
  await tester.runAsync(() async => tester.pump());
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    appRouter.go('/');
  });

  testWidgets('shows banks entry tile and stats tile on empty state', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _emptyBankListOverrides(),
        child: MaterialApp.router(routerConfig: appRouter),
      ),
    );
    await _settleAsync(tester);

    expect(find.text('红课复习'), findsOneWidget);

    expect(find.text('我的题库'), findsOneWidget);
    expect(find.text('导入题库开始复习'), findsOneWidget);

    expect(find.text('乱序抽题'), findsOneWidget);
    expect(find.text('错题复习'), findsOneWidget);
    expect(find.text('错题抽查'), findsOneWidget);
    expect(find.text('随机出题 · 即时判分'), findsOneWidget);

    expect(find.text('数据统计'), findsOneWidget);
    expect(find.text('查看正确率与错题分布'), findsOneWidget);
  });

  testWidgets('entry tile surfaces bank and question totals', (tester) async {
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
    await _settleAsync(tester);

    expect(find.text('我的题库'), findsOneWidget);
    expect(find.text('2 个题库 · 共 80 道题'), findsOneWidget);
  });

  testWidgets('tapping stats entry navigates to /stats', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _emptyBankListOverrides(),
        child: MaterialApp.router(routerConfig: appRouter),
      ),
    );
    await _settleAsync(tester);

    final statsTile = find.text('查看正确率与错题分布');
    await tester.ensureVisible(statsTile);
    await tester.pumpAndSettle();

    await tester.tap(statsTile);
    // 给路由切换时间 (目标页有 CircularProgressIndicator, 不要 pumpAndSettle)
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('数据统计'), findsOneWidget);
  });

  testWidgets('tapping banks entry tile navigates to /banks', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _emptyBankListOverrides(),
        child: MaterialApp.router(routerConfig: appRouter),
      ),
    );
    await _settleAsync(tester);

    // 入口卡可能位于屏幕外 (宽屏内容堆叠), 滚动到可见
    final entryTile = find.text('我的题库');
    await tester.ensureVisible(entryTile);
    await tester.pumpAndSettle();

    await tester.tap(entryTile);
    await tester.pump(const Duration(milliseconds: 400));

    // BanksListScreen AppBar 标题
    expect(find.text('我的题库'), findsOneWidget);
  });
}
