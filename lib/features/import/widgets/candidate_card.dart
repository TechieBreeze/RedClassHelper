// lib/features/import/widgets/candidate_card.dart
// ── 候选题目卡片 ──
// ImportPreviewScreen 中每个 ParseCandidate 的可编辑卡片。

import 'package:flutter/material.dart';

import '../parsing/parse_candidate.dart';

/// 显示单个 [ParseCandidate] 的卡片，支持编辑和删除。
class CandidateCard extends StatefulWidget {
  const CandidateCard({
    required this.candidate,
    required this.index,
    required this.total,
    required this.isConfirmed,
    required this.onToggleConfirm,
    required this.onTypeChanged,
    required this.onOptionsChanged,
    required this.onAnswerChanged,
    super.key,
  });

  /// 候选题目数据
  final ParseCandidate candidate;

  /// 在列表中的索引（0-based）
  final int index;

  /// 题目总数
  final int total;

  /// 是否已确认（在 confirmedIndices 中）
  final bool isConfirmed;

  /// 切换确认状态回调
  final VoidCallback onToggleConfirm;

  /// 题型变更回调
  final void Function(CandidateType type) onTypeChanged;

  /// 选项变更回调
  final void Function(List<String> options) onOptionsChanged;

  /// 答案变更回调
  final void Function(String answer) onAnswerChanged;

  @override
  State<CandidateCard> createState() => _CandidateCardState();
}

class _CandidateCardState extends State<CandidateCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = widget.candidate;
    final isLowConfidence = c.confidence < 0.5;

    return Card(
      elevation: widget.isConfirmed ? 1 : 0,
      color: widget.isConfirmed
          ? null
          : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 头部：题号 + 题型标签 + 置信度标记 ──
              Row(
                children: [
                  // 题号
                  Text(
                    '${widget.index + 1}/${widget.total}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 题型标签
                  _TypeChip(type: c.candidateType),
                  const SizedBox(width: 8),

                  // 低置信度标记
                  if (isLowConfidence) ...[
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '可能需要人工复核',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],

                  const Spacer(),

                  // 确认复选框
                  Checkbox(
                    value: widget.isConfirmed,
                    onChanged: (_) => widget.onToggleConfirm(),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // ── 题干 ──
              Text(
                c.title.isNotEmpty ? c.title : c.rawText,
                style: theme.textTheme.bodyMedium,
                maxLines: _expanded ? null : 3,
                overflow: _expanded ? null : TextOverflow.ellipsis,
              ),

              // ── 选项预览 ──
              if (c.options.isNotEmpty) ...[
                const SizedBox(height: 8),
                ...c.options.take(_expanded ? c.options.length : 2).map(
                      (opt) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          opt,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ),
                if (!_expanded && c.options.length > 2)
                  Text(
                    '…还有 ${c.options.length - 2} 个选项',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
              ],

              // ── 展开编辑区域 ──
              if (_expanded) ...[
                const Divider(height: 24),

                // 题型选择器
                _buildTypeSelector(context),
                const SizedBox(height: 16),

                // 选项编辑
                if (c.candidateType == CandidateType.singleChoice ||
                    c.candidateType == CandidateType.multiChoice) ...[
                  _buildOptionsEditor(context),
                  const SizedBox(height: 16),
                ],

                // 答案编辑
                _buildAnswerEditor(context),

                // 判断题答案编辑
                if (c.candidateType == CandidateType.trueFalse) ...[
                  const SizedBox(height: 16),
                  _buildTrueFalseEditor(context),
                ],
              ],

              // ── 展开/收起提示 ──
              if (!_expanded)
                Align(
                  alignment: Alignment.centerRight,
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    size: 20,
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector(BuildContext context) {
    return Row(
      children: [
        Text('题型：', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(width: 8),
        Expanded(
          child: SegmentedButton<CandidateType>(
            segments: const [
              ButtonSegment(
                value: CandidateType.singleChoice,
                label: Text('单选'),
              ),
              ButtonSegment(
                value: CandidateType.multiChoice,
                label: Text('多选'),
              ),
              ButtonSegment(
                value: CandidateType.trueFalse,
                label: Text('判断'),
              ),
              ButtonSegment(
                value: CandidateType.shortAnswer,
                label: Text('简答'),
              ),
            ],
            selected: {widget.candidate.candidateType},
            onSelectionChanged: (set) {
              if (set.isNotEmpty) widget.onTypeChanged(set.first);
            },
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionsEditor(BuildContext context) {
    final options = widget.candidate.options;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('选项：', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        ...List.generate(options.length, (i) {
          final label = String.fromCharCode('A'.codeUnitAt(0) + i);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: Text('$label.',
                      style: Theme.of(context).textTheme.labelMedium),
                ),
                Expanded(
                  child: TextFormField(
                    initialValue: options[i].replaceFirst(
                        RegExp(r'^[A-H][.、．]\s*'), ''),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      final updated = List<String>.from(options);
                      updated[i] = '$label. $value';
                      widget.onOptionsChanged(updated);
                    },
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAnswerEditor(BuildContext context) {
    return Row(
      children: [
        Text('答案：', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(width: 8),
        SizedBox(
          width: 120,
          child: TextFormField(
            initialValue: widget.candidate.answer,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '如 A',
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
            onChanged: widget.onAnswerChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildTrueFalseEditor(BuildContext context) {
    final isTrue = widget.candidate.answer.toUpperCase().contains('A') ||
        widget.candidate.answer.contains('对') ||
        widget.candidate.answer.contains('正') ||
        widget.candidate.answer.contains('✓') ||
        widget.candidate.answer.contains('✔');
    final isFalse = widget.candidate.answer.toUpperCase().contains('B') ||
        widget.candidate.answer.contains('错') ||
        widget.candidate.answer.contains('误') ||
        widget.candidate.answer.contains('✗') ||
        widget.candidate.answer.contains('✘');

    return Row(
      children: [
        Text('答案：', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(width: 8),
        ChoiceChip(
          label: const Text('正确'),
          selected: isTrue,
          onSelected: (_) => widget.onAnswerChanged('正确'),
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: const Text('错误'),
          selected: isFalse,
          onSelected: (_) => widget.onAnswerChanged('错误'),
        ),
      ],
    );
  }
}

/// 题型标签小组件
class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.type});
  final CandidateType type;

  @override
  Widget build(BuildContext context) {
    final (label, icon) = switch (type) {
      CandidateType.singleChoice => ('单选', Icons.radio_button_checked),
      CandidateType.multiChoice => ('多选', Icons.check_box),
      CandidateType.trueFalse => ('判断', Icons.thumbs_up_down),
      CandidateType.shortAnswer => ('简答', Icons.short_text),
      CandidateType.unknown => ('未知', Icons.help_outline),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
