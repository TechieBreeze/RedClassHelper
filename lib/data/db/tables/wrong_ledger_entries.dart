// lib/data/db/tables/wrong_ledger_entries.dart (D-09)
// ── 错题本表 ── 每题至多一条记录（UNIQUE question_id）──

import 'package:drift/drift.dart';
import 'questions.dart';

/// 错题记录（D-10：3 张表合并为单表，用 severity 替代 Penalty 表）
@DataClassName('WrongLedgerEntry')
class WrongLedgerEntries extends Table {
  /// 自增主键
  IntColumn get id => integer().autoIncrement()();

  /// 关联题目 FK（表级 UNIQUE 约束：一题至多一条错题记录）
  TextColumn get questionId => text()
      .named('question_id')
      .references(Questions, #id, onDelete: KeyAction.cascade)();

  /// 累计答错次数
  IntColumn get timesWrong => integer().named('times_wrong')();

  /// 首次答错时间
  DateTimeColumn get firstWrongAt => dateTime().named('first_wrong_at')();

  /// 最近一次答错时间
  DateTimeColumn get lastWrongAt => dateTime().named('last_wrong_at')();

  /// 掌握时间（null = 尚未掌握；非 null = 已从错题本毕业）
  DateTimeColumn get masteredAt => dateTime().named('mastered_at').nullable()();

  // autoIncrement() 自动设置主键，无需再 override primaryKey
  // 表级 UNIQUE 约束与 REFERENCES 并行，不会互相覆盖
  @override
  List<String> get customConstraints => ['UNIQUE(question_id)'];
}
