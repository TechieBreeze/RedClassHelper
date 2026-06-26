// lib/features/models/widgets/parser_choice_dialog.dart
// ── 解析方式选择对话框（D-01）──
// 在文件选择后、解析开始前展示。提供"快速解析（启发式）"和"高精度
// 解析（LLM）"两个选项。LLM 选项在未安装模型时禁用。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/installed_models_provider.dart';

/// 解析方式枚举
enum ParseMethod {
  /// 快速解析（启发式正则）
  heuristic,

  /// 高精度解析（本地 LLM）
  llm,
}

/// 解析方式选择对话框。
///
/// 模态对话框，包含两个 tappable 选项卡片。
/// 选中卡片显示 2dp primary 边框（AnimatedContainer 150ms 过渡）。
/// 返回 [ParseMethod] 表示用户选择；返回 null 表示取消。
class ParserChoiceDialog extends ConsumerStatefulWidget {
  const ParserChoiceDialog({super.key});

  @override
  ConsumerState<ParserChoiceDialog> createState() => _ParserChoiceDialogState();
}

class _ParserChoiceDialogState extends ConsumerState<ParserChoiceDialog> {
  ParseMethod? _selected;

  @override
  Widget build(BuildContext context) {
    final installedModels = ref.watch(installedModelsProvider);
    final hasModels = (installedModels.value ?? []).isNotEmpty;

    return AlertDialog(
      title: const Text('选择解析方式'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _OptionCard(
            icon: Icons.bolt,
            title: '快速解析（启发式）',
            description: '基于规则匹配，速度快但精度约 70%，需手动审核每道题',
            hint: '预计耗时：数秒',
            isSelected: _selected == ParseMethod.heuristic,
            onTap: () => setState(() => _selected = ParseMethod.heuristic),
          ),
          const SizedBox(height: 16),
          _OptionCard(
            icon: Icons.psychology,
            title: '高精度解析（LLM）',
            description: '本地 AI 模型解析，精度更高，自动确认无需逐题审核',
            hint: '预计耗时：1-3 分钟（取决于模型和文件大小）',
            isSelected: _selected == ParseMethod.llm,
            enabled: hasModels,
            disabledReason: hasModels ? null : '需要先下载模型',
            disabledAction: hasModels ? null : () => _onDisabledLlmTap(context),
            onTap: hasModels
                ? () => setState(() => _selected = ParseMethod.llm)
                : null,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('取消'),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: _selected != null
              ? () => Navigator.of(context).pop(_selected)
              : null,
          child: const Text('开始解析'),
        ),
      ],
    );
  }

  void _onDisabledLlmTap(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('请先下载模型。前往 设置 → 模型管理下载'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// 单个选项卡片。
///
/// 使用 [AnimatedContainer] 实现 150ms 选中状态过渡。
class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.hint,
    required this.isSelected,
    this.enabled = true,
    this.disabledReason,
    this.disabledAction,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final String hint;
  final bool isSelected;
  final bool enabled;
  final String? disabledReason;
  final VoidCallback? disabledAction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveEnabled = enabled;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.primaryContainer.withOpacity(0.08)
            : theme.colorScheme.surfaceContainerHighest,
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outline,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: MouseRegion(
        cursor: effectiveEnabled ? SystemMouseCursors.click : MouseCursor.defer,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: effectiveEnabled ? onTap : null,
            borderRadius: BorderRadius.circular(12),
            child: Opacity(
              opacity: effectiveEnabled ? 1.0 : 0.5,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      icon,
                      size: 28,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(description, style: theme.textTheme.bodySmall),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              hint,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.6,
                                ),
                              ),
                            ),
                          ),
                          if (!effectiveEnabled && disabledReason != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              disabledReason!,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                            if (disabledAction != null) ...[
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: disabledAction,
                                child: Text(
                                  '前往设置 → 模型管理下载',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.secondary,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
