// lib/data/db/tables/answer_attempts.dart (D-10)
// ── 答题记录表 ── 每次作答一行 ──

import 'package:drift/drift.dart';
import 'questions.dart';

/// 单次答题记录
@DataClassName('AnswerAttempt')
class AnswerAttempts extends Table {
  /// 自增主键
  IntColumn get id => integer().autoIncrement()();

  /// 关联题目 FK（题目删除时级联删除记录）
  TextColumn get questionId => text()
      .named('question_id')
      .references(Questions, #id, onDelete: KeyAction.cascade)();

  /// 用户提交的答案 JSON 数组：["A"] 或 ["B","D"]
  TextColumn get givenAnswerJson => text().named('given_answer_json')();

  /// 本次作答是否正确
  BoolColumn get isCorrect => boolean().named('is_correct')();

  /// 复习模式：'random' | 'review' | 'spotcheck'
  TextColumn get mode => text()();

  /// 作答耗时（毫秒）
  IntColumn get elapsedMs => integer().named('elapsed_ms')();

  /// 作答时间
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
