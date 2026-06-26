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
import '../../../core/platform/responsive.dart';
import '../../../core/theme.dart';

// ── File-private layout constants ──
// Screen-specific spacing that does not belong in the shared design tokens.
const double _kHeroPadding = 24.0;
const double _kSectionGap = 16.0;
const double _kSmallGap = 12.0;
const double _kStuckMessageGap = 8.0;

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
      ImportFile.fromPath(
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
    final isActive =
        state.isExtracting || state.isParsing || state.isLlmParsing;

    return PopScope(
      canPop: !isActive,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) await _onWillPop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('正在导入…'),
          leading: isActive
              ? IconButton(icon: const Icon(Icons.close), onPressed: _onWillPop)
              : null,
        ),
        body: AdaptiveLayout(
          compact: (_) => KeyedSubtree(
            key: const Key('import_progress_vertical_layout'),
            child: _buildVerticalLayout(context, state, fileName, fileIcon),
          ),
          medium: (_) => KeyedSubtree(
            key: const Key('import_progress_vertical_layout'),
            child: _buildVerticalLayout(
              context,
              state,
              fileName,
              fileIcon,
              maxWidth: kImportProgressMediumWidth,
            ),
          ),
          expanded: (_) => KeyedSubtree(
            key: const Key('import_progress_horizontal_layout'),
            child: _buildHorizontalLayout(context, state, fileName, fileIcon),
          ),
        ),
      ),
    );
  }

  /// Vertical (single-column) layout for compact + medium form factors.
  ///
  /// When [maxWidth] is null (compact), the column fills available width.
  /// When [maxWidth] is provided (medium), the column is constrained to that
  /// maximum width and centered — gives tablets breathing room.
  Widget _buildVerticalLayout(
    BuildContext context,
    ImportState state,
    String fileName,
    IconData fileIcon, {
    double? maxWidth,
  }) {
    final theme = Theme.of(context);
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeroCard(theme, fileName, fileIcon),
        const SizedBox(height: kImportProgressPagePadding),
        _buildPhaseSection(context, theme, state),
        _buildErrorSection(context, theme, state),
      ],
    );

    final padded = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: kImportProgressPagePadding,
      ),
      child: column,
    );

    if (maxWidth == null) {
      // Compact: Scaffold body fills available space, so the padded column
      // already expands to width. No Center wrapper needed — it would only
      // center vertically and the column uses MainAxisSize.min anyway.
      return padded;
    }
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: padded,
      ),
    );
  }

  /// Horizontal (two-column) layout for expanded form factors.
  ///
  /// Left column: gradient hero card with fileIcon + fileName.
  /// Right column: phase section (extracting/parsing/llmParsing) or error state.
  Widget _buildHorizontalLayout(
    BuildContext context,
    ImportState state,
    String fileName,
    IconData fileIcon,
  ) {
    final theme = Theme.of(context);
    final phaseColumn = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPhaseSection(context, theme, state),
        _buildErrorSection(context, theme, state),
      ],
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kExpandedReadingWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: kImportProgressPagePadding,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: kImportProgressHeroCardWidth,
                  ),
                  child: _buildHeroCard(theme, fileName, fileIcon),
                ),
              ),
              const SizedBox(width: kImportProgressPagePadding),
              Expanded(child: phaseColumn),
            ],
          ),
        ),
      ),
    );
  }

  /// Gradient hero card showing the file icon and file name.
  Widget _buildHeroCard(ThemeData theme, String fileName, IconData fileIcon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(_kHeroPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: heroGradient(theme.colorScheme, theme.brightness),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(fileIcon, size: 48, color: Colors.white),
          const SizedBox(height: _kSmallGap),
          Text(
            fileName,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Phase section: extracting/parsing (Phase 2) + llmParsing (Phase 3 D-07).
  Widget _buildPhaseSection(
    BuildContext context,
    ThemeData theme,
    ImportState state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.isExtracting || state.isParsing) ...[
          LinearProgressIndicator(value: state.progress),
          const SizedBox(height: _kSectionGap),
          Text(
            state.isExtracting ? '提取文本中…' : '解析中…',
            style: theme.textTheme.labelLarge,
          ),
          if (_showStuckMessage) ...[
            const SizedBox(height: _kStuckMessageGap),
            Text(
              '仍在处理…',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
          const SizedBox(height: kImportProgressPagePadding),
          _buildCancelButton(),
        ],
        if (state.isLlmParsing) ...[
          _buildLlmProgress(context, state),
          const SizedBox(height: kImportProgressPagePadding),
          _buildCancelButton(),
        ],
      ],
    );
  }

  /// Error section: error icon, message, and retry/home actions.
  Widget _buildErrorSection(
    BuildContext context,
    ThemeData theme,
    ImportState state,
  ) {
    if (!state.hasError) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
        const SizedBox(height: _kSectionGap),
        Text(
          state.error!,
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: kImportProgressPagePadding),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(onPressed: _onGoHome, child: const Text('返回首页')),
            const SizedBox(width: _kSectionGap),
            FilledButton(onPressed: _onRetry, child: const Text('重试')),
          ],
        ),
      ],
    );
  }

  /// Cancel-import button shared by both phase rows.
  Widget _buildCancelButton() =>
      TextButton(onPressed: _onWillPop, child: const Text('取消'));

  /// Reset state and navigate to home (used by the error section).
  void _onGoHome() {
    ref.read(importNotifierProvider.notifier).reset();
    if (mounted) context.go('/');
  }

  /// Reset state and restart the import (used by the error section).
  void _onRetry() {
    ref.read(importNotifierProvider.notifier).reset();
    _isStarted = false;
    _startImport();
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
        Text('LLM 解析中… $completed/...', style: theme.textTheme.labelLarge),
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
      return theme.textTheme.bodyMedium!.copyWith(color: Colors.amber.shade700);
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
