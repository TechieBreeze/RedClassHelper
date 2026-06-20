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

    await controller.submitAnswer('A');

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

    await controller.submitAnswer('B');

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

    await controller.submitAnswer('A');

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
    await controller.submitAnswer('A');

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

    await controller2.submitAnswer('B');

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
    await controller.submitAnswer('B');
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
}
