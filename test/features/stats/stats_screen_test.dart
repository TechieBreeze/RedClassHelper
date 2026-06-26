import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:redclass/data/db/database.dart';
import 'package:redclass/features/stats/providers/stats_provider.dart';
import 'package:redclass/features/stats/presentation/stats_screen.dart';

/// Helper to create a mock BankStats for widget tests.
BankStats _createMockStats({
  String bankName = 'Test Bank',
  int totalQuestions = 10,
  int totalAttempts = 50,
  int correctCount = 35,
  int activeLedgerCount = 5,
  List<ModeBreakdown>? modes,
}) {
  final bank = QuestionBank(
    id: 'bank-1',
    name: bankName,
    source: 'test.docx',
    questionCount: totalQuestions,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
  return BankStats(
    bank: bank,
    totalQuestions: totalQuestions,
    totalAttempts: totalAttempts,
    correctCount: correctCount,
    activeLedgerCount: activeLedgerCount,
    modes:
        modes ??
        const [
          ModeBreakdown(mode: 'random', attempts: 30, correctCount: 20),
          ModeBreakdown(mode: 'review', attempts: 15, correctCount: 12),
          ModeBreakdown(mode: 'spotcheck', attempts: 5, correctCount: 3),
        ],
  );
}

void main() {
  // ── Test 1: Loading state ──
  testWidgets('StatsScreen shows CircularProgressIndicator while loading', (
    tester,
  ) async {
    final completer = Completer<List<BankStats>>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bankStatsListProvider.overrideWith((ref) => completer.future),
        ],
        child: const MaterialApp(home: StatsScreen()),
      ),
    );

    // Should show loading indicator and text
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('加载统计...'), findsOneWidget);

    // Clean up
    completer.complete([]);
  });

  // ── Test 2: Empty state ──
  testWidgets('StatsScreen shows empty state when no banks exist', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [bankStatsListProvider.overrideWith((ref) async => [])],
        child: const MaterialApp(home: StatsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('暂无统计数据'), findsOneWidget);
    expect(find.text('完成答题后这里会显示各题库的正确率统计'), findsOneWidget);
    expect(find.byIcon(Icons.insights_outlined), findsOneWidget);
  });

  // ── Test 3: Data state ──
  testWidgets('StatsScreen shows bank card list when banks have stats', (
    tester,
  ) async {
    final stats = [
      _createMockStats(bankName: 'Bank A'),
      _createMockStats(bankName: 'Bank B'),
    ];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [bankStatsListProvider.overrideWith((ref) async => stats)],
        child: const MaterialApp(home: StatsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // App bar
    expect(find.text('数据统计'), findsOneWidget);

    // Bank names visible
    expect(find.text('Bank A'), findsOneWidget);
    expect(find.text('Bank B'), findsOneWidget);

    // Summary stats visible
    expect(find.text('正确率'), findsNWidgets(2));
    expect(find.text('错题本'), findsNWidgets(2));

    // Correct rate display
    expect(find.text('70%'), findsNWidgets(2)); // 35/50 = 70%

    // Ledger counts
    expect(find.text('5'), findsNWidgets(2)); // activeLedgerCount = 5

    // Expand chevrons visible
    expect(find.byIcon(Icons.expand_more), findsNWidgets(2));
  });

  // ── Test 4: Expanding a card shows per-mode rows ──
  testWidgets('StatsScreen expanding a card shows per-mode rows', (
    tester,
  ) async {
    final stats = [_createMockStats(bankName: 'Bank A')];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [bankStatsListProvider.overrideWith((ref) async => stats)],
        child: const MaterialApp(home: StatsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Per-mode rows should NOT be visible before expanding
    expect(find.text('乱序抽题'), findsNothing);
    expect(find.text('错题复习'), findsNothing);
    expect(find.text('错题抽查'), findsNothing);

    // Tap the card to expand
    await tester.tap(find.text('Bank A'));
    await tester.pumpAndSettle();

    // Now per-mode rows should be visible
    expect(find.text('乱序抽题'), findsOneWidget);
    expect(find.text('错题复习'), findsOneWidget);
    expect(find.text('错题抽查'), findsOneWidget);

    // Check mode stats display
    // random: 30 attempts, 20 correct → 66% (20/30) ≈ 67%
    expect(find.textContaining('30次 ·'), findsOneWidget);
    // review: 15 attempts, 12 correct → 80% (12/15)
    expect(find.text('15次 · 80%'), findsOneWidget);
    // spotcheck: 5 attempts, 3 correct → 60% (3/5)
    expect(find.text('5次 · 60%'), findsOneWidget);
  });

  // ── Test 5: Error state with retry ──
  testWidgets('StatsScreen retry button invalidates provider', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bankStatsListProvider.overrideWith((ref) async {
            throw Exception('Test error');
          }),
        ],
        child: const MaterialApp(home: StatsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Error state visible
    expect(find.text('加载失败'), findsOneWidget);
    expect(find.text('请返回重试'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);

    // Retry button exists
    expect(find.text('重试'), findsOneWidget);

    // Tap retry — should re-invoke the provider (which throws again)
    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();

    // Error state should still be shown (provider still throws)
    expect(find.text('加载失败'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
  });
}
