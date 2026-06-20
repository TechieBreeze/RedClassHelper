// lib/features/stats/providers/stats_provider.dart
// Provider for per-bank + per-mode statistics aggregation (STAT-02).

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/db/database.dart';

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
  // STUB — returns empty list. Tests must fail in RED phase.
  return [];
}
