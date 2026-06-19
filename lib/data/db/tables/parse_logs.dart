// lib/data/db/tables/parse_logs.dart (D-13)
// ── 解析日志表 ── Phase 1 占位，Phase 6 添加 LRU 200 行 ──

import 'package:drift/drift.dart';
import 'parse_jobs.dart';

/// 解析过程日志（每条日志关联一个解析任务）
@DataClassName('ParseLog')
class ParseLogs extends Table {
  /// 自增主键
  IntColumn get id => integer().autoIncrement()();

  /// 关联解析任务 FK（任务删除时级联删除日志）
  TextColumn get parseJobId => text()
      .named('parse_job_id')
      .references(ParseJobs, #id, onDelete: KeyAction.cascade)();

  /// 日志级别：'info' | 'warn' | 'error'
  TextColumn get level => text()();

  /// 日志消息
  TextColumn get message => text()();

  /// 附加上下文 JSON（文件偏移量 / 行号等）
  TextColumn get contextJson => text().named('context_json')();

  /// 日志时间
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
