// lib/features/import/presentation/import_screen.dart
// ── 导入题库入口页 ──
// 平台分支：桌面端显示 .docx/.pdf/.json 图块 + 拖放；
// Android 仅显示 .json（禁用）。

import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;

import '../widgets/file_format_tile.dart';

/// 导入题库入口页。
///
/// 桌面端：3 个格式图块 + 拖放 + 提示文字。
/// Android 端：仅 .json 图块（禁用）。
class ImportScreen extends StatelessWidget {
  const ImportScreen({super.key});

  /// 支持的桌面端文件扩展名（用于拖放验证）
  static const _supportedExtensions = [
    'doc',
    'docx',
    'pdf',
    'json',
  ];

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
        // 拖放视觉反馈由 DropTarget 内部的 builder 处理
      },
      onDragExited: (_) {},
      onDragDone: (details) {
        final filePath = details.files.firstOrNull?.path;
        if (filePath != null && _isSupportedFile(filePath)) {
          _navigateToProgress(context, filePath);
        } else if (filePath != null) {
          _showUnsupportedError(context);
        }
      },
      child: Padding(
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
    if (isDesktop) {
      return [
        FileFormatTile(
          title: 'Word 题库',
          subtitle: '导入 .docx 或 .doc 格式的题库文件',
          icon: Icons.description_outlined,
          onTap: () => _pickWordFile(context),
        ),
        const SizedBox(height: 12),
        FileFormatTile(
          title: 'PDF 题库',
          subtitle: '导入文字型 PDF 题库（不含扫描件）',
          icon: Icons.picture_as_pdf_outlined,
          onTap: () => _pickPdfFile(context),
        ),
        const SizedBox(height: 12),
        FileFormatTile(
          title: 'JSON 题库',
          subtitle: '导入标准 JSON 格式题库文件',
          icon: Icons.code_outlined,
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
          onTap: () {}, // Phase 5 启用
        ),
      ];
    }
  }

  // ── 文件选择器 ──

  Future<void> _pickWordFile(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['docx', 'doc'],
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final filePath = result.files.first.path;
      if (filePath != null) {
        _navigateToProgress(context, filePath);
      }
    }
  }

  Future<void> _pickPdfFile(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final filePath = result.files.first.path;
      if (filePath != null) {
        _navigateToProgress(context, filePath);
      }
    }
  }

  Future<void> _pickJsonFile(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final filePath = result.files.first.path;
      if (filePath != null) {
        _navigateToProgress(context, filePath);
      }
    }
  }

  // ── 导航与错误处理 ──

  void _navigateToProgress(BuildContext context, String filePath) {
    context.go('/import/progress', extra: filePath);
  }

  void _showUnsupportedError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('不支持的文件格式，请选择 .doc/.docx/.pdf/.json'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
