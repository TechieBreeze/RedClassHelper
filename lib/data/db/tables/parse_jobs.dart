// lib/data/db/tables/parse_jobs.dart (D-12)
// ── 解析任务表 ── Phase 1 占位，Phase 2 完整实现 ──

import 'package:drift/drift.dart';

/// 一次文件解析任务
@DataClassName('ParseJob')
class ParseJobs extends Table {
  /// 任务 UUID（文本主键）
  TextColumn get id => text()();

  /// 源文件路径
  TextColumn get sourcePath => text().named('source_path')();

  /// 状态：'pending' | 'running' | 'succeeded' | 'failed' | 'cancelled'
  TextColumn get status => text()();

  /// 进度 0.0–1.0
  RealColumn get progress => real()();

  /// 解析出的题目数量
  IntColumn get resultCount => integer().named('result_count')();

  /// 失败原因（成功时为 null）
  TextColumn get errorMessage => text().named('error_message').nullable()();

  /// 创建时间
  DateTimeColumn get createdAt => dateTime()();

  /// 最后更新时间
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
