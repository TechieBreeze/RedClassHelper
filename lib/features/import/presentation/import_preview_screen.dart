// lib/features/import/presentation/import_preview_screen.dart
// ── 导入预览编辑页 ──
// 展示解析出的候选题目，支持审核、编辑、删除和保存。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../parsing/parse_candidate.dart';
import '../providers/import_notifier.dart';
import '../providers/import_state.dart';
import '../widgets/candidate_card.dart';

/// 导入预览编辑页——审核解析出的候选题目。
///
/// 路径参数：:jobId —— 解析任务 ID。
/// 从 ImportNotifier 读取候选列表和确认集合。
class ImportPreviewScreen extends ConsumerStatefulWidget {
  const ImportPreviewScreen({super.key});

  @override
  ConsumerState<ImportPreviewScreen> createState() =>
      _ImportPreviewScreenState();
}

class _ImportPreviewScreenState extends ConsumerState<ImportPreviewScreen> {
  CandidateType? _filterType;
  bool _selectAll = true;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(importNotifierProvider);
    final candidates = state.candidates;
    final confirmedIndices = state.confirmedIndices;

    // 题型筛选
    final filteredCandidates = _filterType == null
        ? candidates
        : candidates
            .asMap()
            .entries
            .where((e) => e.value.candidateType == _filterType)
            .toList();

    // 是否有修改
    final hasModifications = confirmedIndices.length != candidates.length ||
        candidates.any((c) => c.confidence < 0.5);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          final confirmed = await _showExitDialog();
          if (confirmed == true && context.mounted) {
            ref.read(importNotifierProvider.notifier).reset();
            context.go('/');
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '审核结果（${confirmedIndices.length}/${candidates.length}）',
          ),
          actions: [
            if (confirmedIndices.isNotEmpty)
              FilledButton(
                onPressed: () => _onSave(context),
                child: const Text('保存'),
              ),
            if (confirmedIndices.isEmpty)
              FilledButton(
                onPressed: null,
                child: const Text('保存'),
              ),
            const SizedBox(width: 8),
          ],
        ),
        body: candidates.isEmpty
            ? _buildEmptyState(context)
            : Column(
                children: [
                  // ── 底部 Sheet：批量操作 + 题型筛选 ──
                  _buildToolbar(context, confirmedIndices, candidates),
                  // ── 候选列表 ──
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: filteredCandidates.length,
                      itemBuilder: (context, index) {
                        final entry = _filterType == null
                            ? MapEntry(index, candidates[index])
                            : filteredCandidates[index];
                        final i = entry.key;
                        final candidate = entry.value;
                        final isConfirmed = confirmedIndices.contains(i);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: CandidateCard(
                            candidate: candidate,
                            index: i,
                            total: candidates.length,
                            isConfirmed: isConfirmed,
                            onToggleConfirm: () {
                              ref
                                  .read(importNotifierProvider.notifier)
                                  .toggleCandidate(i);
                            },
                            onTypeChanged: (type) {
                              ref
                                  .read(importNotifierProvider.notifier)
                                  .setCandidateType(i, type);
                            },
                            onOptionsChanged: (options) {
                              ref
                                  .read(importNotifierProvider.notifier)
                                  .setCandidateOptions(i, options);
                            },
                            onAnswerChanged: (answer) {
                              ref
                                  .read(importNotifierProvider.notifier)
                                  .setCandidateAnswer(i, answer);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildToolbar(
    BuildContext context,
    Set<int> confirmedIndices,
    List<ParseCandidate> candidates,
  ) {
    final theme = Theme.of(context);
    final types = candidates.map((c) => c.candidateType).toSet().toList();

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          top: BorderSide(color: theme.dividerColor),
          bottom: BorderSide(color: theme.dividerColor),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 批量操作
          Row(
            children: [
              TextButton.icon(
                onPressed: _toggleSelectAll,
                icon: Icon(_selectAll
                    ? Icons.deselect
                    : Icons.select_all),
                label: Text(_selectAll ? '取消全选' : '全选'),
              ),
              const Spacer(),
              Text(
                '已选 ${confirmedIndices.length}/${candidates.length}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),

          // 题型筛选芯片
          if (types.length > 1) ...[
            const SizedBox(height: 4),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('全部'),
                    selected: _filterType == null,
                    onSelected: (_) =>
                        setState(() => _filterType = null),
                  ),
                  const SizedBox(width: 8),
                  ...types.map(
                    (t) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(_typeLabel(t)),
                        selected: _filterType == t,
                        onSelected: (selected) => setState(
                          () => _filterType = selected ? t : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            '未解析到题目',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '请检查文件格式或尝试手动创建题库',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  // ── 操作 ──

  void _toggleSelectAll() {
    final notifier = ref.read(importNotifierProvider.notifier);
    final candidates = ref.read(importNotifierProvider).candidates;

    setState(() => _selectAll = !_selectAll);

    if (_selectAll) {
      for (var i = 0; i < candidates.length; i++) {
        if (!ref.read(importNotifierProvider).confirmedIndices.contains(i)) {
          notifier.toggleCandidate(i);
        }
      }
    } else {
      for (final i in ref
          .read(importNotifierProvider)
          .confirmedIndices
          .toList()) {
        notifier.toggleCandidate(i);
      }
    }
  }

  Future<bool?> _showExitDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('退出审核'),
        content: const Text('未保存的编辑将会丢失，确定退出？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('继续审核'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('退出'),
          ),
        ],
      ),
    );
  }

  Future<void> _onSave(BuildContext context) async {
    final notifier = ref.read(importNotifierProvider.notifier);
    await notifier.commitToDatabase();

    final state = ref.read(importNotifierProvider);
    if (state.isDone && mounted) {
      context.go('/import/summary/${state.jobId}');
    }
  }

  String _typeLabel(CandidateType type) {
    return switch (type) {
      CandidateType.singleChoice => '单选',
      CandidateType.multiChoice => '多选',
      CandidateType.trueFalse => '判断',
      CandidateType.shortAnswer => '简答',
      CandidateType.unknown => '未知',
    };
  }
}
