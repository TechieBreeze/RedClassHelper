// lib/features/import/presentation/import_progress_screen.dart
// ── 导入进度页 ──
// 显示文本提取和解析的进度，支持取消。

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;

import '../providers/import_notifier.dart';
import '../providers/import_state.dart';

/// 导入进度页——在后台 isolate 中执行提取+解析时显示进度。
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
      _startImport();
      _isStarted = true;
    }
  }

  @override
  void dispose() {
    _stuckTimer?.cancel();
    super.dispose();
  }

  void _startImport() {
    if (_filePath == null) return;

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
    if (state.isExtracting || state.isParsing) {
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

    // 自动导航到下一屏
    ref.listen(importNotifierProvider, (prev, next) {
      if (next.isEditing && next.hasCandidates && next.jobId.isNotEmpty) {
        if (mounted) {
          context.go('/import/preview/${next.jobId}');
        }
      }
    });

    final fileName = _filePath != null ? p.basename(_filePath!) : '';
    final fileIcon = _getFileIcon(fileName);

    return PopScope(
      canPop: !(state.isExtracting || state.isParsing),
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) await _onWillPop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('正在导入…'),
          leading: state.isExtracting || state.isParsing
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
                  // 文件图标
                  Icon(
                    fileIcon,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 24),

                  // 文件名
                  Text(
                    fileName,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 32),

                  // 进度条
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

  IconData _getFileIcon(String fileName) {
    final ext = p.extension(fileName).toLowerCase();
    if (ext == '.pdf') return Icons.picture_as_pdf;
    if (ext == '.json') return Icons.code;
    return Icons.description;
  }
}
