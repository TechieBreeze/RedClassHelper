// lib/features/stats/presentation/stats_screen.dart
// Full StatsScreen implementation — per-bank expandable cards with per-mode
// breakdown (UI-SPEC §3, D-09, D-10, D-11).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/stats_provider.dart';

/// 数据统计 screen (UI-SPEC §3).
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(bankStatsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('数据统计')),
      body: statsAsync.when(
        loading: () => const _LoadingState(),
        error: (error, stack) => _ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(bankStatsListProvider),
        ),
        data: (stats) {
          if (stats.isEmpty) {
            return const _EmptyState();
          }
          return _DataState(stats: stats);
        },
      ),
    );
  }
}

// ── Loading state ──

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('加载统计...'),
        ],
      ),
    );
  }
}

// ── Error state ──

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: colorScheme.error),
          const SizedBox(height: 16),
          Text('加载失败', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            '请返回重试',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ──

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insights_outlined,
              size: 48, color: colorScheme.onSurface.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text('暂无统计数据',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            '完成答题后这里会显示各题库的正确率统计',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }
}

// ── Data state with bank card list ──

class _DataState extends StatelessWidget {
  const _DataState({required this.stats});

  final List<BankStats> stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final double hPad;
        final double? maxWidth;
        if (width < 600) {
          hPad = 16;
          maxWidth = null;
        } else if (width < 840) {
          hPad = 24;
          maxWidth = null;
        } else {
          hPad = 32;
          maxWidth = 720;
        }
        return Center(
          child: ConstrainedBox(
            constraints:
                BoxConstraints(maxWidth: maxWidth ?? double.infinity),
            child: ListView(
              padding:
                  EdgeInsets.symmetric(horizontal: hPad, vertical: 24),
              children: [
                for (final stat in stats) _StatsBankCard(stat: stat),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Expandable bank card (StatefulWidget for ephemeral expanded state) ──

class _StatsBankCard extends StatefulWidget {
  const _StatsBankCard({required this.stat});

  final BankStats stat;

  @override
  State<_StatsBankCard> createState() => _StatsBankCardState();
}

class _StatsBankCardState extends State<_StatsBankCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final stat = widget.stat;
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ── Header row ──
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(stat.bank.name,
                                style:
                                    Theme.of(context).textTheme.headlineSmall),
                            const SizedBox(height: 4),
                            Text(
                              '总题数 ${stat.totalQuestions} · 总答题次数 ${stat.totalAttempts}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(Icons.expand_more),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // ── Summary stats row ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatChip(
                        label: '正确率',
                        value: stat.correctRateDisplay,
                        valueBold: true,
                        valueColor: colorScheme.primary,
                      ),
                      _StatChip(
                        label: '错题本',
                        value: '${stat.activeLedgerCount}',
                        valueBold: true,
                        valueColor: stat.activeLedgerCount > 0
                            ? colorScheme.error
                            : null,
                      ),
                    ],
                  ),
                  // ── Expanded per-mode rows ──
                  if (_expanded) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    ...stat.modes.map(
                      (m) => _PerModeRow(breakdown: m),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12), // card list gap
      ],
    );
  }
}

// ── Stat chip for summary numbers ──

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    this.valueBold = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool valueBold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: valueBold ? FontWeight.w700 : FontWeight.w400,
            color: valueColor ?? Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

// ── Per-mode breakdown row (D-10) ──

class _PerModeRow extends StatelessWidget {
  const _PerModeRow({required this.breakdown});

  final ModeBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    final rateDisplay = breakdown.attempts == 0
        ? '暂无'
        : '${(breakdown.correctRate * 100).toStringAsFixed(0)}%';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(breakdown.displayName,
              style: Theme.of(context).textTheme.bodyMedium),
          const Spacer(),
          Text('${breakdown.attempts}次 · $rateDisplay',
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
