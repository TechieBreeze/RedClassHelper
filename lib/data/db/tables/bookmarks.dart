// lib/data/db/tables/bookmarks.dart (D-11)
// ── 收藏表 ── Phase 1 占位，Phase 5 完整实现 ──

import 'package:drift/drift.dart';
import 'questions.dart';

/// 收藏记录（一题至多一条；UNIQUE question_id）
@DataClassName('Bookmark')
class Bookmarks extends Table {
  /// 自增主键
  IntColumn get id => integer().autoIncrement()();

  /// 关联题目 FK（UNIQUE：一题至多收藏一次）
  TextColumn get questionId => text()
      .named('question_id')
      .customConstraint('UNIQUE')
      .references(Questions, #id, onDelete: KeyAction.cascade)();

  /// 收藏时间
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
