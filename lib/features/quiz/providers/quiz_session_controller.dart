import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/db/database.dart';
import '../../../data/repositories/ledger_repository.dart';
import '../models/quiz_session_state.dart';
import '../models/review_mode.dart';
import 'quiz_session_persistence.dart';
import 'quiz_settings_provider.dart';
import 'wrong_questions_provider.dart';

part 'quiz_session_controller.g.dart';

/// 答题会话控制器 — 管理整个答题生命周期 (D-01 ~ D-06, D-16, D-17)。
///
/// 拥有题目队列、当前索引、已提交答案、耗时统计和自动翻题计时器。
/// 所有 DB 写入委托给 [LedgerRepository] 以保证原子性 (D-16)。
///
/// 支持会话持久化：答题过程中自动保存进度到 SharedPreferences，
/// 退出后再次进入可恢复上次的答题状态。
@riverpod
class QuizSessionController extends _$QuizSessionController {
  Timer? _autoAdvanceTimer;
  LedgerRepository? _ledgerRepo;
  QuizSessionPersistence? _persistence;
  final _random = Random();

  /// 已保存但尚未使用的会话数据（用于触发恢复对话框）。
  QuizSessionState? pendingResumeSession;

  @override
  Future<QuizSessionState> build(String bankId, String modeStr) async {
    final mode = reviewModeFromString(modeStr);
    final db = await ref.watch(appDatabaseProvider.future);
    _ledgerRepo = LedgerRepository(db);
    final prefs = ref.read(sharedPreferencesProvider);
    _persistence = QuizSessionPersistence(prefs);

    // 尝试加载已保存的会话
    final saved = await _persistence!.load(
      db: db,
      bankId: bankId,
      modeStr: modeStr,
    );

    if (saved != null &&
        saved.status == QuizStatus.active &&
        saved.questions.isNotEmpty) {
      // 有待恢复的会话 — 暂存到 pendingResumeSession，
      // 由 QuizScreen 显示恢复对话框后再决定是否使用。
      pendingResumeSession = saved;
    }

    // Load bank name
    final bank = await (db.select(db.questionBanks)
      ..where((b) => b.id.equals(bankId))
    ).getSingleOrNull();

    if (bank == null) {
      return QuizSessionState(
        bankId: bankId,
        mode: mode,
        questions: const [],
        startTime: DateTime.now(),
        status: QuizStatus.error,
        bankName: '题库不存在',
      );
    }

    // Load questions based on mode
    final List<Question> questions;
    switch (mode) {
      case ReviewMode.random:
        questions = await _loadRandomQuestions(db, bankId);
      case ReviewMode.review:
        questions = await _loadReviewQuestions(db, bankId);
      case ReviewMode.spotcheck:
        questions = await _loadSpotcheckQuestions(db, bankId);
    }

    // Shuffle using Fisher-Yates (dart:math)
    questions.shuffle(_random);

    if (questions.isEmpty) {
      // 空题库 — 清除可能存在的旧会话
      await _persistence!.clear(bankId, mode.name);
      return QuizSessionState(
        bankId: bankId,
        mode: mode,
        questions: const [],
        startTime: DateTime.now(),
        status: QuizStatus.complete,
        bankName: bank.name,
        totalQuestions: 0,
        correctCount: 0,
        wrongCount: 0,
        newlyWrongCount: 0,
        newlyMasteredCount: 0,
        elapsedSeconds: 0,
      );
    }

    return QuizSessionState(
      bankId: bankId,
      mode: mode,
      questions: questions,
      currentIndex: 0,
      answers: const [],
      startTime: DateTime.now(),
      status: QuizStatus.active,
      bankName: bank.name,
    );
  }

  /// 使用已保存的会话恢复答题进度。
  void resumeSavedSession() {
    final saved = pendingResumeSession;
    if (saved == null) return;
    pendingResumeSession = null;
    state = AsyncData(saved);
  }

  /// 丢弃已保存的会话，从头开始答题。
  Future<void> discardSavedSession() async {
    final current = state.value;
    pendingResumeSession = null;
    if (current != null && _persistence != null) {
      await _persistence!.clear(current.bankId, current.mode.name);
    }
  }

  Future<List<Question>> _loadRandomQuestions(
    AppDatabase db,
    String bankId,
  ) async {
    // REV-01: Load ALL questions from bank
    return (db.select(db.questions)
      ..where((q) => q.bankId.equals(bankId))
    ).get();
  }

  Future<List<Question>> _loadReviewQuestions(
    AppDatabase db,
    String bankId,
  ) async {
    // REV-03: JOIN Questions + WrongLedgerEntries WHERE masteredAt IS NULL
    final query = db.select(db.questions).join([
      innerJoin(
        db.wrongLedgerEntries,
        db.wrongLedgerEntries.questionId.equalsExp(db.questions.id),
      ),
    ]);
    query
      ..where(db.questions.bankId.equals(bankId))
      ..where(db.wrongLedgerEntries.masteredAt.isNull());
    final rows = await query.get();
    return rows.map((row) => row.readTable(db.questions)).toList();
  }

  Future<List<Question>> _loadSpotcheckQuestions(
    AppDatabase db,
    String bankId,
  ) async {
    // REV-05, REV-06: Sample up to 10 from active ledger, exclude mastered
    final questions = await _loadReviewQuestions(db, bankId);
    questions.shuffle(_random);
    return questions.take(10).toList();
  }

  /// D-02, D-04: Submit the selected option(s) and grade them.
  Future<void> submitAnswer(List<String> optionKeys) async {
    final current = state.value;
    if (current == null || current.isComplete) return;
    if (current.status != QuizStatus.active) return;

    final question = current.currentQuestion!;
    final submitStart = DateTime.now();
    final elapsedMs =
        submitStart.difference(current.startTime).inMilliseconds;

    final correctKeys = List<String>.from(
      jsonDecode(question.correctJson) as List,
    );
    final isMultiChoice = correctKeys.length > 1;
    final isCorrect = isMultiChoice
        ? _gradeMultiChoice(correctKeys, optionKeys)
        : _gradeSingleChoice(correctKeys, optionKeys);

    // Create answer record
    final record = AnswerRecord(
      questionId: question.id,
      givenAnswer: optionKeys,
      isCorrect: isCorrect,
      elapsedMs: elapsedMs,
    );

    // Determine ledger action based on mode + correctness (D-16, STAT-01)
    final modeStr = current.mode == ReviewMode.random
        ? 'random'
        : current.mode == ReviewMode.review
            ? 'review'
            : 'spotcheck';

    if (isCorrect && current.mode == ReviewMode.review) {
      // REV-04: Correct in review mode → mark as mastered
      await _ledgerRepo!.recordCorrectReview(
        questionId: question.id,
        givenAnswer: optionKeys,
        mode: modeStr,
        elapsedMs: elapsedMs,
      );
    } else if (!isCorrect && current.mode != ReviewMode.spotcheck) {
      // REV-02: Wrong in random/review → add to ledger
      await _ledgerRepo!.recordWrongAnswer(
        questionId: question.id,
        givenAnswer: optionKeys,
        isCorrect: false,
        mode: modeStr,
        elapsedMs: elapsedMs,
      );
    } else {
      // STAT-01: Record attempt without ledger change
      final db = await ref.read(appDatabaseProvider.future);
      await db.into(db.answerAttempts).insert(
        AnswerAttemptsCompanion.insert(
          questionId: question.id,
          givenAnswerJson: jsonEncode(optionKeys),
          isCorrect: isCorrect,
          mode: modeStr,
          elapsedMs: elapsedMs,
          createdAt: DateTime.now(),
        ),
      );
    }

    // Count new wrongs for summary
    final newlyWrong =
        (!isCorrect && current.mode != ReviewMode.spotcheck) ? 1 : 0;
    final newlyMastered =
        (isCorrect && current.mode == ReviewMode.review) ? 1 : 0;

    final updatedAnswers = [...current.answers, record];
    final correctCount = updatedAnswers.where((a) => a.isCorrect).length;
    final wrongCount = updatedAnswers.length - correctCount;

    state = AsyncData(current.copyWith(
      answers: updatedAnswers,
      correctCount: correctCount,
      wrongCount: wrongCount,
      newlyWrongCount: (current.newlyWrongCount ?? 0) + newlyWrong,
      newlyMasteredCount: (current.newlyMasteredCount ?? 0) + newlyMastered,
      status: QuizStatus.showingFeedback,
    ));

    // 保存进度到持久化存储
    await _saveSession();

    // Invalidate wrongQuestionsProvider so badge updates reactively
    ref.invalidate(wrongQuestionsProvider);
  }

  /// Go back to the previous question.
  void goToPrevious() {
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = null;

    final current = state.value;
    if (current == null) return;
    if (current.currentIndex <= 0) return;

    state = AsyncData(current.copyWith(
      currentIndex: current.currentIndex - 1,
      status: QuizStatus.showingFeedback,
    ));
  }

  /// D-03: Advance to the next question.
  void advanceToNext() {
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = null;

    final current = state.value;
    if (current == null) return;

    final nextIndex = current.currentIndex + 1;

    if (nextIndex >= current.questions.length) {
      // All questions answered — compute summary
      final elapsed = DateTime.now().difference(current.startTime);
      state = AsyncData(current.copyWith(
        status: QuizStatus.complete,
        elapsedSeconds: elapsed.inSeconds,
        totalQuestions: current.questions.length,
      ));
      // 清除已保存的会话（已完成，无需恢复）
      _persistence?.clear(current.bankId, current.mode.name);
    } else {
      final alreadyAnswered = nextIndex < current.answers.length;
      state = AsyncData(current.copyWith(
        currentIndex: nextIndex,
        status: alreadyAnswered
            ? QuizStatus.showingFeedback
            : QuizStatus.active,
      ));
      // 保存进度
      _saveSession();
    }
  }

  /// D-03: Start the 2-second auto-advance timer.
  void startAutoAdvance() {
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = Timer(const Duration(seconds: 2), () {
      advanceToNext();
    });
  }

  /// Cancel the auto-advance timer (manual advance, navigate away).
  void cancelAutoAdvance() {
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = null;
  }

  /// 将当前会话状态保存到持久化存储。
  Future<void> _saveSession() async {
    final current = state.value;
    if (current == null || _persistence == null) return;
    if (current.isComplete) return;

    await _persistence!.save(
      bankId: current.bankId,
      mode: current.mode,
      questions: current.questions,
      currentIndex: current.currentIndex,
      answers: current.answers,
      startTime: current.startTime,
      bankName: current.bankName,
    );
  }

  /// Single-choice grading (RESEARCH Pattern 5).
  bool _gradeSingleChoice(List<String> correctKeys, List<String> givenKeys) {
    if (correctKeys.isEmpty || givenKeys.isEmpty) return false;
    if (correctKeys.length != 1 || givenKeys.length != 1) return false;
    return correctKeys.first == givenKeys.first;
  }

  /// Multi-choice grading: exact match required.
  /// User must select ALL correct options and NO wrong options.
  bool _gradeMultiChoice(List<String> correctKeys, List<String> givenKeys) {
    if (correctKeys.isEmpty || givenKeys.isEmpty) return false;
    final correctSet = correctKeys.toSet();
    final givenSet = givenKeys.toSet();
    return correctSet.length == givenSet.length &&
        correctSet.containsAll(givenSet);
  }
}
