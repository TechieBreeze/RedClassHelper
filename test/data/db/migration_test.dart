// test/data/db/migration_test.dart
// ── AppDatabase schema 验证 ──
// 7 个测试覆盖：schemaVersion、7 表创建、FK PRAGMA、CRUD 往返、UNIQUE 约束、
// v1→v2 迁移后 questions.bank_id FK 仍可工作、
// v2→v3 修复 v1 破坏性迁移留下的孤儿 FK

import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

import 'package:redclass/data/db/database.dart';
// ignore_for_file: unused_local_variable — 表查询用于触发 onCreate / 验证 schema

void main() {
  group('AppDatabase schema (schemaVersion = 3)', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    // ── 测试 1: schemaVersion ──
    test('schemaVersion is 3', () {
      expect(db.schemaVersion, 3);
    });

    // ── 测试 2: onCreate 创建全部 7 张表 ──
    test('onCreate creates all 7 tables', () async {
      // 对内存数据库，drift 在首次查询时触发 onCreate
      // 每张表执行一次 select 以确认表存在且可查询
      await db.select(db.questionBanks).get();
      await db.select(db.questions).get();
      await db.select(db.wrongLedgerEntries).get();
      await db.select(db.answerAttempts).get();
      await db.select(db.bookmarks).get();
      await db.select(db.parseJobs).get();
      await db.select(db.parseLogs).get();
      // 无异常 = schema 创建成功
    });

    // ── 测试 3: foreign_keys PRAGMA ──
    test('foreign_keys PRAGMA is ON after open', () async {
      // 触发 onCreate（同时跑 beforeOpen）
      await db.select(db.questionBanks).get();

      final row = await db.customSelect('PRAGMA foreign_keys').getSingle();
      expect(
        row.data.values.first,
        1,
        reason: 'PRAGMA foreign_keys 应为 1 (ON) — beforeOpen 回调已执行',
      );
    });

    // ── 测试 4: QuestionBank insert + read 往返 ──
    test('QuestionBank insert + read round-trip (D-07)', () async {
      final now = DateTime.now();
      const bankId = 'bank-roundtrip-test-001';

      await db
          .into(db.questionBanks)
          .insert(
            QuestionBanksCompanion.insert(
              id: bankId,
              name: 'Test Bank',
              source: const Value('/tmp/test.docx'),
              questionCount: 0,
              createdAt: now,
              updatedAt: now,
            ),
          );

      final fetched = await (db.select(
        db.questionBanks,
      )..where((t) => t.id.equals(bankId))).getSingle();

      expect(fetched.name, 'Test Bank');
      expect(fetched.questionCount, 0);
      expect(fetched.source, '/tmp/test.docx');
    });

    // ── 测试 5: WrongLedgerEntry UNIQUE 约束 ──
    test('WrongLedgerEntry has UNIQUE on question_id (D-09)', () async {
      final now = DateTime.now();
      const bankId = 'bank-unique-test';
      const questionId = 'q-unique-test';

      // 插入题库
      await db
          .into(db.questionBanks)
          .insert(
            QuestionBanksCompanion.insert(
              id: bankId,
              name: 'Bank',
              source: const Value('src'),
              questionCount: 1,
              createdAt: now,
              updatedAt: now,
            ),
          );

      // 插入题目
      await db
          .into(db.questions)
          .insert(
            QuestionsCompanion.insert(
              id: questionId,
              bankId: bankId,
              type: 'single',
              stem: 'Q1?',
              optionsJson: '[]',
              correctJson: '["A"]',
              rawText: 'raw',
              createdAt: now,
            ),
          );

      // 第一次插入错题记录 → 成功
      await db
          .into(db.wrongLedgerEntries)
          .insert(
            WrongLedgerEntriesCompanion.insert(
              questionId: questionId,
              timesWrong: 1,
              firstWrongAt: now,
              lastWrongAt: now,
            ),
          );

      // 第二次以相同 question_id 插入 → 必须触发 UNIQUE 约束违规
      await expectLater(
        () => db
            .into(db.wrongLedgerEntries)
            .insert(
              WrongLedgerEntriesCompanion.insert(
                questionId: questionId,
                timesWrong: 2,
                firstWrongAt: now,
                lastWrongAt: now,
              ),
            ),
        throwsA(isA<Exception>()),
      );
    });

    // ── 测试 6: v1→v2 migration 不破坏 questions.bank_id FK ──
    //
    // 根因：_recreateTableNullable 用 ALTER TABLE ... RENAME TO ..._v1_old
    // 重建 question_banks 时，SQLite 会自动把 questions.bank_id 的 FK
    // 引用改成 _v1_old；重建完后 _v1_old 被 DROP，导致 questions.bank_id
    // 指向不存在的表 → INSERT 时 FK 校验报 "no such table: main.question_banks_v1_old"。
    //
    // 手动构造 v1 schema + user_version=1 → 首次查询触发 onUpgrade →
    // INSERT questions 必须成功。
    test('v1→v2 migration: INSERT questions still works after onUpgrade', () async {
      // 用临时文件承载 v1 schema；in-memory DB 每次 open 都是新的，
      // 无法在 drift 打开前预置 v1 schema + user_version=1。
      final tmpDir = await Directory.systemTemp.createTemp('redclass_mig_');
      final dbPath = p.join(tmpDir.path, 'v1.db');
      addTearDown(() async {
        if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
      });

      // Step 1: 用 raw sqlite3 写 v1 schema + user_version=1
      final rawDb = sqlite3.open(dbPath);
      try {
        rawDb.execute('''
          CREATE TABLE question_banks (
            id TEXT NOT NULL PRIMARY KEY,
            name TEXT NOT NULL,
            source TEXT NOT NULL,
            question_count INTEGER NOT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        rawDb.execute('''
          CREATE TABLE parse_jobs (
            id TEXT NOT NULL PRIMARY KEY,
            source_path TEXT NOT NULL,
            status TEXT NOT NULL,
            progress REAL NOT NULL,
            result_count INTEGER NOT NULL,
            error_message TEXT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        // questions 表也需要存在 —— v1 中它就有 FK 指向 question_banks(id)
        // 这是测试 INSERT questions 是否仍然受 FK 校验保护的前提。
        rawDb.execute('''
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
        ''');
        rawDb.execute('PRAGMA user_version = 1');
      } finally {
        rawDb.dispose();
      }

      // Step 2: 用 drift 打开同一文件 → onUpgrade(from=1, to=2) 自动触发
      final migDb = AppDatabase(NativeDatabase(File(dbPath)));
      addTearDown(() async {
        await migDb.close();
      });

      try {
        // 触发 beforeOpen + onUpgrade
        await migDb.select(migDb.questionBanks).get();

        // Step 3: 验证迁移后 user_version 已升级到当前 schemaVersion
        //         （v1→v2 测试中，drift 会从 from=1 一路升级到当前版本 3，
        //         因为 v2→v3 migration 也会跑 —— 但本测试只关心 v1→v2
        //         修复是否生效，不验证 v2→v3）。
        final userVersion = await migDb.customSelect(
          'PRAGMA user_version',
        ).getSingle();
        expect(userVersion.data.values.first, migDb.schemaVersion,
            reason: 'onUpgrade 应已将 user_version 升级到当前 schemaVersion');

        // Step 4: 在迁移后的 v2 schema 上 INSERT 一个 bank + 一道 question
        //         —— 这正是用户报告"保存失败"的代码路径。
        //         如果 questions.bank_id FK 仍指向 _v1_old，下面的 insert
        //         会抛 SqliteException: no such table: main.question_banks_v1_old
        final now = DateTime.now();
        await migDb.into(migDb.questionBanks).insert(
              QuestionBanksCompanion.insert(
                id: 'bank-mig-test',
                name: '迁移测试题库',
                source: const Value('src.docx'),
                questionCount: 1,
                createdAt: now,
                updatedAt: now,
              ),
            );

        await migDb.into(migDb.questions).insert(
              QuestionsCompanion.insert(
                id: 'q-mig-test',
                bankId: 'bank-mig-test',
                type: 'single',
                stem: '迁移后能正常写入吗？',
                optionsJson: '[]',
                correctJson: '["A"]',
                rawText: 'raw',
                createdAt: now,
              ),
            );

        // Step 5: 验证 PRAGMA foreign_key_check 无违规
        final violations = await migDb.customSelect(
          'PRAGMA foreign_key_check',
        ).get();
        expect(violations, isEmpty,
            reason: 'FK 检查必须无违规 —— migration 后所有 FK 都应指向现有表');
      } catch (_) {
        rethrow;
      }
    });

    // ── 测试 7: v2→v3 migration 修复 v1 破坏性迁移留下的孤儿 FK ──
    //
    // 真实场景: 用户的 db 在 commit 1722476 之前已被旧代码执行了破坏性 v1→v2
    // 迁移（旧代码用 "先 RENAME 再 CREATE" 顺序），导致:
    //   - questions.bank_id FK 文本变成 REFERENCES question_banks_v1_old
    //   - parse_logs.parse_job_id FK 文本变成 REFERENCES parse_jobs_v1_old
    //   - _v1_old 表已被 DROP
    //
    // 用户报告的错误: "no such table: main.question_banks_v1_old" 在
    // INSERT INTO "questions" 时发生 —— 500 道题因此无法保存。
    //
    // 修复方案 (v2→v3): 用 staging→copy→DROP→RENAME 模式 recreate
    // questions 和 parse_logs，让 FK 文本重新指向 question_banks(id) /
    // parse_jobs(id)，同时保留所有数据（用户已有 500 道题 + 348 错题 +
    // 1465 答题记录）。
    test('v2→v3 migration: repairs orphan FK from broken v1→v2 + preserves data',
        () async {
      final tmpDir = await Directory.systemTemp.createTemp('redclass_mig_v3_');
      final dbPath = p.join(tmpDir.path, 'v2-broken.db');
      addTearDown(() async {
        if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
      });

      // Step 1: 用 raw sqlite3 构造"损坏的 v2 状态"
      //   - questions/parse_logs FK 文本指向 _v1_old（用户真实状态）
      //   - question_banks/parse_jobs 是 v2 schema（source/sourcePath NULL）
      //   - user_version=2
      //   - 预填真实数据（500 questions + 348 wrong + 1465 attempts）
      //     —— FK=ON 时 INSERT 会失败（FK 指向不存在的 _v1_old），
      //     所以先 FK=OFF 插数据，然后 FK=ON 验证迁移。
      final rawDb = sqlite3.open(dbPath);
      try {
        rawDb.execute('PRAGMA foreign_keys = OFF');

        // v2 question_banks (source NULL)
        rawDb.execute('''
          CREATE TABLE question_banks (
            id TEXT NOT NULL PRIMARY KEY,
            name TEXT NOT NULL,
            source TEXT NULL,
            question_count INTEGER NOT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');

        // 损坏的 questions: FK 指向 question_banks_v1_old
        rawDb.execute('''
          CREATE TABLE questions (
            id TEXT NOT NULL PRIMARY KEY,
            bank_id TEXT NOT NULL REFERENCES question_banks_v1_old(id) ON DELETE CASCADE,
            type TEXT NOT NULL,
            stem TEXT NOT NULL,
            options_json TEXT NOT NULL,
            correct_json TEXT NOT NULL,
            raw_text TEXT NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');

        // v2 parse_jobs (source_path NULL)
        rawDb.execute('''
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
        ''');

        // 损坏的 parse_logs: FK 指向 parse_jobs_v1_old
        rawDb.execute('''
          CREATE TABLE parse_logs (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            parse_job_id TEXT NOT NULL REFERENCES parse_jobs_v1_old(id) ON DELETE CASCADE,
            level TEXT NOT NULL,
            message TEXT NOT NULL,
            context_json TEXT NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');

        // 子表: 指向 questions/parse_jobs（这些表 FK 文本正确）
        rawDb.execute('''
          CREATE TABLE wrong_ledger_entries (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            question_id TEXT NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
            times_wrong INTEGER NOT NULL,
            first_wrong_at INTEGER NOT NULL,
            last_wrong_at INTEGER NOT NULL,
            mastered_at INTEGER NULL,
            UNIQUE(question_id)
          )
        ''');
        rawDb.execute('''
          CREATE TABLE answer_attempts (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            question_id TEXT NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
            given_answer_json TEXT NOT NULL,
            is_correct INTEGER NOT NULL CHECK (is_correct IN (0, 1)),
            mode TEXT NOT NULL,
            elapsed_ms INTEGER NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');
        rawDb.execute('''
          CREATE TABLE bookmarks (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            question_id TEXT NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
            created_at INTEGER NOT NULL,
            UNIQUE(question_id)
          )
        ''');

        // 插入真实规模的数据
        rawDb.execute(
          "INSERT INTO question_banks VALUES ('bank-1', 'B1', 's.docx', 2, 100, 100)",
        );
        for (var i = 0; i < 500; i++) {
          rawDb.execute(
            "INSERT INTO questions VALUES ('q-$i', 'bank-1', 'single', 'Q$i?', '[]', '[\"A\"]', 'r', ${100 + i})",
          );
        }
        for (var i = 0; i < 348; i++) {
          rawDb.execute(
            "INSERT INTO wrong_ledger_entries (question_id, times_wrong, first_wrong_at, last_wrong_at) "
            "VALUES ('q-$i', 1, 100, 100)",
          );
        }
        for (var i = 0; i < 1465; i++) {
          rawDb.execute(
            "INSERT INTO answer_attempts (question_id, given_answer_json, is_correct, mode, elapsed_ms, created_at) "
            "VALUES ('q-0', '[\"A\"]', 1, 'practice', 1000, 100)",
          );
        }

        rawDb.execute('PRAGMA user_version = 2');
      } finally {
        rawDb.dispose();
      }

      // Step 2: 用 drift 打开同一文件 → onUpgrade(from=2, to=3) 自动触发
      final migDb = AppDatabase(NativeDatabase(File(dbPath)));
      addTearDown(() async {
        await migDb.close();
      });

      // 触发 beforeOpen + onUpgrade
      await migDb.select(migDb.questionBanks).get();

      // Step 3: 验证 user_version 升级到 3
      final userVersion = await migDb.customSelect(
        'PRAGMA user_version',
      ).getSingle();
      expect(userVersion.data.values.first, 3,
          reason: 'onUpgrade 应已将 user_version 从 2 升级到 3');

      // Step 4: 验证 questions 表 FK 文本已修复（指向 question_banks，不含 _v1_old）
      final questionsDdl = await migDb.customSelect(
        "SELECT sql FROM sqlite_master WHERE name='questions'",
      ).getSingle();
      final questionsSql = questionsDdl.data.values.first as String;
      expect(questionsSql.contains('REFERENCES question_banks(id)'), isTrue,
          reason: 'questions.bank_id FK 必须指向 question_banks(id)');
      expect(questionsSql.contains('_v1_old'), isFalse,
          reason: 'questions FK 文本不能再包含 _v1_old');

      // Step 5: 验证 parse_logs 表 FK 文本已修复
      final parseLogsDdl = await migDb.customSelect(
        "SELECT sql FROM sqlite_master WHERE name='parse_logs'",
      ).getSingle();
      final parseLogsSql = parseLogsDdl.data.values.first as String;
      expect(parseLogsSql.contains('REFERENCES parse_jobs(id)'), isTrue,
          reason: 'parse_logs.parse_job_id FK 必须指向 parse_jobs(id)');
      expect(parseLogsSql.contains('_v1_old'), isFalse,
          reason: 'parse_logs FK 文本不能再包含 _v1_old');

      // Step 6: 验证子表 FK 文本保持指向 questions（rename 时不被破坏）
      for (final childName in ['wrong_ledger_entries', 'answer_attempts', 'bookmarks']) {
        final childDdl = await migDb.customSelect(
          "SELECT sql FROM sqlite_master WHERE name='" + childName + "'",
        ).getSingle();
        final childSql = childDdl.data.values.first as String;
        expect(childSql.contains('REFERENCES questions(id)'), isTrue,
            reason: '$childName.question_id FK 必须保持指向 questions(id)');
      }

      // Step 7: 验证数据完整保留（500 questions + 348 wrong + 1465 attempts）
      final qCount = await migDb.customSelect(
        'SELECT COUNT(*) AS c FROM questions',
      ).getSingle();
      expect(qCount.data.values.first, 500,
          reason: 'questions 数据必须保留 500 行');

      final wCount = await migDb.customSelect(
        'SELECT COUNT(*) AS c FROM wrong_ledger_entries',
      ).getSingle();
      expect(wCount.data.values.first, 348,
          reason: 'wrong_ledger_entries 数据必须保留 348 行');

      final aCount = await migDb.customSelect(
        'SELECT COUNT(*) AS c FROM answer_attempts',
      ).getSingle();
      expect(aCount.data.values.first, 1465,
          reason: 'answer_attempts 数据必须保留 1465 行');

      // Step 8: PRAGMA foreign_key_check 0 违规
      final violations = await migDb.customSelect(
        'PRAGMA foreign_key_check',
      ).get();
      expect(violations, isEmpty,
          reason: 'FK 检查必须无违规 —— migration 后所有 FK 都应指向现有表');

      // Step 9: 模拟用户的真实场景——INSERT 一道新 question（之前会失败）
      await migDb.into(migDb.questionBanks).insert(
            QuestionBanksCompanion.insert(
              id: 'bank-new',
              name: '迁移后新建的题库',
              source: const Value('new.docx'),
              questionCount: 1,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
      await migDb.into(migDb.questions).insert(
            QuestionsCompanion.insert(
              id: 'q-new',
              bankId: 'bank-new',
              type: 'single',
              stem: '迁移后能写入吗？',
              optionsJson: '[]',
              correctJson: '["A"]',
              rawText: 'raw',
              createdAt: DateTime.now(),
            ),
          );
    });
  });
}
