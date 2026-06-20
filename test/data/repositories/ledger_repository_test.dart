import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:redclass/data/db/database.dart';
import 'package:redclass/data/repositories/ledger_repository.dart';

void main() {
  late AppDatabase db;
  late LedgerRepository repo;

  setUp(() async {
    db = AppDatabase.openInMemoryDatabase();
    // The in-memory DB needs its tables created (migration strategy runs in
    // openInMemoryDatabase via the NativeDatabase.memory() constructor which
    // accepts the migration strategy from the generated code). However,
    // for the drift in-memory database the migration strategy is applied
    // via the onUpgrade/onCreate callbacks. Let's ensure tables exist.
    repo = LedgerRepository(db);
  });

  tearDown(() async => await db.close());

  // ── Helper: Insert a Question so FK constraints pass ──
  Future<void> _insertQuestion(String questionId, String bankId) async {
    await db.into(db.questionBanks).insert(
      QuestionBanksCompanion.insert(
        id: bankId,
        name: 'Test Bank',
        source: 'test',
        questionCount: 1,
      ),
    );
    await db.into(db.questions).insert(
      QuestionsCompanion.insert(
        id: questionId,
        bankId: bankId,
        type: 'single',
        stem: 'Test question?',
        optionsJson: '[{"key":"A","text":"Option A"}]',
        correctJson: '["A"]',
        rawText: 'Test question?',
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════
  // Test 1: markWrong inserts new entry with timesWrong=1
  // ═════════════════════════════════════════════════════════════
  test('markWrong inserts new entry with timesWrong=1', () async {
    await _insertQuestion('q1', 'b1');

    await repo.markWrong('q1');

    final entries = await db.select(db.wrongLedgerEntries).get();
    expect(entries.length, 1);
    expect(entries.first.questionId, 'q1');
    expect(entries.first.timesWrong, 1);
    expect(entries.first.firstWrongAt, isNotNull);
    expect(entries.first.lastWrongAt, isNotNull);
    expect(entries.first.masteredAt, isNull);
  });

  // ═════════════════════════════════════════════════════════════
  // Test 2: markWrong increments timesWrong on existing entry
  // ═════════════════════════════════════════════════════════════
  test('markWrong increments timesWrong on existing entry', () async {
    await _insertQuestion('q2', 'b2');

    // First wrong mark
    await repo.markWrong('q2');
    var entry = await (db.select(db.wrongLedgerEntries)
      ..where((e) => e.questionId.equals('q2'))
    ).getSingle();
    expect(entry.timesWrong, 1);
    final firstWrongAt = entry.firstWrongAt;

    // Second wrong mark
    await repo.markWrong('q2');
    entry = await (db.select(db.wrongLedgerEntries)
      ..where((e) => e.questionId.equals('q2'))
    ).getSingle();
    expect(entry.timesWrong, 2);
    // firstWrongAt should NOT change on subsequent marks
    expect(entry.firstWrongAt, firstWrongAt);
    // lastWrongAt should be updated
    expect(entry.lastWrongAt.isAfter(firstWrongAt!), isTrue);
    expect(entry.masteredAt, isNull);
  });

  // ═════════════════════════════════════════════════════════════
  // Test 3: markMastered sets masteredAt
  // ═════════════════════════════════════════════════════════════
  test('markMastered sets masteredAt on existing entry', () async {
    await _insertQuestion('q3', 'b3');

    // First mark as wrong to create the entry
    await repo.markWrong('q3');

    // Now mark as mastered
    await repo.markMastered('q3');

    final entry = await (db.select(db.wrongLedgerEntries)
      ..where((e) => e.questionId.equals('q3'))
    ).getSingle();
    expect(entry.masteredAt, isNotNull);
  });

  // ═════════════════════════════════════════════════════════════
  // Test 4: recordWrongAnswer inserts attempt + ledger atomically
  // ═════════════════════════════════════════════════════════════
  test('recordWrongAnswer inserts attempt and marks wrong atomically', () async {
    await _insertQuestion('q4', 'b4');

    await repo.recordWrongAnswer(
      questionId: 'q4',
      givenAnswer: ['B'],
      isCorrect: false,
      mode: 'random',
      elapsedMs: 1500,
    );

    // Verify answer attempt was inserted
    final attempts = await db.select(db.answerAttempts).get();
    expect(attempts.length, 1);
    expect(attempts.first.questionId, 'q4');
    expect(attempts.first.givenAnswerJson, '["B"]');
    expect(attempts.first.isCorrect, false);
    expect(attempts.first.mode, 'random');
    expect(attempts.first.elapsedMs, 1500);

    // Verify ledger entry was created
    final entries = await db.select(db.wrongLedgerEntries).get();
    expect(entries.length, 1);
    expect(entries.first.questionId, 'q4');
    expect(entries.first.timesWrong, 1);
  });

  // ═════════════════════════════════════════════════════════════
  // Test 4b: recordWrongAnswer with correct answer does NOT mark wrong
  // ═════════════════════════════════════════════════════════════
  test('recordWrongAnswer with correct answer does not touch ledger', () async {
    await _insertQuestion('q5', 'b5');

    await repo.recordWrongAnswer(
      questionId: 'q5',
      givenAnswer: ['A'],
      isCorrect: true,
      mode: 'random',
      elapsedMs: 800,
    );

    // Answer attempt exists
    final attempts = await db.select(db.answerAttempts).get();
    expect(attempts.length, 1);
    expect(attempts.first.isCorrect, true);

    // Ledger is empty (correct answer, no markWrong)
    final entries = await db.select(db.wrongLedgerEntries).get();
    expect(entries.length, 0);
  });

  // ═════════════════════════════════════════════════════════════
  // Test 5: getActiveCount returns count of unmastered entries
  // ═════════════════════════════════════════════════════════════
  test('getActiveCount returns count where masteredAt IS NULL', () async {
    await _insertQuestion('qA', 'bA');
    await _insertQuestion('qB', 'bB');

    // Mark both wrong
    await repo.markWrong('qA');
    await repo.markWrong('qB');

    expect(await repo.getActiveCount(), 2);

    // Master one
    await repo.markMastered('qA');

    expect(await repo.getActiveCount(), 1);
  });

  // ═════════════════════════════════════════════════════════════
  // Test 6: getActiveByBank returns active wrong count per bankId
  // ═════════════════════════════════════════════════════════════
  test('getActiveByBank returns active wrong count for specific bank', () async {
    await _insertQuestion('qX', 'bankX');
    await _insertQuestion('qY', 'bankY');

    await repo.markWrong('qX');
    await repo.markWrong('qY');

    expect(await repo.getActiveByBank('bankX'), 1);
    expect(await repo.getActiveByBank('bankY'), 1);

    // Master the bankX question
    await repo.markMastered('qX');

    expect(await repo.getActiveByBank('bankX'), 0);
    expect(await repo.getActiveByBank('bankY'), 1);
  });

  // ═════════════════════════════════════════════════════════════
  // Test 7: watchActiveCount emits updated count reactively
  // ═════════════════════════════════════════════════════════════
  test('watchActiveCount emits updated count after mutations', () async {
    await _insertQuestion('qW1', 'bW');
    await _insertQuestion('qW2', 'bW');

    final stream = repo.watchActiveCount();
    final values = <int>[];

    final subscription = stream.listen(values.add);

    // Give the stream a moment to emit the initial value
    await Future<void>.delayed(const Duration(milliseconds: 100));

    // Mark first wrong
    await repo.markWrong('qW1');
    await Future<void>.delayed(const Duration(milliseconds: 100));

    // Mark second wrong
    await repo.markWrong('qW2');
    await Future<void>.delayed(const Duration(milliseconds: 100));

    // Master first
    await repo.markMastered('qW1');
    await Future<void>.delayed(const Duration(milliseconds: 100));

    await subscription.cancel();

    // Should have emitted: 0, 1, 2, 1
    expect(values.length, greaterThanOrEqualTo(2));
    // The stream should have seen the count go up and down
    expect(values.contains(0), isTrue);
    expect(values.contains(2), isTrue);
  });

  // ═════════════════════════════════════════════════════════════
  // Test 8: recordCorrectReview inserts attempt + marks mastered atomically
  // ═════════════════════════════════════════════════════════════
  test('recordCorrectReview inserts attempt and marks mastered atomically', () async {
    await _insertQuestion('qR1', 'bR');

    // First mark wrong to create ledger entry
    await repo.markWrong('qR1');

    // Now record a correct review answer
    await repo.recordCorrectReview(
      questionId: 'qR1',
      givenAnswer: ['A'],
      mode: 'review',
      elapsedMs: 2000,
    );

    // Verify answer attempt was inserted
    final attempts = await db.select(db.answerAttempts).get();
    expect(attempts.length, 1);
    expect(attempts.first.isCorrect, true);
    expect(attempts.first.mode, 'review');

    // Verify ledger entry was marked as mastered
    final entry = await (db.select(db.wrongLedgerEntries)
      ..where((e) => e.questionId.equals('qR1'))
    ).getSingle();
    expect(entry.masteredAt, isNotNull);
  });
}
