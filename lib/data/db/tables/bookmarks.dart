// lib/data/db/tables/bookmarks.dart (D-11)
// ── 收藏表 ── Phase 1 占位，Phase 5 完整实现 ──

import 'package:drift/drift.dart';
import 'questions.dart';

/// 收藏记录（一题至多一条；表级 UNIQUE question_id）
@DataClassName('Bookmark')
class Bookmarks extends Table {
  /// 自增主键
  IntColumn get id => integer().autoIncrement()();

  /// 关联题目 FK（表级 UNIQUE 约束：一题至多收藏一次）
  TextColumn get questionId => text()
      .named('question_id')
      .references(Questions, #id, onDelete: KeyAction.cascade)();

  /// 收藏时间
  DateTimeColumn get createdAt => dateTime()();

  // autoIncrement() 自动设置主键，无需再 override primaryKey
  // 表级 UNIQUE 约束与 REFERENCES 并行，不会互相覆盖
  @override
  List<String> get customConstraints => ['UNIQUE(question_id)'];
}
