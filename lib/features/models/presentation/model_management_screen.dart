// lib/features/models/presentation/model_management_screen.dart
// ── Full model management page (Phase 3, Desktop Only) ──
// 3 sections: installed models, recommended catalog, custom models.
// Uses ModelCard, DownloadProgressWidget, and showAddModelDialog from widgets/.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform/platform_guard.dart';
import '../../../core/platform/platform_info.dart';
import '../providers/model_catalog_provider.dart';
import '../providers/model_download_provider.dart';
import '../providers/installed_models_provider.dart';
import '../widgets/model_card.dart';
import '../widgets/add_model_dialog.dart';
import 'widgets/llm_unsupported_banner.dart';

/// Full model management center.
///
/// Route: /settings/models
///
/// Reachable on mobile (banner explains desktop-only requirement), but the
/// interactive controls (download, delete, add custom) are gated by
/// [UnsupportedFeatureGuard] and render as disabled buttons with tooltips.
class ModelManagementScreen extends ConsumerWidget {
  const ModelManagementScreen({super.key, this.info});

  /// Optional [PlatformInfo] override. When non-null, forwarded to the
  /// [LlmUnsupportedBanner] and used by descendant guards. Tests pass an
  /// explicit value to avoid depending on the host platform reported by
  /// `dart:io`.
  final PlatformInfo? info;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final installedAsync = ref.watch(installedModelsProvider);
    final catalog = ref.watch(modelCatalogProvider);
    final activeDownload = ref.watch(modelDownloadProvider);

    // Build sets for quick lookup
    final installedIds =
        installedAsync.asData?.value.map((m) => m.fileName).toSet() ??
        const <String>{};
    final catalogIds = catalog.map((m) => '${m.id}.gguf').toSet();

    return Scaffold(
      appBar: AppBar(title: const Text('模型管理')),
      body: Column(
        children: [
          LlmUnsupportedBanner(info: info),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final EdgeInsets padding;
                final double? maxWidth;
                if (width < 600) {
                  padding = const EdgeInsets.symmetric(horizontal: 16);
                  maxWidth = null;
                } else if (width < 840) {
                  padding = const EdgeInsets.symmetric(horizontal: 24);
                  maxWidth = null;
                } else {
                  padding = const EdgeInsets.symmetric(horizontal: 32);
                  maxWidth = 720;
                }
                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: maxWidth ?? double.infinity,
                    ),
                    child: SingleChildScrollView(
                      padding: padding.add(
                        const EdgeInsets.symmetric(vertical: 24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── Section 1: Installed Models ──
                          const _SectionHeader('已安装模型'),
                          const SizedBox(height: 16),
                          _InstalledSection(
                            installedAsync: installedAsync,
                            installedIds: installedIds,
                          ),
                          const SizedBox(height: 32),

                          // ── Section 2: Recommended Models ──
                          const _SectionHeader('推荐模型'),
                          const SizedBox(height: 16),
                          ...catalog.map(
                            (model) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: ModelCard(
                                model: model,
                                isInstalled: installedIds.contains(
                                  '${model.id}.gguf',
                                ),
                                activeDownload: activeDownload,
                                info: info,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // ── Section 3: Custom Models ──
                          const _SectionHeader('自定义模型'),
                          const SizedBox(height: 16),
                          _AddModelCard(
                            onTap: () async {
                              final result = await showAddModelDialog(context);
                              if (result != null && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('已添加模型：${result.name}'),
                                  ),
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          // Show custom models (installed but not in catalog)
                          ..._customModels(
                            installedAsync.asData?.value ?? const [],
                            catalogIds,
                          ).map(
                            (model) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _CustomModelCard(
                                fileName: model.fileName,
                                sizeBytes: model.sizeBytes,
                                onDelete: () => _showCustomDeleteDialog(
                                  context,
                                  ref,
                                  model,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static List<InstalledModel> _customModels(
    List<InstalledModel>? installed,
    Set<String> catalogIds,
  ) {
    if (installed == null) return [];
    return installed.where((m) => !catalogIds.contains(m.fileName)).toList();
  }

  static void _showCustomDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    InstalledModel model,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除模型'),
        content: const Text('模型文件将被删除，需要时可重新导入'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () {
              // TODO: implement actual file deletion
              Navigator.of(ctx).pop();
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────── Private Widgets ────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.headlineSmall);
  }
}

/// Empty state shown when no models are installed.
class _InstalledEmptyState extends StatelessWidget {
  const _InstalledEmptyState();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.inventory_2_outlined, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '尚未安装模型',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '从下方推荐模型中选择一个下载，或添加自定义模型',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Container for section 1 — delegates to loading / empty / installed views.
class _InstalledSection extends ConsumerWidget {
  const _InstalledSection({
    required this.installedAsync,
    required this.installedIds,
  });

  final AsyncValue<List<InstalledModel>> installedAsync;
  final Set<String> installedIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return installedAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('加载失败：$error'),
        ),
      ),
      data: (models) {
        if (models.isEmpty) return const _InstalledEmptyState();
        return Column(
          children: models.map((m) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _InstalledModelCard(
                fileName: m.fileName,
                sizeBytes: m.sizeBytes,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

/// Card for an installed model in section 1.
class _InstalledModelCard extends StatelessWidget {
  const _InstalledModelCard({required this.fileName, required this.sizeBytes});

  final String fileName;
  final int sizeBytes;

  String get sizeDisplay {
    if (sizeBytes >= 1073741824) {
      return '约 ${(sizeBytes / 1073741824).toStringAsFixed(1)} GB';
    }
    return '约 ${(sizeBytes / 1048576).toStringAsFixed(0)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.psychology, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fileName, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    sizeDisplay,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Chip(
              avatar: const Icon(Icons.check_circle, size: 16),
              label: const Text('已安装'),
              backgroundColor: Colors.green.shade100,
            ),
          ],
        ),
      ),
    );
  }
}

/// "添加模型" launch card for section 3.
class _AddModelCard extends StatelessWidget {
  const _AddModelCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.add, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '添加模型',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '通过 URL 或本地文件添加自定义 .gguf 模型',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Card for a custom installed model in section 3.
class _CustomModelCard extends StatelessWidget {
  const _CustomModelCard({
    required this.fileName,
    required this.sizeBytes,
    required this.onDelete,
  });

  final String fileName;
  final int sizeBytes;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sizeDisplay = sizeBytes >= 1073741824
        ? '约 ${(sizeBytes / 1073741824).toStringAsFixed(1)} GB'
        : '约 ${(sizeBytes / 1048576).toStringAsFixed(0)} MB';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.upload_file, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fileName, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text('$sizeDisplay · 本地导入', style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            Chip(
              avatar: const Icon(Icons.check_circle, size: 16),
              label: const Text('已安装'),
              backgroundColor: Colors.green.shade100,
            ),
            const SizedBox(width: 8),
            UnsupportedFeatureGuard(
              requiresDesktop: true,
              fallback: const Tooltip(
                message: '桌面端功能',
                child: TextButton(
                  onPressed: null,
                  style: ButtonStyle(
                    foregroundColor: WidgetStatePropertyAll(Colors.grey),
                  ),
                  child: Text('删除'),
                ),
              ),
              child: TextButton(
                onPressed: onDelete,
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
                child: const Text('删除'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
