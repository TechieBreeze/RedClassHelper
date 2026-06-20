import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

import 'package:redclass/data/db/database.dart';
import 'package:redclass/features/stats/providers/stats_provider.dart';

/// Helper: Insert a QuestionBank row.
Future<void> _insertBank({
  required AppDatabase db,
  required String bankId,
  required String name,
  String source = 'test',
  int questionCount = 0,
}) async {
  final now = DateTime.now();
  await db.into(db.questionBanks).insert(
        QuestionBanksCompanion.insert(
          id: bankId,
          name: name,
          source: source,
          questionCount: questionCount,
          createdAt: now,
          updatedAt: now,
        ),
      );
}

/// Helper: Insert a single Question row.
Future<void> _insertQuestion({
  required AppDatabase db,
  required String questionId,
  required String bankId,
  String type = 'single',
  String correctKey = 'A',
  String stem = 'Test question?',
}) async {
  final now = DateTime.now();
  await db.into(db.questions).insert(
        QuestionsCompanion.insert(
          id: questionId,
          bankId: bankId,
          type: type,
          stem: stem,
          optionsJson:
              '[{"key":"A","text":"Option A"},{"key":"B","text":"Option B"}]',
          correctJson: '["$correctKey"]',
          rawText: stem,
          createdAt: now,
        ),
      );
}

/// Helper: Insert an AnswerAttempt row.
Future<void> _insertAttempt({
  required AppDatabase db,
  required String questionId,
  required bool isCorrect,
  required String mode,
  int elapsedMs = 5000,
}) async {
  await db.into(db.answerAttempts).insert(
        AnswerAttemptsCompanion.insert(
          questionId: questionId,
          givenAnswerJson: isCorrect ? '["A"]' : '["B"]',
          isCorrect: isCorrect,
          mode: mode,
          elapsedMs: elapsedMs,
          createdAt: DateTime.now(),
        ),
      );
}

/// Helper: Insert a WrongLedgerEntry row.
Future<void> _insertLedgerEntry({
  required AppDatabase db,
  required String questionId,
  bool mastered = false,
}) async {
  final now = DateTime.now();
  await db.into(db.wrongLedgerEntries).insert(
        WrongLedgerEntriesCompanion.insert(
          questionId: questionId,
          timesWrong: 1,
          firstWrongAt: now,
          lastWrongAt: now,
          masteredAt: mastered ? Value(now) : const Value.absent(),
        ),
      );
}

ProviderContainer _createContainer(AppDatabase db) {
  return ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWith((ref) async => db),
    ],
  );
}

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    db = AppDatabase.openInMemoryDatabase();
    container = _createContainer(db);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  // ── Test 1 ──
  test('bankStatsListProvider returns empty list when no banks exist',
      () async {
    final stats = await container.read(bankStatsListProvider.future);
    expect(stats, isEmpty);
  });

  // ── Test 2 ──
  test('bankStatsListProvider returns one BankStats entry when one bank '
      'exists with no attempts (correctRate = 0.0)', () async {
    await _insertBank(
      db: db,
      bankId: 'bank-1',
      name: 'Test Bank',
      questionCount: 3,
    );
    await _insertQuestion(
      db: db,
      questionId: 'q-1',
      bankId: 'bank-1',
    );

    final stats = await container.read(bankStatsListProvider.future);
    expect(stats.length, 1);
    expect(stats.first.totalQuestions, 1);
    expect(stats.first.totalAttempts, 0);
    expect(stats.first.correctCount, 0);
    expect(stats.first.correctRate, 0.0);
    expect(stats.first.correctRateDisplay, '暂无');
    expect(stats.first.activeLedgerCount, 0);
  });

  // ── Test 3 ──
  test('bankStatsListProvider returns correct correctRate when attempts exist',
      () async {
    await _insertBank(
      db: db,
      bankId: 'bank-1',
      name: 'Test Bank',
      questionCount: 5,
    );
    await _insertQuestion(
      db: db,
      questionId: 'q-1',
      bankId: 'bank-1',
    );
    await _insertQuestion(
      db: db,
      questionId: 'q-2',
      bankId: 'bank-1',
    );

    // 2 correct, 2 incorrect → 4 total, rate = 0.5
    await _insertAttempt(
      db: db,
      questionId: 'q-1',
      isCorrect: true,
      mode: 'random',
    );
    await _insertAttempt(
      db: db,
      questionId: 'q-1',
      isCorrect: false,
      mode: 'random',
    );
    await _insertAttempt(
      db: db,
      questionId: 'q-2',
      isCorrect: true,
      mode: 'review',
    );
    await _insertAttempt(
      db: db,
      questionId: 'q-2',
      isCorrect: false,
      mode: 'review',
    );

    final stats = await container.read(bankStatsListProvider.future);
    expect(stats.length, 1);
    expect(stats.first.totalAttempts, 4);
    expect(stats.first.correctCount, 2);
    expect(stats.first.correctRate, 0.5);
    expect(stats.first.correctRateDisplay, '50%');
  });

  // ── Test 4 ──
  test(
      'bankStatsListProvider includes per-mode breakdown: random attempts '
      'count, correct count', () async {
    await _insertBank(
      db: db,
      bankId: 'bank-1',
      name: 'Per-Mode Bank',
      questionCount: 2,
    );
    await _insertQuestion(
      db: db,
      questionId: 'q-1',
      bankId: 'bank-1',
    );

    // 3 random attempts: 2 correct, 1 wrong
    await _insertAttempt(
      db: db,
      questionId: 'q-1',
      isCorrect: true,
      mode: 'random',
    );
    await _insertAttempt(
      db: db,
      questionId: 'q-1',
      isCorrect: true,
      mode: 'random',
    );
    await _insertAttempt(
      db: db,
      questionId: 'q-1',
      isCorrect: false,
      mode: 'random',
    );

    final stats = await container.read(bankStatsListProvider.future);
    final randomMode = stats.first.modes.firstWhere((m) => m.mode == 'random');
    expect(randomMode.attempts, 3);
    expect(randomMode.correctCount, 2);
    expect(randomMode.correctRate, closeTo(2.0 / 3.0, 0.001));
  });

  // ── Test 5 ──
  test(
      'bankStatsListProvider per-mode breakdown shows correct split across '
      'modes (random vs review vs spotcheck)', () async {
    await _insertBank(
      db: db,
      bankId: 'bank-1',
      name: 'Mixed Mode Bank',
      questionCount: 3,
    );
    await _insertQuestion(
      db: db,
      questionId: 'q-1',
      bankId: 'bank-1',
    );
    await _insertQuestion(
      db: db,
      questionId: 'q-2',
      bankId: 'bank-1',
    );
    await _insertQuestion(
      db: db,
      questionId: 'q-3',
      bankId: 'bank-1',
    );

    // Mode: random — 5 attempts (3 correct)
    for (var i = 0; i < 5; i++) {
      await _insertAttempt(
        db: db,
        questionId: 'q-1',
        isCorrect: i < 3,
        mode: 'random',
      );
    }
    // Mode: review — 3 attempts (2 correct)
    for (var i = 0; i < 3; i++) {
      await _insertAttempt(
        db: db,
        questionId: 'q-2',
        isCorrect: i < 2,
        mode: 'review',
      );
    }
    // Mode: spotcheck — 2 attempts (0 correct)
    for (var i = 0; i < 2; i++) {
      await _insertAttempt(
        db: db,
        questionId: 'q-3',
        isCorrect: false,
        mode: 'spotcheck',
      );
    }

    final stats = await container.read(bankStatsListProvider.future);
    expect(stats.first.modes.length, 3);

    final randomMode = stats.first.modes.firstWhere((m) => m.mode == 'random');
    expect(randomMode.attempts, 5);
    expect(randomMode.correctCount, 3);
    expect(randomMode.correctRate, 0.6);

    final reviewMode = stats.first.modes.firstWhere((m) => m.mode == 'review');
    expect(reviewMode.attempts, 3);
    expect(reviewMode.correctCount, 2);
    expect(reviewMode.correctRate, closeTo(2.0 / 3.0, 0.001));

    final spotcheckMode =
        stats.first.modes.firstWhere((m) => m.mode == 'spotcheck');
    expect(spotcheckMode.attempts, 2);
    expect(spotcheckMode.correctCount, 0);
    expect(spotcheckMode.correctRate, 0.0);

    // Overall totals should match
    expect(stats.first.totalAttempts, 10);
    expect(stats.first.correctCount, 5);
    expect(stats.first.correctRate, 0.5);
  });

  // ── Test 6 ──
  test('BankStats.correctRate returns 0.0 when totalAttempts == 0', () {
    final bankStats = BankStats(
      bank: QuestionBank(
        id: 'test-bank',
        name: 'Test',
        source: 'test',
        questionCount: 5,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
      totalQuestions: 5,
      totalAttempts: 0,
      correctCount: 0,
      activeLedgerCount: 0,
      modes: [],
    );
    expect(bankStats.correctRate, 0.0);
    expect(bankStats.correctRateDisplay, '暂无');
  });

  // ── Test 7 ──
  test('ModeBreakdown.correctRate returns 0.0 when attempts == 0', () {
    const breakdown = ModeBreakdown(
      mode: 'random',
      attempts: 0,
      correctCount: 0,
    );
    expect(breakdown.correctRate, 0.0);
  });

  // ── Test 8 ──
  test('ModeBreakdown.displayName returns correct Chinese labels', () {
    const random = ModeBreakdown(mode: 'random', attempts: 10, correctCount: 5);
    expect(random.displayName, '乱序抽题');

    const review = ModeBreakdown(mode: 'review', attempts: 5, correctCount: 3);
    expect(review.displayName, '错题复习');

    const spotcheck =
        ModeBreakdown(mode: 'spotcheck', attempts: 2, correctCount: 0);
    expect(spotcheck.displayName, '错题抽查');

    const unknown = ModeBreakdown(mode: 'other', attempts: 1, correctCount: 1);
    expect(unknown.displayName, 'other');
  });

  // ── Test 9 ──
  test('bankStatsListProvider includes activeLedgerCount from LedgerRepository',
      () async {
    await _insertBank(
      db: db,
      bankId: 'bank-1',
      name: 'Ledger Test Bank',
      questionCount: 3,
    );
    await _insertQuestion(
      db: db,
      questionId: 'q-1',
      bankId: 'bank-1',
    );
    await _insertQuestion(
      db: db,
      questionId: 'q-2',
      bankId: 'bank-1',
    );
    await _insertQuestion(
      db: db,
      questionId: 'q-3',
      bankId: 'bank-1',
    );

    // q-1 and q-2 are active wrong questions (not mastered)
    await _insertLedgerEntry(db: db, questionId: 'q-1');
    await _insertLedgerEntry(db: db, questionId: 'q-2');
    // q-3 is mastered
    await _insertLedgerEntry(db: db, questionId: 'q-3', mastered: true);

    final stats = await container.read(bankStatsListProvider.future);
    expect(stats.length, 1);
    expect(stats.first.activeLedgerCount, 2);
  });
}
