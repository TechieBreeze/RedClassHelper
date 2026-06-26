// lib/features/import/presentation/import_preview_screen.dart
// ── 导入预览编辑页 ──
// 展示解析出的候选题目，支持审核、编辑、删除和保存。
// Phase 3 扩展：LLM 解析结果自动确认 + 解析来源徽章（D-08）。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/platform/responsive.dart';
import '../parsing/llm/canonicalizer.dart';
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
  bool _isSaving = false;

  late final TextEditingController _bankNameController;
  String? _bankNameError;
  bool _isLlmImport = false;

  @override
  void initState() {
    super.initState();
    // 从 state 初始化 controller
    final bankName = ref.read(importNotifierProvider).bankName;
    _bankNameController = TextEditingController(text: bankName);

    // 判断是否为 LLM 导入
    _isLlmImport = ref
        .read(importNotifierProvider)
        .parseSources
        .values
        .any((s) => s == ParseSource.llm || s == ParseSource.fallback);

    // jobId 有效性守卫——过期路由重定向到首页
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(importNotifierProvider);
      if (!state.isEditing && !state.isCommitting) {
        if (mounted) context.go('/');
      }
    });
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(importNotifierProvider);
    final candidates = state.candidates;
    final confirmedIndices = state.confirmedIndices;

    // 题型筛选
    final filteredCandidates = _filterType == null
        ? candidates.asMap().entries.toList()
        : candidates
              .asMap()
              .entries
              .where((e) => e.value.candidateType == _filterType)
              .toList();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) await _onDiscard(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('审核结果（${confirmedIndices.length}/${candidates.length}）'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: '放弃并返回',
            onPressed: () => _onDiscard(context),
          ),
          actions: [
            if (state.isCommitting || _isSaving)
              FilledButton(
                onPressed: null,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('保存中...'),
                  ],
                ),
              )
            else
              FilledButton(
                onPressed: confirmedIndices.isNotEmpty
                    ? () => _onSave(context)
                    : null,
                child: const Text('保存'),
              ),
            const SizedBox(width: 8),
          ],
        ),
        body: candidates.isEmpty
            ? _buildEmptyState(context)
            : AdaptiveLayout(
                compact: (_) => KeyedSubtree(
                  key: const Key('import_preview_vertical_layout'),
                  child: _buildVerticalLayout(
                    context,
                    state,
                    candidates,
                    confirmedIndices,
                    filteredCandidates,
                  ),
                ),
                medium: (_) => KeyedSubtree(
                  key: const Key('import_preview_vertical_layout'),
                  child: _buildVerticalLayout(
                    context,
                    state,
                    candidates,
                    confirmedIndices,
                    filteredCandidates,
                    maxWidth: 720,
                  ),
                ),
                expanded: (_) => KeyedSubtree(
                  key: const Key('import_preview_horizontal_layout'),
                  child: _buildHorizontalLayout(
                    context,
                    state,
                    candidates,
                    confirmedIndices,
                  ),
                ),
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
                icon: Icon(_selectAll ? Icons.deselect : Icons.select_all),
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
                    onSelected: (_) => setState(() => _filterType = null),
                  ),
                  const SizedBox(width: 8),
                  ...types.map(
                    (t) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(_typeLabel(t)),
                        selected: _filterType == t,
                        onSelected: (selected) =>
                            setState(() => _filterType = selected ? t : null),
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
          Text('未解析到题目', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            '请检查文件格式或尝试手动创建题库',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  // ── Phase 4 响应式布局 (Task 15) ──

  /// Compact / medium 共用的纵向布局。
  ///
  /// medium slot 传入 [maxWidth] 时，会在 Column 外再包一层
  /// `Center > ConstrainedBox(maxWidth: ...)`，让平板用户拥有舒适的阅读宽度。
  /// compact slot 传 null，保持原 mobile 行为不变。
  Widget _buildVerticalLayout(
    BuildContext context,
    ImportState state,
    List<ParseCandidate> candidates,
    Set<int> confirmedIndices,
    List<MapEntry<int, ParseCandidate>> filteredCandidates, {
    double? maxWidth,
  }) {
    final content = Column(
      children: [
        // ── Phase 3: LLM 自动确认横幅（D-08）──
        if (_isLlmImport)
          _buildAutoConfirmBanner(context, confirmedIndices.length),

        // ── 题库名称编辑区（D-18 CJK 感知）──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: _bankNameController,
            decoration: InputDecoration(
              labelText: '题库名称',
              hintText: '输入题库名称',
              errorText: _bankNameError,
              helperText: '中文/全角=2字符，ASCII=1字符，上限100',
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (value) {
              setState(() => _bankNameError = _validateBankName(value));
              if (_bankNameError == null) {
                ref
                    .read(importNotifierProvider.notifier)
                    .setBankName(value.trim());
              }
            },
          ),
        ),
        // ── 底部 Sheet：批量操作 + 题型筛选 ──
        _buildToolbar(context, confirmedIndices, candidates),
        // ── Phase 3: 解析来源摘要行 ──
        if (state.parseSources.isNotEmpty) _buildSourceSummary(context, state),
        // ── 候选列表（移动端纵向滚动）──
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: filteredCandidates.length,
            itemBuilder: (context, index) {
              final entry = filteredCandidates[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildCandidateColumn(
                  context,
                  state,
                  entry.key,
                  entry.value,
                  confirmedIndices,
                  candidates.length,
                ),
              );
            },
          ),
        ),
      ],
    );

    if (maxWidth == null) return content;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: content,
      ),
    );
  }

  /// Expanded 专用横向布局：hero 段保持 960 上限，候选列表换成 2 列 Wrap 网格。
  Widget _buildHorizontalLayout(
    BuildContext context,
    ImportState state,
    List<ParseCandidate> candidates,
    Set<int> confirmedIndices,
  ) {
    final filtered = _filterType == null
        ? candidates.asMap().entries.toList()
        : candidates
              .asMap()
              .entries
              .where((e) => e.value.candidateType == _filterType)
              .toList();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: Column(
          children: [
            // ── Phase 3: LLM 自动确认横幅（D-08）──
            if (_isLlmImport)
              _buildAutoConfirmBanner(context, confirmedIndices.length),

            // ── 题库名称编辑区（D-18 CJK 感知）──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                controller: _bankNameController,
                decoration: InputDecoration(
                  labelText: '题库名称',
                  hintText: '输入题库名称',
                  errorText: _bankNameError,
                  helperText: '中文/全角=2字符，ASCII=1字符，上限100',
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (value) {
                  setState(() => _bankNameError = _validateBankName(value));
                  if (_bankNameError == null) {
                    ref
                        .read(importNotifierProvider.notifier)
                        .setBankName(value.trim());
                  }
                },
              ),
            ),
            // ── 底部 Sheet：批量操作 + 题型筛选 ──
            _buildToolbar(context, confirmedIndices, candidates),
            // ── Phase 3: 解析来源摘要行 ──
            if (state.parseSources.isNotEmpty)
              _buildSourceSummary(context, state),
            // ── 候选列表（桌面端 2 列 Wrap 网格）──
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final entry in filtered)
                          SizedBox(
                            width: (constraints.maxWidth - 12) / 2,
                            child: _buildCandidateColumn(
                              context,
                              state,
                              entry.key,
                              entry.value,
                              confirmedIndices,
                              candidates.length,
                            ),
                          ),
                      ],
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

  /// 单个候选的内容块：解析来源徽章 + CandidateCard。
  ///
  /// 纵向 slot (ListView itemBuilder) 与横向 slot (Wrap children) 共享同一棵 widget 树，
  /// 保证两端的视觉/交互完全一致。
  Widget _buildCandidateColumn(
    BuildContext context,
    ImportState state,
    int index,
    ParseCandidate candidate,
    Set<int> confirmedIndices,
    int totalCount,
  ) {
    final isConfirmed = confirmedIndices.contains(index);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Parse source badge
        if (state.parseSources.containsKey(index))
          Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 4),
            child: _ParseSourceBadge(source: state.parseSources[index]!),
          ),
        CandidateCard(
          candidate: candidate,
          index: index,
          total: totalCount,
          isConfirmed: isConfirmed,
          onToggleConfirm: () {
            ref.read(importNotifierProvider.notifier).toggleCandidate(index);
          },
          onTypeChanged: (type) {
            ref
                .read(importNotifierProvider.notifier)
                .setCandidateType(index, type);
          },
          onOptionsChanged: (options) {
            ref
                .read(importNotifierProvider.notifier)
                .setCandidateOptions(index, options);
          },
          onAnswerChanged: (answer) {
            ref
                .read(importNotifierProvider.notifier)
                .setCandidateAnswer(index, answer);
          },
        ),
      ],
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
      for (final i
          in ref.read(importNotifierProvider).confirmedIndices.toList()) {
        notifier.toggleCandidate(i);
      }
    }
  }

  Future<void> _onDiscard(BuildContext context) async {
    final confirmed = await _showExitDialog();
    if (confirmed == true && context.mounted) {
      ref.read(importNotifierProvider.notifier).reset();
      context.go('/');
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
    if (_isSaving) return;
    // 验证题库名称
    final nameError = _validateBankName(_bankNameController.text);
    if (nameError != null) {
      setState(() => _bankNameError = nameError);
      return;
    }
    // 确保 state 中的 bankName 是最新的
    ref
        .read(importNotifierProvider.notifier)
        .setBankName(_bankNameController.text.trim());

    setState(() => _isSaving = true);

    try {
      final notifier = ref.read(importNotifierProvider.notifier);
      await notifier.commitToDatabase();

      final state = ref.read(importNotifierProvider);
      if (state.isDone && mounted) {
        context.go('/import/summary/${state.jobId}');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// 计算字符串的 CJK 感知长度：中文/全角字符=2，ASCII=1
  int _cjkAwareLength(String text) {
    int len = 0;
    for (final char in text.characters) {
      final code = char.codeUnitAt(0);
      // CJK统一表意文字 (U+4E00–U+9FFF)、CJK扩展A (U+3400–U+4DBF)、
      // CJK兼容表意文字 (U+F900–U+FAFF)、中文标点 (U+3000–U+303F)、
      // 全角字母/数字 (U+FF01–U+FF5E)
      if ((code >= 0x4E00 && code <= 0x9FFF) ||
          (code >= 0xFF01 && code <= 0xFF5E) ||
          (code >= 0x3000 && code <= 0x303F) ||
          (code >= 0x3400 && code <= 0x4DBF) ||
          (code >= 0xF900 && code <= 0xFAFF)) {
        len += 2;
      } else {
        len += 1;
      }
    }
    return len;
  }

  /// 验证题库名称，返回 null 表示有效
  String? _validateBankName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '请输入题库名称';
    if (_cjkAwareLength(trimmed) > 100) return '题库名称过长（上限100字符，中文=2）';
    return null;
  }

  // ── Phase 3: LLM 预览扩展（D-08）──

  /// 绿色信息横幅："LLM 解析结果已自动确认，N 题待入库"
  Widget _buildAutoConfirmBanner(BuildContext context, int confirmedCount) {
    return Card(
      color: Theme.of(context).colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.tertiary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'LLM 解析结果已自动确认，$confirmedCount 题待入库',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 解析来源摘要行："解析来源：LLM N 题 / 启发式 M 题 / 兜底 K 题"
  Widget _buildSourceSummary(BuildContext context, ImportState state) {
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        '解析来源：LLM $llmCount 题 / 启发式 $heuristicCount 题 / 兜底 $fallbackCount 题',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
    );
  }

  /// 单个候选的解析来源徽章。
  ///
  /// LLM → teal "LLM" chip
  /// 启发式 → secondary "启发式" chip
  /// 兜底 → amber "兜底" chip
  Widget _ParseSourceBadge({required ParseSource source}) {
    final (color, icon, label) = switch (source) {
      ParseSource.llm => (Colors.teal, Icons.psychology, 'LLM'),
      ParseSource.heuristic => (
        Theme.of(context).colorScheme.secondary,
        Icons.rule,
        '启发式',
      ),
      ParseSource.fallback => (Colors.amber.shade700, Icons.swap_horiz, '兜底'),
    };

    return SizedBox(
      height: 24,
      child: ActionChip(
        avatar: Icon(icon, size: 14),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        backgroundColor: color.withOpacity(0.15),
        side: BorderSide.none,
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
      ),
    );
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
