// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/quiz_session_state.dart';
import '../models/review_mode.dart';
import '../providers/quiz_session_controller.dart';

/// 答题统计摘要页 —— 一轮答题结束后显示 (D-11, D-12)。
///
/// 显示正确率、答对/答错数、总用时、新增错题/掌握错题数。
/// 提供"再来一轮"和"返回主页"两个操作按钮。
/// 错题复习模式全部掌握时显示庆祝提示 (D-13)。
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
    final sessionAsync = ref.watch(
      quizSessionControllerProvider(bankId, mode),
    );
    final session = sessionAsync.value;

    // Guard: session not yet ready or not complete
    if (session == null || session.status != QuizStatus.complete) {
      return Scaffold(
        appBar: AppBar(title: const Text('答题完成')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final total = session.totalQuestions ?? 0;
    final correct = session.correctCount ?? 0;
    final wrong = session.wrongCount ?? 0;
    final accuracyPercent =
        total > 0 ? ((correct / total) * 100).round() : 0;
    final isAllMastered = session.mode == ReviewMode.review &&
        (session.newlyMasteredCount ?? 0) > 0 &&
        wrong == 0;

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isAllMastered ? '全部掌握' : '答题完成 ✓'),
          automaticallyImplyLeading: false,
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 24,
                  ),
                  child: Column(
                    children: [
                      if (isAllMastered) _buildAllMasteredCelebration(context),
                      if (!isAllMastered)
                        _buildScoreHeader(context, accuracyPercent),
                      const SizedBox(height: 24),
                      _buildStatsCard(context, session),
                      if (isAllMastered) const SizedBox(height: 24),
                      const SizedBox(height: 32),
                      _buildActionButtons(context, ref),
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

  Widget _buildScoreHeader(BuildContext context, int accuracyPercent) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(
          Icons.check_circle,
          size: 64,
          color: Colors.green.shade600,
        ),
        const SizedBox(height: 16),
        Text(
          '$accuracyPercent%',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          '正确率',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildStatsCard(BuildContext context, QuizSessionState session) {
    final total = session.totalQuestions ?? 0;
    final correct = session.correctCount ?? 0;
    final wrong = session.wrongCount ?? 0;
    final elapsedSeconds = session.elapsedSeconds ?? 0;
    final newlyWrong = session.newlyWrongCount ?? 0;
    final newlyMastered = session.newlyMasteredCount ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _StatRow(label: '答对', value: '$correct / $total 题'),
            const Divider(),
            _StatRow(label: '答错', value: '$wrong 题'),
            const Divider(),
            _StatRow(label: '总用时', value: _formatElapsed(elapsedSeconds)),
            if (newlyWrong > 0) ...[
              const Divider(),
              _StatRow(label: '新增错题', value: '$newlyWrong 题'),
            ],
            if (newlyMastered > 0) ...[
              const Divider(),
              _StatRow(label: '掌握错题', value: '$newlyMastered 题'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAllMasteredCelebration(BuildContext context) {
    return Card(
      color: Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Text('🎉', style: TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '全部掌握！错题本已清空',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            onPressed: () {
              ref.invalidate(quizSessionControllerProvider(bankId, mode));
              context.go('/quiz/$bankId/$mode');
            },
            child: const Text('再来一轮'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => context.go('/'),
            child: const Text('返回主页'),
          ),
        ),
      ],
    );
  }
}

String _formatElapsed(int seconds) {
  final mins = seconds ~/ 60;
  final secs = seconds % 60;
  if (mins > 0) {
    return '$mins 分 $secs 秒';
  }
  return '$secs 秒';
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: textTheme.bodyMedium),
          Text(
            value,
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
