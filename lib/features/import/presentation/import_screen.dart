// lib/features/import/presentation/import_screen.dart
// ── 导入题库入口页 ──
// 平台分支：桌面端显示 .docx/.pdf/.json 图块 + 拖放 + 解析方式选择；
// Android 仅显示 .json（禁用）。

import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;

import '../../../core/theme.dart';
import '../../models/widgets/parser_choice_dialog.dart';
import '../providers/import_notifier.dart';
import '../providers/import_state.dart';
import '../widgets/file_format_tile.dart';

/// 导入题库入口页。
///
/// 桌面端：3 个格式图块 + 拖放 + 解析方式选择对话框。
/// Android 端：仅 .json 图块（禁用）。
class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  /// 支持的桌面端文件扩展名（用于拖放验证）
  // Note: 'doc' is not supported — pandoc only handles docx.
  static const _supportedExtensions = [
    'docx',
    'pdf',
    'json',
  ];

  /// 拖放悬停状态——控制视觉反馈覆盖层的显隐
  bool _isDragOver = false;

  /// 判断是否为支持的导入文件
  static bool _isSupportedFile(String filePath) {
    final ext = p.extension(filePath).toLowerCase().replaceAll('.', '');
    return _supportedExtensions.contains(ext);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = !kIsWeb && (Platform.isWindows || Platform.isLinux);

    final body = isDesktop
        ? _buildDesktopLayout(context)
        : _buildAndroidLayout(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('导入题库'),
      ),
      body: body,
    );
  }

  /// 桌面端布局：3 个格式图块 + 拖放支持 + 提示文字
  Widget _buildDesktopLayout(BuildContext context) {
    final body = _buildTileList(context, isDesktop: true);

    return DropTarget(
      onDragEntered: (_) {
        setState(() => _isDragOver = true);
      },
      onDragExited: (_) {
        setState(() => _isDragOver = false);
      },
      onDragDone: (details) {
        setState(() => _isDragOver = false);
        final filePath = details.files.firstOrNull?.path;
        if (filePath != null && _isSupportedFile(filePath)) {
          _onFileSelected(context, filePath);
        } else if (filePath != null) {
          _showUnsupportedError(context);
        }
      },
      child: Stack(
        children: [
          // 主内容
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: ListView(
                        shrinkWrap: true,
                        children: body,
                      ),
                    ),
                  ),
                ),
                // 拖放提示
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    '或将文件拖放到窗口任意位置',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                  ),
                ),
              ],
            ),
          ),
          // 拖放视觉反馈覆盖层 (D-03)
          if (_isDragOver)
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withOpacity(0.15),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '释放以导入',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '支持 .docx / .pdf / .json',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.7),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Android 端布局：仅 .json 图块（禁用）
  Widget _buildAndroidLayout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            shrinkWrap: true,
            children: _buildTileList(context, isDesktop: false),
          ),
        ),
      ),
    );
  }

  /// 构建格式图块列表
  List<Widget> _buildTileList(BuildContext context,
      {required bool isDesktop}) {
    final cs = Theme.of(context).colorScheme;
    if (isDesktop) {
      return [
        // ── 渐变 Hero ──
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: heroGradient(cs, Theme.of(context).brightness),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: cs.primary.withAlpha(50),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(40),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.cloud_upload_rounded,
                    color: Colors.white, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '导入题库',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '选择文件格式或拖放到窗口',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withAlpha(200),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        FileFormatTile(
          title: 'Word 题库',
          subtitle: '导入 .docx 格式的题库文件',
          icon: Icons.description_outlined,
          iconBg: cs.primaryContainer,
          iconColor: cs.onPrimaryContainer,
          onTap: () => _pickWordFile(context),
        ),
        const SizedBox(height: 10),
        FileFormatTile(
          title: 'PDF 题库',
          subtitle: '导入文字型 PDF 题库（不含扫描件）',
          icon: Icons.picture_as_pdf_outlined,
          iconBg: cs.errorContainer,
          iconColor: cs.onErrorContainer,
          onTap: () => _pickPdfFile(context),
        ),
        const SizedBox(height: 10),
        FileFormatTile(
          title: 'JSON 题库',
          subtitle: '导入标准 JSON 格式题库文件',
          icon: Icons.code_outlined,
          iconBg: cs.tertiaryContainer,
          iconColor: cs.onTertiaryContainer,
          onTap: () => _pickJsonFile(context),
        ),
      ];
    } else {
      return [
        FileFormatTile(
          title: 'JSON 题库',
          subtitle: '从文件管理器中选取 .json 题库文件',
          icon: Icons.code_outlined,
          enabled: false,
          onTap: () {},
        ),
      ];
    }
  }

  // ── 文件选择器 ──

  Future<void> _pickWordFile(BuildContext context) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['docx'],
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final filePath = result.files.first.path;
      if (filePath != null) {
        await _onFileSelected(context, filePath);
      }
    }
  }

  Future<void> _pickPdfFile(BuildContext context) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final filePath = result.files.first.path;
      if (filePath != null) {
        await _onFileSelected(context, filePath);
      }
    }
  }

  Future<void> _pickJsonFile(BuildContext context) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final filePath = result.files.first.path;
      if (filePath != null) {
        await _onFileSelected(context, filePath);
      }
    }
  }

  // ── 文件选择后处理 ──

  /// 文件选择完成后：桌面端展示解析方式选择对话框；
  /// Android 直接触发启发式解析。
  Future<void> _onFileSelected(BuildContext context, String filePath) async {
    final isDesktop = !kIsWeb && (Platform.isWindows || Platform.isLinux);

    if (!isDesktop) {
      // Android: 直接触发启发式解析（Phase 2 行为）
      _startParseAndNavigate(context, filePath, ParseMethod.heuristic);
      return;
    }

    // Desktop: 展示解析方式选择对话框
    if (!mounted) return;
    final parseMethod = await showDialog<ParseMethod>(
      context: context,
      builder: (_) => const ParserChoiceDialog(),
    );

    if (parseMethod == null || !mounted) return;

    _startParseAndNavigate(context, filePath, parseMethod);
  }

  /// 启动解析并导航到进度页。
  void _startParseAndNavigate(
    BuildContext context,
    String filePath,
    ParseMethod method,
  ) {
    final file = File(filePath);
    final stat = file.statSync();
    final notifier = ref.read(importNotifierProvider.notifier);

    notifier.pickFiles([
      ImportFile(
        path: filePath,
        name: p.basename(filePath),
        sizeBytes: stat.size,
      ),
    ]);

    if (method == ParseMethod.llm) {
      notifier.llmParse();
    } else {
      notifier.extractAndParse();
    }

    context.push('/import/progress', extra: filePath);
  }

  // ── 错误处理 ──

  void _showUnsupportedError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('不支持的文件格式，请选择 .docx/.pdf/.json'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
