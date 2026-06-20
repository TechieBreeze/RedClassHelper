import 'dart:convert';

import 'package:drift/drift.dart';

import '../db/database.dart';

/// 错题账本仓库 -- 所有账本读写与答题记录的统一入口 (D-16)。
///
/// 每个写方法都包裹在 [AppDatabase.transaction] 中，
/// 确保答案记录与错题账本变更的原子性 (STAT-01, D-16)。
class LedgerRepository {
  final AppDatabase _db;

  LedgerRepository(this._db);

  // ── Ledger Mutations ────────────────────────────────────────────

  /// 将题目记入错题本 (REV-02, D-17)。
  ///
  /// 如果该题目已在此前答错过则 [WrongLedgerEntries.timesWrong]+1
  /// 并更新 [WrongLedgerEntries.lastWrongAt]。
  /// 如果是首次答错则插入新行, timesWrong=1。
  Future<void> markWrong(String questionId) async {
    await _db.transaction(() async {
      final now = DateTime.now();
      final existing = await (_db.select(_db.wrongLedgerEntries)
        ..where((e) => e.questionId.equals(questionId))
      ).getSingleOrNull();

      if (existing != null) {
        await (_db.update(_db.wrongLedgerEntries)
          ..where((e) => e.questionId.equals(questionId))
        ).write(
          WrongLedgerEntriesCompanion(
            timesWrong: Value(existing.timesWrong + 1),
            lastWrongAt: Value(now),
          ),
        );
      } else {
        await _db.into(_db.wrongLedgerEntries).insert(
          WrongLedgerEntriesCompanion.insert(
            questionId: questionId,
            timesWrong: 1,
            firstWrongAt: now,
            lastWrongAt: now,
          ),
        );
      }
    });
  }

  /// 将题目标记为已掌握 (REV-04, D-17)。
  ///
  /// 设置 [WrongLedgerEntries.masteredAt] 为当前时间。
  /// 此后该题目不再计入 active wrong count。
  Future<void> markMastered(String questionId) async {
    await _db.transaction(() async {
      await (_db.update(_db.wrongLedgerEntries)
        ..where((e) => e.questionId.equals(questionId))
      ).write(
        WrongLedgerEntriesCompanion(
          masteredAt: Value(DateTime.now()),
        ),
      );
    });
  }

  /// 记录一次答错并原子写入答题记录与错题账本 (REV-02, STAT-01, D-16)。
  ///
  /// 1. 向 [AnswerAttempts] 插入一行, 包含 questionId、givenAnswerJson、
  ///    isCorrect、mode、elapsedMs、createdAt。
  /// 2. 如果 [isCorrect] 为 false 则调用 [markWrong]。
  ///
  /// 以上两步在同一个 drift transaction 中执行——
  /// 如果任意一步失败则全部回滚。
  Future<void> recordWrongAnswer({
    required String questionId,
    required List<String> givenAnswer,
    required bool isCorrect,
    required String mode,
    required int elapsedMs,
  }) async {
    await _db.transaction(() async {
      // 1. Insert answer attempt (STAT-01)
      await _db.into(_db.answerAttempts).insert(
        AnswerAttemptsCompanion.insert(
          questionId: questionId,
          givenAnswerJson: jsonEncode(givenAnswer),
          isCorrect: isCorrect,
          mode: mode,
          elapsedMs: elapsedMs,
          createdAt: DateTime.now(),
        ),
      );

      // 2. If incorrect, upsert into wrong ledger (REV-02)
      if (!isCorrect) {
        final now = DateTime.now();
        final existing = await (_db.select(_db.wrongLedgerEntries)
          ..where((e) => e.questionId.equals(questionId))
        ).getSingleOrNull();

        if (existing != null) {
          await (_db.update(_db.wrongLedgerEntries)
            ..where((e) => e.questionId.equals(questionId))
          ).write(
            WrongLedgerEntriesCompanion(
              timesWrong: Value(existing.timesWrong + 1),
              lastWrongAt: Value(now),
            ),
          );
        } else {
          await _db.into(_db.wrongLedgerEntries).insert(
            WrongLedgerEntriesCompanion.insert(
              questionId: questionId,
              timesWrong: 1,
              firstWrongAt: now,
              lastWrongAt: now,
            ),
          );
        }
      }
    });
  }

  /// 记录一次正确作答 (错题复习模式) 并原子标记掌握 (REV-04)。
  ///
  /// 在同一个 transaction 中完成:
  /// 1. 插入 AnswerAttempts (isCorrect=true)
  /// 2. 调用 markMastered 设置 masteredAt=now
  Future<void> recordCorrectReview({
    required String questionId,
    required List<String> givenAnswer,
    required String mode,
    required int elapsedMs,
  }) async {
    await _db.transaction(() async {
      // 1. Insert answer attempt
      await _db.into(_db.answerAttempts).insert(
        AnswerAttemptsCompanion.insert(
          questionId: questionId,
          givenAnswerJson: jsonEncode(givenAnswer),
          isCorrect: true,
          mode: mode,
          elapsedMs: elapsedMs,
          createdAt: DateTime.now(),
        ),
      );

      // 2. Mark as mastered (REV-04)
      await (_db.update(_db.wrongLedgerEntries)
        ..where((e) => e.questionId.equals(questionId))
      ).write(
        WrongLedgerEntriesCompanion(
          masteredAt: Value(DateTime.now()),
        ),
      );
    });
  }

  // ── Ledger Queries ──────────────────────────────────────────────

  /// 全局活跃错题数 (D-17)。
  ///
  /// 返回 [WrongLedgerEntries.masteredAt] IS NULL 的行数。
  Future<int> getActiveCount() async {
    final query = _db.selectOnly(_db.wrongLedgerEntries)
      ..addColumns([_db.wrongLedgerEntries.id.count()])
      ..where(_db.wrongLedgerEntries.masteredAt.isNull());
    final row = await query.getSingle();
    return row.read(_db.wrongLedgerEntries.id.count()) ?? 0;
  }

  /// 指定题库的活跃错题数 (D-17)。
  ///
  /// 返回 JOIN Questions 后 WHERE mastered_at IS NULL AND bank_id = ?
  /// 的行数。
  Future<int> getActiveByBank(String bankId) async {
    final joinQuery = _db.select(_db.wrongLedgerEntries).join([
      innerJoin(
        _db.questions,
        _db.questions.id.equalsExp(_db.wrongLedgerEntries.questionId),
      ),
    ])
      ..where(_db.wrongLedgerEntries.masteredAt.isNull())
      ..where(_db.questions.bankId.equals(bankId));
    final rows = await joinQuery.get();
    return rows.length;
  }

  /// 全局活跃错题数的响应式 Stream (D-14)。
  ///
  /// 每当 WrongLedgerEntries 表发生变更 (markWrong / markMastered)，
  /// 此 stream 自动发出新的 count 值。
  /// 返回的 [Stream<int>] 可直接绑定到 [wrongQuestionsProvider]。
  Stream<int> watchActiveCount() {
    final query = _db.selectOnly(_db.wrongLedgerEntries)
      ..addColumns([_db.wrongLedgerEntries.id.count()])
      ..where(_db.wrongLedgerEntries.masteredAt.isNull());
    return query
        .map((row) => row.read(_db.wrongLedgerEntries.id.count()) ?? 0)
        .watchSingle();
  }
}
