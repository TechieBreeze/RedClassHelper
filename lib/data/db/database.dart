// lib/data/db/database.dart
// ── drift @DriftDatabase 入口 ──
// 连接所有 7 张表，定义 schemaVersion=3 的 MigrationStrategy。
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

  // ── schema version history ──
  // v1: 起步 — 7 张表
  // v2: source/sourcePath 改为 nullable（移动端字节源无磁盘路径）
  // v3: 修复 v2 迁移逻辑 bug —— 老 v2 迁移用 "先 RENAME 再 CREATE" 留下了
  //     指向 _v1_old 的孤儿 FK；本版本 recreate questions/parse_logs 表
  //     让 FK 文本重新指向 question_banks/parse_jobs。

  @override
  int get schemaVersion => 3;

  // ── MigrationStrategy ──

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      // v1 起步 — 创建所有 7 张表
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      // v1→v2: source/sourcePath 改为 nullable（移动端字节源无磁盘路径）
      if (from < 2) {
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

      // v2→v3: 修复 v1→v2 迁移留下的孤儿 FK
      //
      // 老版本 v1→v2 用 "先 RENAME 旧表再 CREATE 同名新表" 顺序，SQLite 在
      // RENAME 时自动更新子表 FK 引用，导致 questions.bank_id 变成
      // "REFERENCES question_banks_v1_old"。DROP 旧表后 FK 指向不存在的表
      // → INSERT 报 "no such table: main.question_banks_v1_old"。
      //
      // 本版本用 staging→copy→DROP→RENAME 模式重新创建 questions 和
      // parse_logs，让 FK 文本重新指向正确的 v2 表名。
      if (from < 3) {
        await _recreateTableFixingFks(
          m,
          oldName: 'questions',
          newName: 'questions',
          ddl: _questionsV3Ddl,
          columns:
              'id, bank_id, type, stem, options_json, correct_json, raw_text, created_at',
        );
        await _recreateTableFixingFks(
          m,
          oldName: 'parse_logs',
          newName: 'parse_logs',
          ddl: _parseLogsV3Ddl,
          columns: 'id, parse_job_id, level, message, context_json, created_at',
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
  /// create new (different name) → copy → drop old → rename new 的等价操作。
  ///
  /// **重要**：必须先创建"新表"，最后再 rename 到原名。如果先 RENAME 旧表，
  /// SQLite 会自动更新子表的外键引用（如 `questions.bank_id REFERENCES
  /// question_banks` → `REFERENCES question_banks_v1_old`），重建完后
  /// `_v1_old` 被 DROP，子表 FK 指向不存在的表 → INSERT 校验报
  /// "no such table: main.question_banks_v1_old"。
  ///
  /// 当前顺序让 FK 文本始终是 `REFERENCES 原表名`，最终 RENAME 后
  /// 立即匹配，无需刷新 FK 元数据。
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
    final staging = '${newName}_v2_new';
    final oldLegacy = '${oldName}_v1_old';
    final db = m.database;
    // 防御性清理 1：清理当前迁移可能残留的 staging 表。
    // 上次迁移如果在中途崩溃 (例如应用被强杀), {name}_v2_new 可能残留。
    await db.customStatement('DROP TABLE IF EXISTS $staging');
    // 防御性清理 2：清理旧版（破坏性）迁移残留的 _v1_old 表。
    // 老版本用 "先 RENAME 再 CREATE" 的顺序，崩溃时会留下 _v1_old；
    // 新顺序下 _v1_old 不会再产生，但用户的库可能已残留 —— 安全地清掉。
    await db.customStatement('DROP TABLE IF EXISTS $oldLegacy');

    // 1. 用 v2 schema 创建临时表（名字不同，不影响子表 FK 引用）
    await db.customStatement(
      ddl.replaceFirst('CREATE TABLE $newName', 'CREATE TABLE $staging'),
    );

    // 2. 从旧表复制数据
    await db.customStatement(
      'INSERT INTO $staging ($columns) '
      'SELECT $columns '
      'FROM $oldName',
    );

    // 3. 删除旧表
    await db.customStatement('DROP TABLE $oldName');

    // 4. 临时表改名为最终表名（子表 FK 文本已经是 REFERENCES 原表名，无需更新）
    await db.customStatement('ALTER TABLE $staging RENAME TO $newName');
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

  /// 将指定表重建为给定 DDL（用于 v2→v3 修复孤儿 FK）。
  ///
  /// 与 [_recreateTableNullable] 相同的 staging→copy→DROP→RENAME 顺序，
  /// 但本函数不涉及 source/sourcePath NULL 切换——纯粹为了更新 FK 引用。
  ///
  /// **关键安全保证**：
  /// 1. CREATE staging 时 FK 写正确引用（如 `REFERENCES question_banks(id)`），
  ///    此时旧 questions 还在，staging 不与任何表冲突。
  /// 2. INSERT staging FROM old —— FK=ON 时会校验数据完整性（FK 引用
  ///    question_banks(id)，必须所有 bank_id 都存在）。如果旧 questions
  ///    中存在孤儿行（指向不存在 bank_id），staging INSERT 会失败——这正
  ///    是我们想要的行为：FK 校验暴露数据不一致。
  /// 3. DROP old —— FK=ON 时，如果子表（wrong_ledger_entries 等）的
  ///    ON DELETE CASCADE 没设好会失败。本场景子表 FK 都是 ON DELETE
  ///    CASCADE，DROP old 会 cascade delete 子表中引用旧 questions 的行——
  ///    **然后 staging 也要重建这个引用链**。但因为 staging CREATE 时只
  ///    处理 `bank_id` FK，子表 FK 文本保持 `REFERENCES questions(id)`
  ///    不变，最终 RENAME staging→questions 后子表 FK 自动指向新 questions。
  /// 4. RENAME staging → original —— SQLite 的 RENAME 行为：如果新名字
  ///    和某个 FK 引用一致，所有子表 FK 文本保持指向该名字。
  ///
  /// [columns] 是 v2 与 v3 共享的列清单（逗号分隔）。v2 与 v3 必须列名一致——
  /// 本函数只用于"重建相同 schema 但修复 FK 引用"的迁移。
  static Future<void> _recreateTableFixingFks(
    Migrator m, {
    required String oldName,
    required String newName,
    required String ddl,
    required String columns,
  }) async {
    final staging = '${newName}_v3_new';
    final db = m.database;
    // 防御性清理:上次迁移如果在中途崩溃 staging 表可能残留
    await db.customStatement('DROP TABLE IF EXISTS $staging');

    // 防御性检查:从 v1 schema 升级 (from=1) 时,旧 schema 可能没有
    // parse_logs 等表（v1 只有 question_banks/parse_jobs/questions/
    // answer_attempts/wrong_ledger_entries/bookmarks 共 6 张表）。
    // 如果表不存在,跳过 recreate。
    final exists = await db.customSelect(
      "SELECT COUNT(*) AS c FROM sqlite_master "
      "WHERE type='table' AND name='$oldName'",
    ).getSingle();
    if (exists.data.values.first == 0) {
      return;
    }

    // 关键: 临时禁用 FK 检查。
    // beforeOpen 已开启 FK=ON。如果 FK=ON, DROP TABLE questions 会触发
    // 子表 (wrong_ledger_entries/answer_attempts/bookmarks) 的 ON DELETE
    // CASCADE, 级联删除用户数据（用户的 348 错题 + 1465 答题记录会被
    // 全部删除！）。FK=OFF 期间 SQLite 不检查 FK 约束, 但 FK 定义本身
    // 保留在 schema 中, 所以 RENAME staging→原名后子表 FK 自动指向新表。
    await db.customStatement('PRAGMA foreign_keys = OFF');

    try {
      // 1. 用正确 FK 引用创建 staging 表
      await db.customStatement(
        ddl.replaceFirst('CREATE TABLE $newName', 'CREATE TABLE $staging'),
      );

      // 2. 从旧表复制数据
      await db.customStatement(
        'INSERT INTO $staging ($columns) '
        'SELECT $columns '
        'FROM $oldName',
      );

      // 3. 删除旧表（FK=OFF 时不触发子表 cascade）
      await db.customStatement('DROP TABLE $oldName');

      // 4. staging 改名为原名
      //    SQLite RENAME 时自动扫描所有 FK 引用 staging 名的子表,
      //    把它们更新为指向新名字。如果新名字和旧 FK 引用一致
      //    (e.g. 子表 FK 写的是 REFERENCES questions(id)),
      //    最终 FK 文本保持原样 —— 正是我们要的。
      await db.customStatement('ALTER TABLE $staging RENAME TO $newName');
    } finally {
      // 恢复 FK=ON(下一次 beforeOpen 会再次设置)
      await db.customStatement('PRAGMA foreign_keys = ON');
    }
  }

  /// v3 questions DDL —— FK 指向 question_banks(id)（修复 v1 破坏性迁移
  /// 留下的 REFERENCES question_banks_v1_old）。
  static const _questionsV3Ddl = '''
    CREATE TABLE questions (
      id TEXT NOT NULL PRIMARY KEY,
      bank_id TEXT NOT NULL REFERENCES question_banks(id) ON DELETE CASCADE,
      type TEXT NOT NULL,
      stem TEXT NOT NULL,
      options_json TEXT NOT NULL,
      correct_json TEXT NOT NULL,
      raw_text TEXT NOT NULL,
      created_at INTEGER NOT NULL
    )
  ''';

  /// v3 parse_logs DDL —— FK 指向 parse_jobs(id)。
  static const _parseLogsV3Ddl = '''
    CREATE TABLE parse_logs (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      parse_job_id TEXT NOT NULL REFERENCES parse_jobs(id) ON DELETE CASCADE,
      level TEXT NOT NULL,
      message TEXT NOT NULL,
      context_json TEXT NOT NULL,
      created_at INTEGER NOT NULL
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
