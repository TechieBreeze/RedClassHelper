// lib/features/import/presentation/import_progress_screen.dart
// ── 导入进度页 ──
// 显示文本提取和解析的进度，支持 LLM 解析子阶段和取消。
// Phase 3 扩展：llmParsing 子阶段 UI（D-07）。

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;

import '../parsing/llm/canonicalizer.dart';
import '../providers/import_notifier.dart';
import '../providers/import_state.dart';
import '../../../core/theme.dart';

/// 导入进度页——在后台 isolate 中执行提取+解析时显示进度。
///
/// Phase 2 行为：extracting → parsing → editing
/// Phase 3 行为（LLM）：extracting → llmParsing → editing
///
/// 通过 [GoRouterState.extra] 接收文件路径。
class ImportProgressScreen extends ConsumerStatefulWidget {
  const ImportProgressScreen({super.key});

  @override
  ConsumerState<ImportProgressScreen> createState() =>
      _ImportProgressScreenState();
}

class _ImportProgressScreenState extends ConsumerState<ImportProgressScreen> {
  String? _filePath;
  Timer? _stuckTimer;
  bool _showStuckMessage = false;
  bool _isStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isStarted) {
      final state = GoRouterState.of(context);
      _filePath = state.extra as String?;
      _isStarted = true;
      // Defer provider modification to after the current build frame
      // to avoid "Tried to modify a provider while the widget tree
      // was building" error.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startImport();
      });
    }
  }

  @override
  void dispose() {
    _stuckTimer?.cancel();
    super.dispose();
  }

  void _startImport() {
    if (_filePath == null) return;

    // If ImportScreen already started the parse (Phase 3 desktop flow),
    // don't re-initialize. Just resume watching progress.
    final currentState = ref.read(importNotifierProvider);
    if (currentState.phase != ImportPhase.idle) {
      _stuckTimer?.cancel();
      _stuckTimer = Timer(const Duration(seconds: 10), () {
        if (mounted) {
          setState(() => _showStuckMessage = true);
        }
      });
      return;
    }

    // Phase 2 behavior: start import from scratch
    final file = File(_filePath!);
    final stat = file.statSync();
    final notifier = ref.read(importNotifierProvider.notifier);

    notifier.pickFiles([
      ImportFile(
        path: _filePath!,
        name: p.basename(_filePath!),
        sizeBytes: stat.size,
      ),
    ]);

    notifier.extractAndParse();

    // 10 秒卡住定时器
    _stuckTimer?.cancel();
    _stuckTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() => _showStuckMessage = true);
      }
    });
  }

  Future<bool> _onWillPop() async {
    final state = ref.read(importNotifierProvider);
    if (state.isExtracting || state.isParsing || state.isLlmParsing) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('取消导入'),
          content: const Text('已解析的题目将不会保存，确定取消？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('继续导入'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('取消'),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        ref.read(importNotifierProvider.notifier).reset();
        if (mounted) {
          context.pop();
        }
      }
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(importNotifierProvider);

    // 自动导航到下一屏（Phase 2 heuristic parse complete）
    ref.listen(importNotifierProvider, (prev, next) {
      if (next.isEditing && next.hasCandidates && next.jobId.isNotEmpty) {
        if (mounted) {
          context.go('/import/preview/${next.jobId}');
        }
      }
    });

    final fileName = _filePath != null ? p.basename(_filePath!) : '';
    final fileIcon = _getFileIcon(fileName);
    final isActive = state.isExtracting ||
        state.isParsing ||
        state.isLlmParsing;

    return PopScope(
      canPop: !isActive,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) await _onWillPop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('正在导入…'),
          leading: isActive
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _onWillPop,
                )
              : null,
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── 渐变 Hero ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: heroGradient(
                          Theme.of(context).colorScheme,
                          Theme.of(context).brightness,
                        ),
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          fileIcon,
                          size: 48,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          fileName,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Phase 2: extracting / parsing phase ──
                  if (state.isExtracting || state.isParsing) ...[
                    LinearProgressIndicator(value: state.progress),
                    const SizedBox(height: 16),
                    Text(
                      state.isExtracting
                          ? '提取文本中…'
                          : '解析中…',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    if (_showStuckMessage) ...[
                      const SizedBox(height: 8),
                      Text(
                        '仍在处理…',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                            ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    // 取消按钮
                    TextButton(
                      onPressed: _onWillPop,
                      child: const Text('取消'),
                    ),
                  ],

                  // ── Phase 3: llmParsing sub-phase (D-07) ──
                  if (state.isLlmParsing) ...[
                    _buildLlmProgress(context, state),
                    const SizedBox(height: 32),
                    TextButton(
                      onPressed: _onWillPop,
                      child: const Text('取消'),
                    ),
                  ],

                  // 错误状态
                  if (state.hasError) ...[
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.error!,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {
                            ref
                                .read(importNotifierProvider.notifier)
                                .reset();
                            if (mounted) context.go('/');
                          },
                          child: const Text('返回首页'),
                        ),
                        const SizedBox(width: 16),
                        FilledButton(
                          onPressed: () {
                            ref
                                .read(importNotifierProvider.notifier)
                                .reset();
                            _isStarted = false;
                            _startImport();
                          },
                          child: const Text('重试'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// LLM 解析子阶段进度 UI（D-07）。
  Widget _buildLlmProgress(BuildContext context, ImportState state) {
    final theme = Theme.of(context);
    final llmCount = state.parseSources.values
        .where((s) => s == ParseSource.llm)
        .length;
    final fallbackCount = state.parseSources.values
        .where((s) => s == ParseSource.fallback)
        .length;
    final completed = llmCount + fallbackCount;

    return Column(
      children: [
        // "LLM 解析中…" label
        Text(
          'LLM 解析中… $completed/...',
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 12),

        // Overall progress bar
        LinearProgressIndicator(value: state.progress),
        const SizedBox(height: 12),

        // Per-question status
        if (state.parseStatus != null) ...[
          Text(
            state.parseStatus!,
            style: _statusTextStyle(theme, state.parseStatus!),
          ),
          const SizedBox(height: 12),
        ],

        // Fallback indicator
        if (fallbackCount > 0)
          Text(
            '${fallbackCount} 题已切换兜底解析',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.amber.shade700,
            ),
          ),
      ],
    );
  }

  /// Determine text style based on status message content.
  TextStyle _statusTextStyle(ThemeData theme, String status) {
    final isRetry = status.contains('重试');
    final isFallback = status.contains('兜底');
    if (isRetry || isFallback) {
      return theme.textTheme.bodyMedium!.copyWith(
        color: Colors.amber.shade700,
      );
    }
    return theme.textTheme.bodyMedium!;
  }

  IconData _getFileIcon(String fileName) {
    final ext = p.extension(fileName).toLowerCase();
    if (ext == '.pdf') return Icons.picture_as_pdf;
    if (ext == '.json') return Icons.code;
    return Icons.description;
  }
}
