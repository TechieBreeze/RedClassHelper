// test/data/db/migration_test.dart
// ── AppDatabase schema 验证 ──
// 6 个测试覆盖：schemaVersion、7 表创建、FK PRAGMA、CRUD 往返、UNIQUE 约束、
// v1→v2 迁移后 questions.bank_id FK 仍可工作

import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

import 'package:redclass/data/db/database.dart';
// ignore_for_file: unused_local_variable — 表查询用于触发 onCreate / 验证 schema

void main() {
  group('AppDatabase schema (schemaVersion = 2)', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    // ── 测试 1: schemaVersion ──
    test('schemaVersion is 2', () {
      expect(db.schemaVersion, 2);
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

        // Step 3: 验证迁移后 user_version 已升级到 2
        final userVersion = await migDb.customSelect(
          'PRAGMA user_version',
        ).getSingle();
        expect(userVersion.data.values.first, 2,
            reason: 'onUpgrade 应已将 user_version 从 1 升级到 2');

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
  });
}
