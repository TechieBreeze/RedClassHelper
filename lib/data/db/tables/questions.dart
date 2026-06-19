// lib/data/db/tables/questions.dart (D-08)
// ── 题目表 ── 存储解析后的单道题 ──

import 'package:drift/drift.dart';
import 'question_banks.dart';

/// 题目行（隶属于某个题库；题库删除时级联删除）
@DataClassName('Question')
class Questions extends Table {
  /// UUID 主键（与 QuestionBank 共享 String id 类型，D-08）
  TextColumn get id => text()();

  /// 所属题库 FK → question_banks.id（D-09：级联删除）
  TextColumn get bankId => text()
      .named('bank_id')
      .references(QuestionBanks, #id, onDelete: KeyAction.cascade)();

  /// 题型：'single' | 'multiple'
  TextColumn get type => text()();

  /// 题干纯文本
  TextColumn get stem => text()();

  /// 选项 JSON 数组：[{"key":"A","text":"..."}, ...]
  TextColumn get optionsJson => text().named('options_json')();

  /// 正确答案 JSON 数组：["A"] 或 ["A","C"]
  TextColumn get correctJson => text().named('correct_json')();

  /// 原始文本（供 LLM 重放 / 调试）
  TextColumn get rawText => text().named('raw_text')();

  /// 创建时间
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
