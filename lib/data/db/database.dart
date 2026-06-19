// lib/data/db/database.dart
// ── drift @DriftDatabase 入口 ──
// 连接所有 7 张表，定义 schemaVersion=1 的 MigrationStrategy。
// Plan 01-03: 添加 appDatabaseProvider（通过 pathResolverProvider 获取 DB 路径）

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/paths.dart';
import 'tables/answer_attempts.dart';
import 'tables/bookmarks.dart';
import 'tables/parse_jobs.dart';
import 'tables/parse_logs.dart';
import 'tables/question_banks.dart';
import 'tables/questions.dart';
import 'tables/wrong_ledger_entries.dart';

part 'database.g.dart';

@DriftDatabase(tables: [
  QuestionBanks,
  Questions,
  WrongLedgerEntries,
  AnswerAttempts,
  Bookmarks,
  ParseJobs,
  ParseLogs,
])
class AppDatabase extends _$AppDatabase {
  /// 由 drift codegen 调用；传入底层数据库连接。
  AppDatabase(super.e);

  // ── D-14: schemaVersion = 1 ──

  @override
  int get schemaVersion => 1;

  // ── MigrationStrategy ──

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          // D-14: v1 起步 — 创建所有 6+1 张表
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          // D-14: v1 留空 — 未来 schema 变更再补
        },
        beforeOpen: (details) async {
          // PITFALL 3: SQLite 默认关闭外键; 每次连接必须显式开启
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  // ── 工厂方法 ──

  /// 打开磁盘 SQLite 文件（生产环境用 — 计划 01-03 切换到 PathResolver）
  static AppDatabase openAppDatabase(String filePath) {
    return AppDatabase(
      NativeDatabase.createInBackground(
        File(filePath),
        setup: (db) {
          // PITFALL 3: WAL 模式支持并发读 + 单线程写
          db.execute('pragma journal_mode = WAL;');
        },
      ),
    );
  }

  /// 内存数据库 — 单元测试专用
  static AppDatabase openInMemoryDatabase() {
    return AppDatabase(NativeDatabase.memory());
  }
}

// ── Riverpod provider: 通过 pathResolverProvider 获取 DB 路径 ──

@Riverpod(keepAlive: true)
Future<AppDatabase> appDatabase(Ref ref) async {
  final resolver = await ref.watch(pathResolverProvider.future);
  return AppDatabase(
    NativeDatabase.createInBackground(
      File(resolver.databasePath),
      setup: (db) {
        // PITFALL 3: WAL 模式支持并发读 + 单线程写
        db.execute('pragma journal_mode = WAL;');
      },
    ),
  );
}
