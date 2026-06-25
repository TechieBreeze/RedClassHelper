// lib/data/db/tables/question_banks.dart (D-07)
// ── 题库表 ── 存储导入的题库元数据 ──

import 'package:drift/drift.dart';

/// 题库元数据行
@DataClassName('QuestionBank')
class QuestionBanks extends Table {
  /// UUID 主键（D-08 共享 String id 类型）
  TextColumn get id => text()();

  /// 题库名称（用户可见，如"2024秋-数据库原理"）
  TextColumn get name => text()();

  /// 来源路径或描述（文件路径 / 手动输入）。
  ///
  /// 移动端字节源无磁盘路径时为 null（DB 端使用 file name 兜底）。
  TextColumn get source => text().nullable()();

  /// 解析出的题目总数
  IntColumn get questionCount => integer().named('question_count')();

  /// 创建时间
  DateTimeColumn get createdAt => dateTime()();

  /// 最后修改时间
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
