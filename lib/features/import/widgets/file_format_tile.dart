// lib/features/import/widgets/file_format_tile.dart
// ── 文件格式入口图块 ──
// ImportScreen 中每种文件格式的入口卡片。

import 'package:flutter/material.dart';

/// ImportScreen 中每种受支持文件格式的可点击图块。
class FileFormatTile extends StatelessWidget {
  const FileFormatTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.enabled = true,
    super.key,
  });

  /// 格式名称（如 "Word 题库"）
  final String title;

  /// 格式描述（如 "导入 .docx 或 .doc 格式的题库文件"）
  final String subtitle;

  /// 格式图标
  final IconData icon;

  /// 点击回调
  final VoidCallback onTap;

  /// 是否可交互（Android .json 在 Phase 2 中禁用）
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: enabled ? 1.0 : 0.5,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Icon(icon, size: 32),
                const SizedBox(width: 16), // md
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4), // xs
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
