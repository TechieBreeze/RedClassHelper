// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/nav/safe_nav.dart';

import '../models/quiz_session_state.dart';
import '../models/review_mode.dart';
import '../providers/quiz_session_controller.dart';
import '../../../core/theme.dart';

/// 答题统计摘要页 —— 一轮答题结束后显示
class QuizSummaryScreen extends ConsumerWidget {
  const QuizSummaryScreen({
    super.key,
    required this.bankId,
    required this.mode,
  });

  final String bankId;
  final String mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(quizSessionControllerProvider(bankId, mode));
    final session = sessionAsync.value;

    if (session == null || session.status != QuizStatus.complete) {
      return Scaffold(
        appBar: AppBar(title: const Text('答题完成')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final total = session.totalQuestions ?? 0;
    final correct = session.correctCount ?? 0;
    final wrong = session.wrongCount ?? 0;
    final accuracyPercent = total > 0 ? ((correct / total) * 100).round() : 0;
    final isAllMastered =
        session.mode == ReviewMode.review &&
        (session.newlyMasteredCount ?? 0) > 0 &&
        wrong == 0;
    final cs = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isAllMastered ? '全部掌握' : '答题完成'),
          automaticallyImplyLeading: false,
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  child: Column(
                    children: [
                      // ── Hero banner ──
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isAllMastered
                                ? [
                                    Colors.amber.shade400,
                                    Colors.orange.shade400,
                                  ]
                                : heroGradient(
                                    cs,
                                    Theme.of(context).brightness,
                                  ),
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: (isAllMastered ? Colors.amber : cs.primary)
                                  .withAlpha(50),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Icon(
                              isAllMastered
                                  ? Icons.celebration_rounded
                                  : Icons.check_circle_rounded,
                              size: 56,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              isAllMastered ? '全部掌握!' : '$accuracyPercent%',
                              style: Theme.of(context).textTheme.displaySmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isAllMastered ? '错题本已清空' : '正确率',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Colors.white.withAlpha(200),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Stats grid ──
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryStatCard(
                              label: '答对',
                              value: '$correct',
                              unit: '/ $total 题',
                              icon: Icons.check_rounded,
                              color: cs.tertiaryContainer,
                              iconColor: cs.onTertiaryContainer,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _SummaryStatCard(
                              label: '答错',
                              value: '$wrong',
                              unit: '题',
                              icon: Icons.close_rounded,
                              color: wrong > 0
                                  ? cs.errorContainer
                                  : cs.surfaceContainerHighest,
                              iconColor: wrong > 0
                                  ? cs.onErrorContainer
                                  : cs.onSurface.withAlpha(100),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _SummaryStatCard(
                              label: '用时',
                              value: _formatElapsedShort(
                                session.elapsedSeconds ?? 0,
                              ),
                              unit: '',
                              icon: Icons.timer_outlined,
                              color: cs.secondaryContainer,
                              iconColor: cs.onSecondaryContainer,
                            ),
                          ),
                        ],
                      ),

                      if (session.newlyWrongCount != null &&
                          session.newlyWrongCount! > 0) ...[
                        const SizedBox(height: 10),
                        _DetailRow(
                          icon: Icons.add_circle_outline,
                          label: '新增错题',
                          value: '${session.newlyWrongCount} 题',
                          color: cs.error,
                        ),
                      ],
                      if (session.newlyMasteredCount != null &&
                          session.newlyMasteredCount! > 0) ...[
                        const SizedBox(height: 10),
                        _DetailRow(
                          icon: Icons.check_circle_outline,
                          label: '掌握错题',
                          value: '${session.newlyMasteredCount} 题',
                          color: cs.tertiary,
                        ),
                      ],

                      const SizedBox(height: 28),

                      // ── Action buttons ──
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          onPressed: () {
                            ref.invalidate(
                              quizSessionControllerProvider(bankId, mode),
                            );
                            if (context.canPop()) {
                              context.pop();
                            }
                            context.safePush('/quiz/$bankId/$mode');
                          },
                          child: const Text('再来一轮'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => context.go('/'),
                          child: const Text('返回主页'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SummaryStatCard extends StatelessWidget {
  const _SummaryStatCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.iconColor,
  });

  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (unit.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2, left: 2),
                    child: Text(
                      unit,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(150),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 10),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            const Spacer(),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatElapsedShort(int seconds) {
  final mins = seconds ~/ 60;
  final secs = seconds % 60;
  if (mins > 0) return '${mins}m${secs}s';
  return '${secs}s';
}
