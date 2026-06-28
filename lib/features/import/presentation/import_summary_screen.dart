// lib/features/import/presentation/import_summary_screen.dart
// ── 导入完成摘要页 ──
// 显示导入结果统计、解析来源分析和下一步操作入口。
// Phase 3 扩展：解析来源章节（D-09）+ 跳过项解析来源标注。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../parsing/llm/canonicalizer.dart';
import '../parsing/parse_candidate.dart';
import '../providers/import_notifier.dart';
import '../providers/import_state.dart';
import '../../../core/platform/responsive.dart';
import '../../../core/theme.dart';

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

    // 统计题型分布
    final typeCounts = _countByType(state.candidates, state.confirmedIndices);
    final fileName = state.files.isNotEmpty ? state.files.first.name : '未知文件';

    return Scaffold(
      appBar: AppBar(title: const Text('导入完成 ✓')),
      body: AdaptiveLayout(
        compact: (_) => KeyedSubtree(
          key: const Key('import_summary_vertical_layout'),
          child: _buildVerticalLayout(context, state, fileName, typeCounts),
        ),
        medium: (_) => KeyedSubtree(
          key: const Key('import_summary_vertical_layout'),
          child: _buildVerticalLayout(
            context,
            state,
            fileName,
            typeCounts,
            maxWidth: 600,
          ),
        ),
        expanded: (_) => KeyedSubtree(
          key: const Key('import_summary_horizontal_layout'),
          child: _buildHorizontalLayout(context, state, fileName, typeCounts),
        ),
      ),
    );
  }

  /// Compact / medium layout: vertical column with optional max-width cap.
  Widget _buildVerticalLayout(
    BuildContext context,
    ImportState state,
    String fileName,
    Map<String, int> typeCounts, {
    double? maxWidth,
  }) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── 渐变 Hero ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: heroGradient(theme.colorScheme, theme.brightness),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withAlpha(50),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 56,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '成功导入 ${state.committedCount} 道题',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
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
                      if (state.bankId.isNotEmpty)
                        _buildInfoRow(
                          context,
                          icon: Icons.tag,
                          label: '题库 ID',
                          value: state.bankId,
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
              // ── Phase 3: 解析来源章节（D-09）──
              if (state.parseSources.values.any(
                (s) => s == ParseSource.llm || s == ParseSource.fallback,
              ))
                _buildParseSourceSection(context, state),
              // ── 跳过题目列表（D-09）──
              if (state.skippedCandidates.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildSkippedSection(context),
              ],
              const SizedBox(height: 32),

              // ── CTA 按钮 ──
              FilledButton.icon(
                onPressed: () {
                  final bankId = state.bankId;
                  ref.read(importNotifierProvider.notifier).reset();
                  // 开始复习：用 push 把 quiz 叠在 summary 上方，
                  // quiz 关闭时 pop 回 summary（tab-like 导航）。
                  context.push('/quiz/$bankId/random');
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('开始复习'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  /// Expanded layout: 2-column (hero on left, details + CTA on right).
  Widget _buildHorizontalLayout(
    BuildContext context,
    ImportState state,
    String fileName,
    Map<String, int> typeCounts,
  ) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Left: hero gradient card ──
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Container(
                  width: 320,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: heroGradient(theme.colorScheme, theme.brightness),
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withAlpha(50),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 56,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '成功导入 ${state.committedCount} 道题',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 32),

              // ── Right: details + parse sources + skipped + CTA ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                            if (state.bankId.isNotEmpty)
                              _buildInfoRow(
                                context,
                                icon: Icons.tag,
                                label: '题库 ID',
                                value: state.bankId,
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
                    if (state.parseSources.values.any(
                      (s) => s == ParseSource.llm || s == ParseSource.fallback,
                    ))
                      _buildParseSourceSection(context, state),
                    if (state.skippedCandidates.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildSkippedSection(context),
                    ],
                    const SizedBox(height: 32),
                    FilledButton.icon(
                      onPressed: () {
                        final bankId = state.bankId;
                        ref.read(importNotifierProvider.notifier).reset();
                        // 开始复习：用 push 叠在 summary 上方（tab-like 导航）。
                        context.push('/quiz/$bankId/random');
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('开始复习'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
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
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange.shade700,
                  size: 20,
                ),
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
              final source = state.parseSources[item.index];

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '#$displayIndex: ${item.reason}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.orange.shade900,
                                  ),
                                ),
                              ),
                              if (source != null)
                                Text(
                                  _sourceLabel(source),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: _sourceColor(source),
                                  ),
                                ),
                            ],
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
                        // 手动编辑：用 push 把 preview 叠在 summary 上方，
                        // preview 关闭时 pop 回 summary（tab-like 导航）。
                        context.push('/import/preview/${state.jobId}');
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

  // ── Phase 3: 解析来源章节（D-09）──

  /// "解析来源"章节——仅 LLM 导入时显示。
  Widget _buildParseSourceSection(BuildContext context, ImportState state) {
    final theme = Theme.of(context);
    final llmCount = state.parseSources.values
        .where((s) => s == ParseSource.llm)
        .length;
    final heuristicCount = state.parseSources.values
        .where((s) => s == ParseSource.heuristic)
        .length;
    final fallbackCount = state.parseSources.values
        .where((s) => s == ParseSource.fallback)
        .length;

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '解析来源',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _sourceRow(
                context,
                icon: Icons.psychology,
                label: 'LLM 解析',
                count: llmCount,
                color: Colors.teal,
                showCheck: llmCount > 0,
              ),
              _sourceRow(
                context,
                icon: Icons.bolt,
                label: '启发式解析',
                count: heuristicCount,
                color: theme.colorScheme.secondary,
              ),
              _sourceRow(
                context,
                icon: Icons.swap_horiz,
                label: '兜底解析',
                count: fallbackCount,
                color: Colors.amber.shade700,
                subtitle: '(LLM 失败后启发式重试)',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sourceRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int count,
    required Color color,
    bool showCheck = false,
    String? subtitle,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(label, style: theme.textTheme.bodyMedium),
                    const SizedBox(width: 8),
                    Text(
                      '$count 题',
                      style: theme.textTheme.labelLarge?.copyWith(color: color),
                    ),
                    if (showCheck) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                    ],
                  ],
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _sourceLabel(ParseSource source) {
    return switch (source) {
      ParseSource.llm => 'LLM',
      ParseSource.heuristic => '启发式',
      ParseSource.fallback => '兜底',
    };
  }

  Color _sourceColor(ParseSource source) {
    return switch (source) {
      ParseSource.llm => Colors.teal,
      ParseSource.heuristic => Theme.of(context).colorScheme.secondary,
      ParseSource.fallback => Colors.amber.shade700,
    };
  }
}
