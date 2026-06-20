import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

import 'package:redclass/data/db/database.dart';
import 'package:redclass/features/quiz/models/quiz_session_state.dart';
import 'package:redclass/features/quiz/providers/quiz_session_controller.dart';

/// Helper: Insert a QuestionBank + Question so FK constraints pass.
Future<void> _insertQuestion({
  required AppDatabase db,
  required String questionId,
  required String bankId,
  required String correctKey,
  String stem = 'Test question?',
}) async {
  final now = DateTime.now();
  // Only insert bank if it doesn't already exist (test may share bankId)
  final existing = await (db.select(db.questionBanks)
    ..where((b) => b.id.equals(bankId))
  ).getSingleOrNull();
  if (existing == null) {
    await db.into(db.questionBanks).insert(
      QuestionBanksCompanion.insert(
        id: bankId,
        name: 'Test Bank $bankId',
        source: 'test',
        questionCount: 1,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
  await db.into(db.questions).insert(
    QuestionsCompanion.insert(
      id: questionId,
      bankId: bankId,
      type: 'single',
      stem: stem,
      optionsJson:
          '[{"key":"A","text":"Option A"},{"key":"B","text":"Option B"}]',
      correctJson: '["$correctKey"]',
      rawText: stem,
      createdAt: now,
    ),
  );
}

/// Helper: Insert a WrongLedgerEntry for a question.
Future<void> _insertWrongEntry({
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

/// Helper: Insert a multi-choice Question with given correct keys and type.
Future<void> _insertMultiChoiceQuestion({
  required AppDatabase db,
  required String questionId,
  required String bankId,
  required List<String> correctKeys,
  String stem = 'Multi-choice test question?',
}) async {
  final now = DateTime.now();
  final existing = await (db.select(db.questionBanks)
    ..where((b) => b.id.equals(bankId))
  ).getSingleOrNull();
  if (existing == null) {
    await db.into(db.questionBanks).insert(
      QuestionBanksCompanion.insert(
        id: bankId,
        name: 'Test Bank $bankId',
        source: 'test',
        questionCount: 1,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
  // Build options for keys A through D
  final optionsList = ['A', 'B', 'C', 'D'].map((k) => {
    'key': k,
    'text': '选项$k',
  }).toList();
  await db.into(db.questions).insert(
    QuestionsCompanion.insert(
      id: questionId,
      bankId: bankId,
      type: 'multiple',
      stem: stem,
      optionsJson: jsonEncode(optionsList),
      correctJson: jsonEncode(correctKeys),
      rawText: stem,
      createdAt: now,
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

  setUp(() async {
    db = AppDatabase.openInMemoryDatabase();
  });

  tearDown(() async => await db.close());

  // ═════════════════════════════════════════════════════════════
  // Test 1: build() in random mode loads all questions, shuffles
  // ═════════════════════════════════════════════════════════════
  test('build() in random mode loads all questions from bank and shuffles',
      () async {
    await _insertQuestion(
      db: db, questionId: 'q1', bankId: 'b1', correctKey: 'A');
    await _insertQuestion(
      db: db, questionId: 'q2', bankId: 'b1', correctKey: 'B');
    await _insertQuestion(
      db: db, questionId: 'q3', bankId: 'b1', correctKey: 'A');

    final container = _createContainer(db);
    addTearDown(container.dispose);

    final state = await container
        .read(quizSessionControllerProvider('b1', 'random').future);

    expect(state.questions.length, 3);
    expect(state.status, QuizStatus.active);
    expect(state.bankId, 'b1');
    expect(state.mode.name, 'random');
    expect(state.bankName, 'Test Bank b1');
    expect(state.currentIndex, 0);
    expect(state.answers, isEmpty);
  });

  // ═════════════════════════════════════════════════════════════
  // Test 2: build() in review mode loads only active ledger questions
  // ═════════════════════════════════════════════════════════════
  test(
      'build() in review mode loads only questions from '
      'WrongLedgerEntries WHERE masteredAt IS NULL', () async {
    await _insertQuestion(
      db: db, questionId: 'q1', bankId: 'b1', correctKey: 'A');
    await _insertQuestion(
      db: db, questionId: 'q2', bankId: 'b1', correctKey: 'B');
    await _insertQuestion(
      db: db, questionId: 'q3', bankId: 'b1', correctKey: 'A');
    await _insertWrongEntry(db: db, questionId: 'q1');
    await _insertWrongEntry(db: db, questionId: 'q3');

    final container = _createContainer(db);
    addTearDown(container.dispose);

    final state = await container
        .read(quizSessionControllerProvider('b1', 'review').future);

    expect(state.questions.length, 2);
    final ids = state.questions.map((q) => q.id).toSet();
    expect(ids, contains('q1'));
    expect(ids, contains('q3'));
    expect(ids, isNot(contains('q2')));
    expect(state.status, QuizStatus.active);
  });

  // ═════════════════════════════════════════════════════════════
  // Test 3: build() in spotcheck mode loads at most 10
  // ═════════════════════════════════════════════════════════════
  test('build() in spotcheck mode loads at most 10 from active ledger',
      () async {
    for (var i = 0; i < 15; i++) {
      await _insertQuestion(
        db: db,
        questionId: 'qs$i',
        bankId: 'b1',
        correctKey: 'A',
        stem: 'Question $i',
      );
      await _insertWrongEntry(db: db, questionId: 'qs$i');
    }

    final container = _createContainer(db);
    addTearDown(container.dispose);

    final state = await container
        .read(quizSessionControllerProvider('b1', 'spotcheck').future);

    expect(state.questions.length, 10);
    expect(state.status, QuizStatus.active);
  });

  // ═════════════════════════════════════════════════════════════
  // Test 4: submitAnswer() with correct option
  // ═════════════════════════════════════════════════════════════
  test('submitAnswer() with correct option: status becomes showingFeedback',
      () async {
    await _insertQuestion(
      db: db, questionId: 'q1', bankId: 'b1', correctKey: 'A');

    final container = _createContainer(db);
    addTearDown(container.dispose);

    final controller =
        container.read(quizSessionControllerProvider('b1', 'random').notifier);
    await container
        .read(quizSessionControllerProvider('b1', 'random').future);

    await controller.submitAnswer(['A']);

    final state = container
        .read(quizSessionControllerProvider('b1', 'random'))
        .value!;
    expect(state.status, QuizStatus.showingFeedback);
    expect(state.answers.length, 1);
    expect(state.answers.first.isCorrect, true);
    expect(state.answers.first.givenAnswer, ['A']);
    expect(state.correctCount, 1);
    expect(state.wrongCount, 0);
  });

  // ═════════════════════════════════════════════════════════════
  // Test 5: submitAnswer() with incorrect option in random mode
  // ═════════════════════════════════════════════════════════════
  test(
      'submitAnswer() incorrect in random mode: '
      'wrongCount increments, ledger written', () async {
    await _insertQuestion(
      db: db, questionId: 'q1', bankId: 'b1', correctKey: 'A');

    final container = _createContainer(db);
    addTearDown(container.dispose);

    final controller =
        container.read(quizSessionControllerProvider('b1', 'random').notifier);
    await container
        .read(quizSessionControllerProvider('b1', 'random').future);

    await controller.submitAnswer(['B']);

    final state = container
        .read(quizSessionControllerProvider('b1', 'random'))
        .value!;
    expect(state.status, QuizStatus.showingFeedback);
    expect(state.answers.first.isCorrect, false);
    expect(state.wrongCount, 1);
    expect(state.newlyWrongCount, 1);

    // Verify ledger was written
    final entries = await db.select(db.wrongLedgerEntries).get();
    expect(entries.length, 1);
    expect(entries.first.questionId, 'q1');
    expect(entries.first.timesWrong, 1);
    expect(entries.first.masteredAt, isNull);

    // Verify answer attempt was recorded (STAT-01)
    final attempts = await db.select(db.answerAttempts).get();
    expect(attempts.length, 1);
    expect(attempts.first.questionId, 'q1');
    expect(attempts.first.isCorrect, false);
    expect(attempts.first.mode, 'random');
    expect(attempts.first.elapsedMs, greaterThanOrEqualTo(0));
  });

  // ═════════════════════════════════════════════════════════════
  // Test 6: submitAnswer() correct in review → markMastered
  // ═════════════════════════════════════════════════════════════
  test('submitAnswer() correct in review mode calls recordCorrectReview',
      () async {
    await _insertQuestion(
      db: db, questionId: 'q1', bankId: 'b1', correctKey: 'A');
    await _insertWrongEntry(db: db, questionId: 'q1');

    final container = _createContainer(db);
    addTearDown(container.dispose);

    final controller =
        container.read(quizSessionControllerProvider('b1', 'review').notifier);
    await container
        .read(quizSessionControllerProvider('b1', 'review').future);

    await controller.submitAnswer(['A']);

    final state = container
        .read(quizSessionControllerProvider('b1', 'review'))
        .value!;
    expect(state.answers.first.isCorrect, true);
    expect(state.newlyMasteredCount, 1);

    // Verify ledger entry was marked as mastered
    final entry = await (db.select(db.wrongLedgerEntries)
      ..where((e) => e.questionId.equals('q1'))
    ).getSingle();
    expect(entry.masteredAt, isNotNull);
  });

  // ═════════════════════════════════════════════════════════════
  // Test 7: submitAnswer() in spotcheck never mutates ledger
  // ═════════════════════════════════════════════════════════════
  test('submitAnswer() in spotcheck mode never calls markWrong or markMastered',
      () async {
    await _insertQuestion(
      db: db, questionId: 'q1', bankId: 'b1', correctKey: 'A');
    await _insertWrongEntry(db: db, questionId: 'q1');

    final container = _createContainer(db);
    addTearDown(container.dispose);

    final controller = container
        .read(quizSessionControllerProvider('b1', 'spotcheck').notifier);
    await container
        .read(quizSessionControllerProvider('b1', 'spotcheck').future);

    // Submit correct answer in spotcheck
    await controller.submitAnswer(['A']);

    // The ledger entry should NOT be mastered (spotcheck doesn't modify)
    final entry = await (db.select(db.wrongLedgerEntries)
      ..where((e) => e.questionId.equals('q1'))
    ).getSingle();
    expect(entry.masteredAt, isNull);

    // Submit wrong answer in spotcheck (create new question)
    await _insertQuestion(
      db: db, questionId: 'q2', bankId: 'b1', correctKey: 'A');
    await _insertWrongEntry(db: db, questionId: 'q2');

    // Build a new session for q2
    final container2 = _createContainer(db);
    addTearDown(container2.dispose);

    final controller2 = container2
        .read(quizSessionControllerProvider('b1', 'spotcheck').notifier);
    await container2
        .read(quizSessionControllerProvider('b1', 'spotcheck').future);

    await controller2.submitAnswer(['B']);

    // newWrongCount should be 0 for spotcheck
    final state2 = container2
        .read(quizSessionControllerProvider('b1', 'spotcheck'))
        .value!;
    expect(state2.newlyWrongCount, 0);

    // But answer attempt should still be recorded (STAT-01)
    final attempts = await db.select(db.answerAttempts).get();
    expect(attempts.length, greaterThanOrEqualTo(2));
  });

  // ═════════════════════════════════════════════════════════════
  // Test 8: advanceToNext()
  // ═════════════════════════════════════════════════════════════
  test('advanceToNext() increments currentIndex and detects completion',
      () async {
    await _insertQuestion(
      db: db, questionId: 'q1', bankId: 'b1', correctKey: 'A');
    await _insertQuestion(
      db: db, questionId: 'q2', bankId: 'b1', correctKey: 'B');

    final container = _createContainer(db);
    addTearDown(container.dispose);

    final controller =
        container.read(quizSessionControllerProvider('b1', 'random').notifier);
    await container
        .read(quizSessionControllerProvider('b1', 'random').future);

    // Advance from q1 (index 0) to q2 (index 1)
    controller.advanceToNext();

    var state = container
        .read(quizSessionControllerProvider('b1', 'random'))
        .value!;
    expect(state.currentIndex, 1);
    expect(state.status, QuizStatus.active);

    // Advance from q2 (index 1) → complete (index 2 == questions.length)
    controller.advanceToNext();

    state = container
        .read(quizSessionControllerProvider('b1', 'random'))
        .value!;
    expect(state.status, QuizStatus.complete);
    expect(state.totalQuestions, 2);
    expect(state.elapsedSeconds, isNotNull);
  });

  // ═════════════════════════════════════════════════════════════
  // Test 9: Invalid mode string throws clear error
  // ═════════════════════════════════════════════════════════════
  test('build() with invalid mode string throws ArgumentError', () async {
    await _insertQuestion(
      db: db, questionId: 'q1', bankId: 'b1', correctKey: 'A');

    final container = _createContainer(db);
    addTearDown(container.dispose);

    expect(
      () => container
          .read(quizSessionControllerProvider('b1', 'rando').future),
      throwsA(isA<ArgumentError>()),
    );
  });

  // ═════════════════════════════════════════════════════════════
  // Test 10: Empty question list → status complete immediately
  // ═════════════════════════════════════════════════════════════
  test('Empty question list sets status to complete immediately', () async {
    final now = DateTime.now();
    await db.into(db.questionBanks).insert(
      QuestionBanksCompanion.insert(
        id: 'emptyBank',
        name: 'Empty Bank',
        source: 'test',
        questionCount: 0,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final container = _createContainer(db);
    addTearDown(container.dispose);

    final state = await container
        .read(quizSessionControllerProvider('emptyBank', 'random').future);

    expect(state.status, QuizStatus.complete);
    expect(state.questions, isEmpty);
    expect(state.totalQuestions, 0);
    expect(state.correctCount, 0);
    expect(state.wrongCount, 0);
  });

  // ═════════════════════════════════════════════════════════════
  // Test 11: build() with non-existent bank returns error status
  // ═════════════════════════════════════════════════════════════
  test('build() with non-existent bankId returns error status', () async {
    final container = _createContainer(db);
    addTearDown(container.dispose);

    final state = await container
        .read(quizSessionControllerProvider('nonexistent', 'random').future);

    expect(state.status, QuizStatus.error);
    expect(state.bankName, '题库不存在');
    expect(state.questions, isEmpty);
  });

  // ═════════════════════════════════════════════════════════════
  // Test 12: submitAnswer() does nothing when status is not active
  // ═════════════════════════════════════════════════════════════
  test('submitAnswer() is a no-op when status is complete', () async {
    await _insertQuestion(
      db: db, questionId: 'q1', bankId: 'b1', correctKey: 'A');

    final container = _createContainer(db);
    addTearDown(container.dispose);

    final controller =
        container.read(quizSessionControllerProvider('b1', 'random').notifier);
    await container
        .read(quizSessionControllerProvider('b1', 'random').future);

    // Advance past the only question → complete
    controller.advanceToNext();

    // Try submitting after completion → should be no-op
    await controller.submitAnswer(['B']);
    final state = container
        .read(quizSessionControllerProvider('b1', 'random'))
        .value!;
    expect(state.answers, isEmpty); // No answer recorded
  });

  // ═════════════════════════════════════════════════════════════
  // Test 13: Review mode excludes mastered questions
  // ═════════════════════════════════════════════════════════════
  test('review mode excludes questions where masteredAt IS NOT NULL', () async {
    await _insertQuestion(
      db: db, questionId: 'q1', bankId: 'b1', correctKey: 'A');
    await _insertQuestion(
      db: db, questionId: 'q2', bankId: 'b1', correctKey: 'B');
    await _insertWrongEntry(db: db, questionId: 'q1', mastered: true);
    await _insertWrongEntry(db: db, questionId: 'q2');

    final container = _createContainer(db);
    addTearDown(container.dispose);

    final state = await container
        .read(quizSessionControllerProvider('b1', 'review').future);

    expect(state.questions.length, 1);
    expect(state.questions.first.id, 'q2');
  });

  // ═════════════════════════════════════════════════════════════
  // Test 14: spotcheck with fewer than 10 active returns that many
  // ═════════════════════════════════════════════════════════════
  test('spotcheck returns min(10, activeCount) questions', () async {
    for (var i = 0; i < 3; i++) {
      await _insertQuestion(
        db: db,
        questionId: 'qs$i',
        bankId: 'b1',
        correctKey: 'A',
        stem: 'Question $i',
      );
      await _insertWrongEntry(db: db, questionId: 'qs$i');
    }

    final container = _createContainer(db);
    addTearDown(container.dispose);

    final state = await container
        .read(quizSessionControllerProvider('b1', 'spotcheck').future);

    expect(state.questions.length, 3); // min(10, 3) = 3
  });

  // ═════════════════════════════════════════════════════════════
  // Test 15: Timer created by startAutoAdvance is cancelled by advanceToNext
  // ═════════════════════════════════════════════════════════════
  test('startAutoAdvance + cancelAutoAdvance do not crash', () async {
    await _insertQuestion(
      db: db, questionId: 'q1', bankId: 'b1', correctKey: 'A');
    await _insertQuestion(
      db: db, questionId: 'q2', bankId: 'b1', correctKey: 'B');

    final container = _createContainer(db);
    addTearDown(container.dispose);

    final controller =
        container.read(quizSessionControllerProvider('b1', 'random').notifier);
    await container
        .read(quizSessionControllerProvider('b1', 'random').future);

    controller.startAutoAdvance();
    controller.advanceToNext();

    var state = container
        .read(quizSessionControllerProvider('b1', 'random'))
        .value!;
    expect(state.currentIndex, 1);

    // Cancel auto-advance should not crash
    controller.cancelAutoAdvance();
  });

  // ═════════════════════════════════════════════════════════════
  // Test 16: Multi-choice exact match with all correct options
  // ═════════════════════════════════════════════════════════════
  test(
      'multi-choice exact match: selecting all correct options '
      'scores correct', () async {
    await _insertMultiChoiceQuestion(
        db: db, questionId: 'mq1', bankId: 'bM1', correctKeys: ['A', 'C']);
    final container = _createContainer(db);
    addTearDown(container.dispose);
    final controller =
        container.read(quizSessionControllerProvider('bM1', 'random').notifier);
    await container
        .read(quizSessionControllerProvider('bM1', 'random').future);
    await controller.submitAnswer(['A', 'C']);
    final state = container
        .read(quizSessionControllerProvider('bM1', 'random'))
        .value!;
    expect(state.answers.first.isCorrect, true);
    expect(state.correctCount, 1);
    expect(state.wrongCount, 0);
  });

  // ═════════════════════════════════════════════════════════════
  // Test 17: Multi-choice — subset of correct = incorrect
  // ═════════════════════════════════════════════════════════════
  test(
      'multi-choice exact match: selecting only a subset of '
      'correct options scores incorrect', () async {
    await _insertMultiChoiceQuestion(
        db: db, questionId: 'mq2', bankId: 'bM2', correctKeys: ['A', 'C', 'D']);
    final container = _createContainer(db);
    addTearDown(container.dispose);
    final controller =
        container.read(quizSessionControllerProvider('bM2', 'random').notifier);
    await container
        .read(quizSessionControllerProvider('bM2', 'random').future);
    await controller.submitAnswer(['A', 'C']); // Missing 'D'
    final state = container
        .read(quizSessionControllerProvider('bM2', 'random'))
        .value!;
    expect(state.answers.first.isCorrect, false);
    expect(state.wrongCount, 1);
  });

  // ═════════════════════════════════════════════════════════════
  // Test 18: Multi-choice — correct + extra wrong = incorrect
  // ═════════════════════════════════════════════════════════════
  test(
      'multi-choice exact match: selecting correct options plus '
      'an extra scores incorrect', () async {
    await _insertMultiChoiceQuestion(
        db: db, questionId: 'mq3', bankId: 'bM3', correctKeys: ['A', 'C']);
    final container = _createContainer(db);
    addTearDown(container.dispose);
    final controller =
        container.read(quizSessionControllerProvider('bM3', 'random').notifier);
    await container
        .read(quizSessionControllerProvider('bM3', 'random').future);
    await controller.submitAnswer(['A', 'C', 'D']); // Extra 'D'
    final state = container
        .read(quizSessionControllerProvider('bM3', 'random'))
        .value!;
    expect(state.answers.first.isCorrect, false);
    expect(state.wrongCount, 1);
  });

  // ═════════════════════════════════════════════════════════════
  // Test 19: Multi-choice — completely wrong = incorrect
  // ═════════════════════════════════════════════════════════════
  test(
      'multi-choice exact match: selecting none of the correct '
      'options scores incorrect', () async {
    await _insertMultiChoiceQuestion(
        db: db, questionId: 'mq4', bankId: 'bM4', correctKeys: ['A', 'C']);
    final container = _createContainer(db);
    addTearDown(container.dispose);
    final controller =
        container.read(quizSessionControllerProvider('bM4', 'random').notifier);
    await container
        .read(quizSessionControllerProvider('bM4', 'random').future);
    await controller.submitAnswer(['B', 'D']);
    final state = container
        .read(quizSessionControllerProvider('bM4', 'random'))
        .value!;
    expect(state.answers.first.isCorrect, false);
    expect(state.wrongCount, 1);
  });

  // ═════════════════════════════════════════════════════════════
  // Test 20: Multi-choice wrong → ledger entry created
  // ═════════════════════════════════════════════════════════════
  test(
      'multi-choice wrong answer in random mode adds to '
      'wrong-question ledger', () async {
    await _insertMultiChoiceQuestion(
        db: db, questionId: 'mq5', bankId: 'bM5', correctKeys: ['A', 'C']);
    final container = _createContainer(db);
    addTearDown(container.dispose);
    final controller =
        container.read(quizSessionControllerProvider('bM5', 'random').notifier);
    await container
        .read(quizSessionControllerProvider('bM5', 'random').future);
    await controller.submitAnswer(['A']); // Only 1 of 2 correct → wrong
    final state = container
        .read(quizSessionControllerProvider('bM5', 'random'))
        .value!;
    expect(state.answers.first.isCorrect, false);
    expect(state.newlyWrongCount, 1);
    // Verify ledger entry was created
    final entries = await db.select(db.wrongLedgerEntries).get();
    expect(entries.length, 1);
    expect(entries.first.questionId, 'mq5');
  });

  // ═════════════════════════════════════════════════════════════
  // Test 21: Multi-choice answer attempt records given selection
  // ═════════════════════════════════════════════════════════════
  test(
      'multi-choice answer stores given selection as JSON array '
      'in answer_attempts', () async {
    await _insertMultiChoiceQuestion(
        db: db, questionId: 'mq6', bankId: 'bM6', correctKeys: ['A', 'B', 'C']);
    final container = _createContainer(db);
    addTearDown(container.dispose);
    final controller =
        container.read(quizSessionControllerProvider('bM6', 'random').notifier);
    await container
        .read(quizSessionControllerProvider('bM6', 'random').future);
    await controller.submitAnswer(['A', 'C']);
    // Verify answer_attempts record
    final attempts = await db.select(db.answerAttempts).get();
    expect(attempts.length, 1);
    expect(attempts.first.questionId, 'mq6');
    expect(attempts.first.isCorrect, false);
    expect(attempts.first.mode, 'random');
    // givenAnswerJson should be '["A","C"]'
    final givenJson = jsonDecode(attempts.first.givenAnswerJson) as List;
    expect(givenJson, containsAll(['A', 'C']));
    expect(givenJson.length, 2);
  });

  // ═════════════════════════════════════════════════════════════
  // Test 22: Multi-choice correct in review mode marks as mastered
  // ═════════════════════════════════════════════════════════════
  test(
      'multi-choice correct answer in review mode marks question '
      'as mastered', () async {
    await _insertMultiChoiceQuestion(
        db: db, questionId: 'mq7', bankId: 'bM7', correctKeys: ['A', 'B', 'D']);
    await _insertWrongEntry(db: db, questionId: 'mq7');
    final container = _createContainer(db);
    addTearDown(container.dispose);
    final controller =
        container.read(quizSessionControllerProvider('bM7', 'review').notifier);
    await container
        .read(quizSessionControllerProvider('bM7', 'review').future);
    await controller.submitAnswer(['A', 'B', 'D']);
    final state = container
        .read(quizSessionControllerProvider('bM7', 'review'))
        .value!;
    expect(state.answers.first.isCorrect, true);
    expect(state.newlyMasteredCount, 1);
    // Verify masteredAt is set
    final entry = await (db.select(db.wrongLedgerEntries)
      ..where((e) => e.questionId.equals('mq7'))
    ).getSingle();
    expect(entry.masteredAt, isNotNull);
  });

  // ═════════════════════════════════════════════════════════════
  // Test 23: Multi-choice — empty selection = incorrect
  // ═════════════════════════════════════════════════════════════
  test('multi-choice: submitting empty selection scores incorrect', () async {
    await _insertMultiChoiceQuestion(
        db: db, questionId: 'mq8', bankId: 'bM8', correctKeys: ['A', 'C']);
    final container = _createContainer(db);
    addTearDown(container.dispose);
    final controller =
        container.read(quizSessionControllerProvider('bM8', 'random').notifier);
    await container
        .read(quizSessionControllerProvider('bM8', 'random').future);
    await controller.submitAnswer([]);
    final state = container
        .read(quizSessionControllerProvider('bM8', 'random'))
        .value!;
    expect(state.answers.first.isCorrect, false);
    expect(state.wrongCount, 1);
  });
}
