// test/data/db/migration_test.dart
// ── AppDatabase schema 验证 ──
// 5 个测试覆盖：schemaVersion、7 表创建、FK PRAGMA、CRUD 往返、UNIQUE 约束

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:redclass/data/db/database.dart';
// ignore_for_file: unused_local_variable — 表查询用于触发 onCreate / 验证 schema

void main() {
  group('AppDatabase schema (D-14: schemaVersion = 1)', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    // ── 测试 1: schemaVersion ──
    test('schemaVersion is 1', () {
      expect(db.schemaVersion, 1);
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
      expect(row.data.values.first, 1,
          reason: 'PRAGMA foreign_keys 应为 1 (ON) — beforeOpen 回调已执行');
    });

    // ── 测试 4: QuestionBank insert + read 往返 ──
    test('QuestionBank insert + read round-trip (D-07)', () async {
      final now = DateTime.now();
      const bankId = 'bank-roundtrip-test-001';

      await db.into(db.questionBanks).insert(
            QuestionBanksCompanion.insert(
              id: bankId,
              name: 'Test Bank',
              source: '/tmp/test.docx',
              questionCount: 0,
              createdAt: now,
              updatedAt: now,
            ),
          );

      final fetched = await (db.select(db.questionBanks)
            ..where((t) => t.id.equals(bankId)))
          .getSingle();

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
      await db.into(db.questionBanks).insert(
            QuestionBanksCompanion.insert(
              id: bankId,
              name: 'Bank',
              source: 'src',
              questionCount: 1,
              createdAt: now,
              updatedAt: now,
            ),
          );

      // 插入题目
      await db.into(db.questions).insert(
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
      await db.into(db.wrongLedgerEntries).insert(
            WrongLedgerEntriesCompanion.insert(
              questionId: questionId,
              timesWrong: 1,
              firstWrongAt: now,
              lastWrongAt: now,
            ),
          );

      // 第二次以相同 question_id 插入 → 必须触发 UNIQUE 约束违规
      await expectLater(
        () => db.into(db.wrongLedgerEntries).insert(
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
  });
}
