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

@DriftDatabase(
  tables: [
    QuestionBanks,
    Questions,
    WrongLedgerEntries,
    AnswerAttempts,
    Bookmarks,
    ParseJobs,
    ParseLogs,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// 由 drift codegen 调用；传入底层数据库连接。
  AppDatabase(super.e);

  // ── D-14: schemaVersion = 1 — v2: source/sourcePath nullable ──

  @override
  int get schemaVersion => 2;

  // ── MigrationStrategy ──

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      // D-14: v1 起步 — 创建所有 6+1 张表
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      // v2: source/sourcePath 改为 nullable（移动端字节源无磁盘路径）
      if (from < 2) {
        // SQLite 不支持 ALTER COLUMN — 通过 rename + recreate + copy 重建表
        await _recreateTableNullable(
          m,
          oldName: 'question_banks',
          newName: 'question_banks',
          ddl: _questionBanksV2Ddl,
          columns: 'id, name, source, question_count, created_at, updated_at',
        );
        await _recreateTableNullable(
          m,
          oldName: 'parse_jobs',
          newName: 'parse_jobs',
          ddl: _parseJobsV2Ddl,
          columns:
              'id, source_path, status, progress, result_count, '
              'error_message, created_at, updated_at',
        );
      }
    },
    beforeOpen: (details) async {
      // PITFALL 3: SQLite 默认关闭外键; 每次连接必须显式开启
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// 将指定表重建为给定 DDL，并保留旧数据。
  ///
  /// SQLite 不支持 `ALTER COLUMN ... DROP NOT NULL`，因此采用
  /// rename → create new → copy → drop old 的等价操作。
  ///
  /// [columns] 是 v1 与 v2 共享的列清单（逗号分隔）。v1 与 v2 必须列名一致——
  /// 本函数只用于"仅改 nullable"的迁移；如果 v2 列名变了，应该单独写迁移。
  static Future<void> _recreateTableNullable(
    Migrator m, {
    required String oldName,
    required String newName,
    required String ddl,
    required String columns,
  }) async {
    final old = '${oldName}_v1_old';
    final db = m.database;
    // 防御性清理: 上次迁移如果在中途崩溃 (例如应用被强杀), 临时表
    // {name}_v1_old 可能残留, 导致本次 ALTER TABLE RENAME 报 "already exists"。
    await db.customStatement('DROP TABLE IF EXISTS $old');
    await db.customStatement('ALTER TABLE $oldName RENAME TO $old');
    await db.customStatement(ddl);
    await db.customStatement(
      'INSERT INTO $newName ($columns) '
      'SELECT $columns '
      'FROM $old',
    );
    await db.customStatement('DROP TABLE $old');
  }

  static const _questionBanksV2Ddl = '''
    CREATE TABLE question_banks (
      id TEXT NOT NULL PRIMARY KEY,
      name TEXT NOT NULL,
      source TEXT NULL,
      question_count INTEGER NOT NULL,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )
  ''';

  static const _parseJobsV2Ddl = '''
    CREATE TABLE parse_jobs (
      id TEXT NOT NULL PRIMARY KEY,
      source_path TEXT NULL,
      status TEXT NOT NULL,
      progress REAL NOT NULL,
      result_count INTEGER NOT NULL,
      error_message TEXT NULL,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )
  ''';

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
