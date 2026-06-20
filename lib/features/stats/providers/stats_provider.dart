// lib/features/stats/providers/stats_provider.dart
// Provider for per-bank + per-mode statistics aggregation (STAT-02).

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/db/database.dart';
import '../../../data/repositories/ledger_repository.dart';

part 'stats_provider.g.dart';

/// Per-mode attempt breakdown for a single review mode.
@immutable
class ModeBreakdown {
  const ModeBreakdown({
    required this.mode,
    required this.attempts,
    required this.correctCount,
  });

  final String mode; // 'random', 'review', 'spotcheck'
  final int attempts;
  final int correctCount;

  double get correctRate => attempts == 0 ? 0.0 : correctCount / attempts;

  String get displayName => switch (mode) {
        'random' => '乱序抽题',
        'review' => '错题复习',
        'spotcheck' => '错题抽查',
        _ => mode,
      };
}

/// Aggregated statistics for a single question bank (D-09, D-10).
@immutable
class BankStats {
  const BankStats({
    required this.bank,
    required this.totalQuestions,
    required this.totalAttempts,
    required this.correctCount,
    required this.activeLedgerCount,
    required this.modes,
  });

  final QuestionBank bank;
  final int totalQuestions;
  final int totalAttempts;
  final int correctCount;
  final int activeLedgerCount;
  final List<ModeBreakdown> modes;

  double get correctRate =>
      totalAttempts == 0 ? 0.0 : correctCount / totalAttempts;

  /// Formatted correct rate as percentage string, or '暂无' if no attempts.
  String get correctRateDisplay => totalAttempts == 0
      ? '暂无'
      : '${(correctRate * 100).toStringAsFixed(0)}%';
}

/// Returns aggregated per-bank statistics with per-mode breakdown.
///
/// Recomputes on each visit (no keepAlive) to ensure freshness after
/// quiz answers modify attempt data.
@riverpod
Future<List<BankStats>> bankStatsList(Ref ref) async {
  final db = await ref.watch(appDatabaseProvider.future);
  final repo = LedgerRepository(db);

  final banks = await db.select(db.questionBanks).get();
  final stats = <BankStats>[];

  for (final bank in banks) {
    // Total questions in bank (COUNT via selectOnly — no join needed)
    final questionCountRow = await (db.selectOnly(db.questions)
          ..addColumns([db.questions.id.count()])
          ..where(db.questions.bankId.equals(bank.id)))
        .getSingle();
    final totalQuestions =
        questionCountRow.read(db.questions.id.count()) ?? 0;

    // Total attempts for this bank: JOIN questions + answer_attempts.
    // Uses select().join() pattern (same as getActiveByBank).
    final attemptRows = await (db.select(db.answerAttempts).join([
          innerJoin(
            db.questions,
            db.questions.id.equalsExp(db.answerAttempts.questionId),
          ),
        ])
          ..where(db.questions.bankId.equals(bank.id)))
        .get();
    final totalAttempts = attemptRows.length;

    // Correct count: same JOIN + isCorrect filter
    final correctRows = await (db.select(db.answerAttempts).join([
          innerJoin(
            db.questions,
            db.questions.id.equalsExp(db.answerAttempts.questionId),
          ),
        ])
          ..where(db.questions.bankId.equals(bank.id))
          ..where(db.answerAttempts.isCorrect.equals(true)))
        .get();
    final correctCount = correctRows.length;

    // Active ledger count
    final activeLedgerCount = await repo.getActiveByBank(bank.id);

    // Per-mode breakdown (D-10): for each mode, count attempts and correct
    final modes = <ModeBreakdown>[];
    for (final mode in ['random', 'review', 'spotcheck']) {
      final modeRows = await (db.select(db.answerAttempts).join([
            innerJoin(
              db.questions,
              db.questions.id.equalsExp(db.answerAttempts.questionId),
            ),
          ])
            ..where(db.questions.bankId.equals(bank.id))
            ..where(db.answerAttempts.mode.equals(mode)))
          .get();
      final modeAttempts = modeRows.length;

      final modeCorrectRows = await (db.select(db.answerAttempts).join([
            innerJoin(
              db.questions,
              db.questions.id.equalsExp(db.answerAttempts.questionId),
            ),
          ])
            ..where(db.questions.bankId.equals(bank.id))
            ..where(db.answerAttempts.mode.equals(mode))
            ..where(db.answerAttempts.isCorrect.equals(true)))
          .get();
      final modeCorrect = modeCorrectRows.length;

      modes.add(ModeBreakdown(
        mode: mode,
        attempts: modeAttempts,
        correctCount: modeCorrect,
      ));
    }

    stats.add(BankStats(
      bank: bank,
      totalQuestions: totalQuestions,
      totalAttempts: totalAttempts,
      correctCount: correctCount,
      activeLedgerCount: activeLedgerCount,
      modes: modes,
    ));
  }

  return stats;
}
