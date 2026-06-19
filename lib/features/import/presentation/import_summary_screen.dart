// lib/features/import/presentation/import_summary_screen.dart
// ── 导入完成摘要页 ──
// 显示导入结果统计和下一步操作入口。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;

import '../parsing/parse_candidate.dart';
import '../providers/import_notifier.dart';

/// 导入完成摘要页——展示导入结果后引导用户开始复习。
///
/// 路径参数：:jobId —— 解析任务 ID。
/// 从 ImportNotifier 读取结果数据。
class ImportSummaryScreen extends ConsumerStatefulWidget {
  const ImportSummaryScreen({super.key});

  @override
  ConsumerState<ImportSummaryScreen> createState() =>
      _ImportSummaryScreenState();
}

class _ImportSummaryScreenState extends ConsumerState<ImportSummaryScreen> {
  @override
  void initState() {
    super.initState();
    // 如果状态不是 done 且没有提交结果，返回首页
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(importNotifierProvider);
      if (!state.isDone && state.committedCount == 0) {
        if (mounted) context.go('/');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(importNotifierProvider);
    final theme = Theme.of(context);

    // 统计题型分布
    final typeCounts = _countByType(state.candidates, state.confirmedIndices);
    final fileName = state.files.isNotEmpty
        ? p.basename(state.files.first.path)
        : '未知文件';

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('导入完成 ✓'),
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── 成功图标 ──
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.green.shade600,
                  ),
                  const SizedBox(height: 16),

                  // ── 主标题 ──
                  Text(
                    '成功导入 ${state.committedCount} 道题',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // ── 详情卡片 ──
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(
                            context,
                            icon: Icons.library_books,
                            label: '题库名称',
                            value: state.bankName,
                          ),
                          const Divider(height: 16),
                          _buildInfoRow(
                            context,
                            icon: Icons.insert_drive_file_outlined,
                            label: '源文件',
                            value: fileName,
                          ),
                          const Divider(height: 16),
                          _buildInfoRow(
                            context,
                            icon: Icons.tag,
                            label: '题库 ID',
                            value: state.jobId,
                            monospace: true,
                          ),
                          if (typeCounts.isNotEmpty) ...[
                            const Divider(height: 16),
                            _buildTypeBreakdown(context, typeCounts),
                          ],
                        ],
                      ),
                    ),
                  ),
                  // ── 跳过题目列表（D-09）──
                  if (state.skippedCandidates.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildSkippedSection(context),
                  ],
                  const SizedBox(height: 32),

                  // ── CTA 按钮 ──
                  FilledButton.icon(
                    onPressed: () {
                      ref.read(importNotifierProvider.notifier).reset();
                      // 使用 bankId（即 jobId）导航到复习页面
                      context.go('/quiz/${state.jobId}/random');
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('开始复习'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () {
                      ref.read(importNotifierProvider.notifier).reset();
                      context.go('/');
                    },
                    child: const Text('返回首页'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool monospace = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: monospace
                    ? Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                          fontSize: 13,
                        )
                    : Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypeBreakdown(
    BuildContext context,
    Map<String, int> typeCounts,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '题型分布',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.6),
              ),
        ),
        const SizedBox(height: 8),
        ...typeCounts.entries.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Expanded(child: Text(e.key)),
                Text(
                  '${e.value} 道',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkippedSection(BuildContext context) {
    final state = ref.watch(importNotifierProvider);
    final theme = Theme.of(context);
    final skipped = state.skippedCandidates;

    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.orange.shade700, size: 20),
                const SizedBox(width: 8),
                Text(
                  '⚠ 跳过 ${skipped.length} 题',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.orange.shade900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...skipped.map((item) {
              final displayIndex = item.index + 1; // 人类可读编号从1开始
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#$displayIndex: ${item.reason}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.orange.shade900,
                            ),
                          ),
                          if (item.candidate.title.isNotEmpty)
                            Text(
                              item.candidate.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.orange.shade700,
                              ),
                            ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ref
                            .read(importNotifierProvider.notifier)
                            .retryParseCandidate(item.index);
                        setState(() {}); // 刷新 UI
                      },
                      child: const Text('重试'),
                    ),
                    TextButton(
                      onPressed: () {
                        // 手动编辑：导航回预览页
                        context.go('/import/preview/${state.jobId}');
                      },
                      child: const Text('手动编辑'),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Map<String, int> _countByType(
    List<ParseCandidate> candidates,
    Set<int> confirmedIndices,
  ) {
    final counts = <String, int>{};
    for (final i in confirmedIndices) {
      if (i < candidates.length) {
        final type = candidates[i].candidateType;
        final label = switch (type) {
          CandidateType.singleChoice => '单选题',
          CandidateType.multiChoice => '多选题',
          CandidateType.trueFalse => '判断题',
          CandidateType.shortAnswer => '简答题',
          CandidateType.unknown => '其他',
        };
        counts[label] = (counts[label] ?? 0) + 1;
      }
    }
    return counts;
  }
}
