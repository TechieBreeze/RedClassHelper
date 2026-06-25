// lib/features/stats/presentation/stats_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/platform/responsive.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/hoverable_card.dart';
import '../providers/stats_provider.dart';

/// 数据统计 screen
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(bankStatsListProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('数据统计'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
            tooltip: '设置',
          ),
        ],
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: cs.error),
              const SizedBox(height: 16),
              Text('加载失败', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(bankStatsListProvider),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('重试'),
              ),
            ],
          ),
        ),
        data: (stats) {
          if (stats.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.insights_rounded, size: 48, color: cs.outline),
                  const SizedBox(height: 16),
                  Text('暂无统计数据', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    '完成答题后会显示各题库的正确率统计',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurface.withAlpha(150),
                    ),
                  ),
                ],
              ),
            );
          }
          return _DataState(stats: stats);
        },
      ),
    );
  }
}

class _DataState extends StatelessWidget {
  const _DataState({required this.stats});
  final List<BankStats> stats;

  @override
  Widget build(BuildContext context) {
    // Calculate totals
    final totalQuestions = stats.fold<int>(0, (s, b) => s + b.totalQuestions);
    final totalAttempts = stats.fold<int>(0, (s, b) => s + b.totalAttempts);
    final totalCorrect = stats.fold<int>(0, (s, b) => s + b.correctCount);
    final overallRate = totalAttempts > 0
        ? (totalCorrect / totalAttempts)
        : 0.0;

    return AdaptiveLayout(
      compact: (_) => KeyedSubtree(
        key: const Key('stats_vertical_layout'),
        child: _buildVerticalLayout(
          context,
          stats,
          totalQuestions,
          totalAttempts,
          totalCorrect,
          overallRate,
        ),
      ),
      medium: (_) => KeyedSubtree(
        key: const Key('stats_vertical_layout'),
        child: _buildVerticalLayout(
          context,
          stats,
          totalQuestions,
          totalAttempts,
          totalCorrect,
          overallRate,
          maxWidth: 720,
        ),
      ),
      expanded: (_) => KeyedSubtree(
        key: const Key('stats_horizontal_layout'),
        child: _buildHorizontalLayout(
          context,
          stats,
          totalQuestions,
          totalAttempts,
          totalCorrect,
          overallRate,
        ),
      ),
    );
  }

  Widget _buildVerticalLayout(
    BuildContext context,
    List<BankStats> stats,
    int totalQuestions,
    int totalAttempts,
    int totalCorrect,
    double overallRate, {
    double? maxWidth,
  }) {
    final cs = Theme.of(context).colorScheme;
    final listView = ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      children: [
        // ── Overall hero ──
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: heroGradient(cs, Theme.of(context).brightness),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: cs.primary.withAlpha(50),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                '${(overallRate * 100).round()}%',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '总正确率',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withAlpha(200),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _HeroMiniStat(label: '总题数', value: '$totalQuestions'),
                  _HeroMiniStat(label: '答题次数', value: '$totalAttempts'),
                  _HeroMiniStat(label: '答对', value: '$totalCorrect'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── Per-bank cards ──
        Text(
          '各题库统计',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        for (final stat in stats) ...[
          _StatsBankCard(stat: stat),
          const SizedBox(height: 10),
        ],
      ],
    );

    if (maxWidth == null) return listView;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: listView,
      ),
    );
  }

  Widget _buildHorizontalLayout(
    BuildContext context,
    List<BankStats> stats,
    int totalQuestions,
    int totalAttempts,
    int totalCorrect,
    double overallRate,
  ) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      children: [
        // ── Overall hero (full-width on top) ──
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: heroGradient(cs, Theme.of(context).brightness),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: cs.primary.withAlpha(50),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                '${(overallRate * 100).round()}%',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '总正确率',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withAlpha(200),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _HeroMiniStat(label: '总题数', value: '$totalQuestions'),
                  _HeroMiniStat(label: '答题次数', value: '$totalAttempts'),
                  _HeroMiniStat(label: '答对', value: '$totalCorrect'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── Per-bank cards: 2-column grid ──
        Text(
          '各题库统计',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final stat in stats)
                  SizedBox(
                    width: (constraints.maxWidth - 12) / 2,
                    child: _StatsBankCard(stat: stat),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _HeroMiniStat extends StatelessWidget {
  const _HeroMiniStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: Colors.white.withAlpha(170)),
        ),
      ],
    );
  }
}

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
    final cs = Theme.of(context).colorScheme;

    return HoverableCard(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [cs.primaryContainer, cs.primary.withAlpha(60)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.menu_book_rounded,
                    size: 22,
                    color: cs.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stat.bank.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${stat.totalQuestions} 题 · ${stat.totalAttempts} 次答题',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withAlpha(150),
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.expand_more, color: cs.outline),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    label: '正确率',
                    value: stat.correctRateDisplay,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniStat(
                    label: '错题本',
                    value: '${stat.activeLedgerCount}',
                    color: stat.activeLedgerCount > 0
                        ? cs.error
                        : cs.onSurface.withAlpha(150),
                  ),
                ),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              ...stat.modes.map((m) => _PerModeRow(breakdown: m)),
            ],
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withAlpha(120),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: color,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

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
          Text(
            breakdown.displayName,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const Spacer(),
          Text(
            '${breakdown.attempts} 次 · $rateDisplay',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
            ),
          ),
        ],
      ),
    );
  }
}
