import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/db/database.dart';
import '../models/quiz_session_state.dart';
import '../models/review_mode.dart';

/// 答题会话持久化服务 — 将答题进度保存到 SharedPreferences，
/// 使用户退出或中断后可以恢复上次的答题状态。
class QuizSessionPersistence {
  const QuizSessionPersistence(this._prefs);

  final SharedPreferences _prefs;

  static const _prefix = 'quiz_session_';

  String _key(String bankId, String mode) => '$_prefix${bankId}_$mode';

  /// 保存当前答题会话。
  Future<void> save({
    required String bankId,
    required ReviewMode mode,
    required List<Question> questions,
    required int currentIndex,
    required List<AnswerRecord> answers,
    required DateTime startTime,
    required String? bankName,
  }) async {
    final data = {
      'bankId': bankId,
      'mode': mode.name,
      'questionIds': questions.map((q) => q.id).toList(),
      'currentIndex': currentIndex,
      'answers': answers
          .map((a) => {
                'questionId': a.questionId,
                'givenAnswer': a.givenAnswer,
                'isCorrect': a.isCorrect,
                'elapsedMs': a.elapsedMs,
              })
          .toList(),
      'startTime': startTime.toIso8601String(),
      'bankName': bankName,
    };
    await _prefs.setString(_key(bankId, mode.name), jsonEncode(data));
  }

  /// 加载已保存的答题会话，从数据库重建完整状态。
  ///
  /// 返回 null 表示没有可恢复的会话。
  Future<QuizSessionState?> load({
    required AppDatabase db,
    required String bankId,
    required String modeStr,
  }) async {
    final key = _key(bankId, modeStr);
    final raw = _prefs.getString(key);
    if (raw == null) return null;

    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final savedMode = reviewModeFromString(data['mode'] as String);
      final questionIds =
          (data['questionIds'] as List).cast<String>();
      final currentIndex = data['currentIndex'] as int;

      // 从数据库重建题目列表（保持保存时的顺序）
      final questions = <Question>[];
      for (final id in questionIds) {
        final q = await (db.select(db.questions)
          ..where((q) => q.id.equals(id))
        ).getSingleOrNull();
        if (q != null) questions.add(q);
      }

      if (questions.isEmpty) return null;

      // 重建答案记录
      final answersData = (data['answers'] as List?) ?? [];
      final answers = answersData.map((a) {
        final m = a as Map<String, dynamic>;
        return AnswerRecord(
          questionId: m['questionId'] as String,
          givenAnswer: (m['givenAnswer'] as List).cast<String>(),
          isCorrect: m['isCorrect'] as bool,
          elapsedMs: m['elapsedMs'] as int,
        );
      }).toList();

      // 加载题库名称
      final bank = await (db.select(db.questionBanks)
        ..where((b) => b.id.equals(bankId))
      ).getSingleOrNull();

      final startTime = DateTime.parse(data['startTime'] as String);
      final elapsed = DateTime.now().difference(startTime).inSeconds;
      final correctCount = answers.where((a) => a.isCorrect).length;

      return QuizSessionState(
        bankId: bankId,
        mode: savedMode,
        questions: questions,
        currentIndex: currentIndex,
        answers: answers,
        startTime: startTime,
        status: currentIndex < questions.length
            ? QuizStatus.active
            : QuizStatus.complete,
        bankName: bank?.name ?? data['bankName'] as String? ?? '',
        totalQuestions: questions.length,
        correctCount: correctCount,
        wrongCount: answers.length - correctCount,
        elapsedSeconds: elapsed,
      );
    } catch (_) {
      // 损坏的保存数据 — 清除并返回 null
      await _prefs.remove(key);
      return null;
    }
  }

  /// 清除指定会话的保存状态。
  Future<void> clear(String bankId, String mode) async {
    await _prefs.remove(_key(bankId, mode));
  }
}
