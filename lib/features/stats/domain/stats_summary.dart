// lib/features/stats/domain/stats_summary.dart

/// Aggregate totals computed across all [BankStats] for the stats screen hero.
///
/// Lives in `domain/` (pure Dart, no Flutter import) so the value object can be
/// reused by non-presentation callers (e.g. summary tests, future export flows)
/// without dragging widget dependencies into the data layer.
class StatsSummary {
  const StatsSummary({
    required this.totalQuestions,
    required this.totalAttempts,
    required this.totalCorrect,
    required this.overallRate,
  });

  final int totalQuestions;
  final int totalAttempts;
  final int totalCorrect;

  /// Fraction in [0.0, 1.0]. `0.0` when [totalAttempts] is zero.
  final double overallRate;
}
