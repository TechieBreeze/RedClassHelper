import 'package:freezed_annotation/freezed_annotation.dart';

import '../../data/db/database.dart';
import 'review_mode.dart';

part 'quiz_session_state.freezed.dart';

/// 答题会话状态 -- QuizSessionController 的 state 类型。
@freezed
class QuizSessionState with _$QuizSessionState {
  const factory QuizSessionState({
    required String bankId,
    required ReviewMode mode,
    required List<Question> questions,
    @Default(0) int currentIndex,
    @Default([]) List<AnswerRecord> answers,
    required DateTime startTime,
    @Default(QuizStatus.idle) QuizStatus status,
    String? bankName,
    int? elapsedSeconds,
    int? totalQuestions,
    int? correctCount,
    int? wrongCount,
    int? newlyWrongCount,
    int? newlyMasteredCount,
  }) = _QuizSessionState;

  const QuizSessionState._();

  /// 当前题目，如果所有题目已答完则返回 null。
  Question? get currentQuestion =>
      currentIndex < questions.length ? questions[currentIndex] : null;

  /// 是否已完成所有题目。
  bool get isComplete => currentIndex >= questions.length;
}

/// 单次答题记录 -- 存储在 QuizSessionState.answers 中。
@freezed
class AnswerRecord with _$AnswerRecord {
  const factory AnswerRecord({
    required String questionId,
    required List<String> givenAnswer,
    required bool isCorrect,
    required int elapsedMs,
  }) = _AnswerRecord;
}

/// 答题会话生命周期状态。
enum QuizStatus {
  /// 初始状态，尚未开始。
  idle,

  /// 正在从数据库加载题目。
  loading,

  /// 正在答题中，等待用户选择/提交。
  active,

  /// 已提交答案，正在展示对错反馈（2秒延迟或等待手动翻题）。
  showingFeedback,

  /// 所有题目已完成，准备跳转摘要页。
  complete,

  /// 加载题目或提交答案时发生错误。
  error,
}
