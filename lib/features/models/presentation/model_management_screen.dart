// lib/features/models/presentation/model_management_screen.dart
// ── Full model management page (Phase 3, Desktop Only) ──
// 3 sections: installed models, recommended catalog, custom models.
// ModelCard / DownloadProgress / AddModelDialog widgets created in Plan 03-06 Task 2.
// Inline rendering in Task 1; upgraded to dedicated widgets in Task 2.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/model_catalog_provider.dart';
import '../providers/model_download_provider.dart';
import '../providers/installed_models_provider.dart';

/// Full model management center (desktop-only).
///
/// Route: /settings/models
class ModelManagementScreen extends ConsumerWidget {
  const ModelManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!(Platform.isWindows || Platform.isLinux)) {
      return _platformUnavailable(context);
    }

    final installedAsync = ref.watch(installedModelsProvider);
    final catalog = ref.watch(modelCatalogProvider);
    final activeDownload = ref.watch(modelDownloadProvider);

    // Build sets for quick lookup
    final installedIds = installedAsync.valueOrNull
            ?.map((m) => m.fileName)
            .toSet() ??
        const <String>{};
    final catalogIds = catalog.map((m) => '${m.id}.gguf').toSet();

    return Scaffold(
      appBar: AppBar(
        title: const Text('模型管理'),
      ),
      body: LayoutBuilder(
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
              constraints:
                  BoxConstraints(maxWidth: maxWidth ?? double.infinity),
              child: SingleChildScrollView(
                padding:
                    padding.add(const EdgeInsets.symmetric(vertical: 24)),
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
                        child: _CatalogModelCard(
                          model: model,
                          isInstalled:
                              installedIds.contains('${model.id}.gguf'),
                          activeDownload: activeDownload,
                          onDownload: () => _onDownload(ref, model),
                          onCancel: () =>
                              ref.read(modelDownloadProvider.notifier)
                                  .cancelDownload(),
                          onDelete: () =>
                              _showDeleteDialog(context, ref, model),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Section 3: Custom Models ──
                    const _SectionHeader('自定义模型'),
                    const SizedBox(height: 16),
                    _AddModelCard(
                      onTap: () => _showAddModelDialog(context, ref),
                    ),
                    const SizedBox(height: 12),
                    // Show custom models (installed but not in catalog)
                    ..._customModels(installedAsync.valueOrNull, catalogIds)
                        .map(
                      (model) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _CustomModelCard(
                          fileName: model.fileName,
                          sizeBytes: model.sizeBytes,
                          onDelete: () => _showCustomDeleteDialog(
                              context, ref, model),
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
    );
  }

  static List<InstalledModel> _customModels(
    List<InstalledModel>? installed,
    Set<String> catalogIds,
  ) {
    if (installed == null) return [];
    return installed.where((m) => !catalogIds.contains(m.fileName)).toList();
  }

  void _onDownload(WidgetRef ref, ModelInfo model) {
    try {
      ref.read(modelDownloadProvider.notifier).startDownload(model);
    } on StateError catch (e) {
      // Another download is active — UI handles via disabled button
    }
  }

  static void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    ModelInfo model,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除模型'),
        content: const Text('模型文件将被删除，需要时可重新下载'),
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

  // Adds a custom model via dialog. ModelInfo returned from dialog
  // is added to the installed list (via file copy or URL download).
  void _showAddModelDialog(BuildContext context, WidgetRef ref) {
    // Task 2 will replace this with the actual AddModelDialog widget.
    // For now, show a placeholder acknowledging the feature.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('添加自定义模型 — Task 2 实现')),
    );
  }

  static Widget _platformUnavailable(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('模型管理')),
      body: const Center(
        child: Text('模型管理仅在桌面端可用'),
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
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall,
    );
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
  const _InstalledModelCard({
    required this.fileName,
    required this.sizeBytes,
  });

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
                  Text(
                    fileName,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
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

/// Inline model card for catalog sections (section 2).
/// Replaced by ModelCard widget in Task 2.
class _CatalogModelCard extends ConsumerWidget {
  const _CatalogModelCard({
    required this.model,
    required this.isInstalled,
    required this.activeDownload,
    required this.onDownload,
    required this.onCancel,
    required this.onDelete,
  });

  final ModelInfo model;
  final bool isInstalled;
  final ActiveDownload? activeDownload;
  final VoidCallback onDownload;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  bool get isDownloadingThis =>
      activeDownload != null &&
      activeDownload!.modelId == model.id &&
      activeDownload!.status == DownloadProviderStatus.downloading;

  bool get isVerifyingThis =>
      activeDownload != null &&
      activeDownload!.modelId == model.id &&
      activeDownload!.status == DownloadProviderStatus.verifying;

  bool get isErrorThis =>
      activeDownload != null &&
      activeDownload!.modelId == model.id &&
      activeDownload!.status == DownloadProviderStatus.error;

  bool get isAnotherDownloading =>
      activeDownload != null &&
      activeDownload!.status == DownloadProviderStatus.downloading &&
      activeDownload!.modelId != model.id;

  IconData get tierIcon {
    switch (model.tier) {
      case ModelTier.recommended:
        return Icons.psychology;
      case ModelTier.fast:
        return Icons.bolt;
      case ModelTier.experimental:
        return Icons.science_outlined;
      case ModelTier.custom:
        return Icons.upload_file;
    }
  }

  Widget get tierBadge {
    final (String label, Color background, Color foreground) = switch (
        model.tier) {
      ModelTier.recommended => (
          '推荐',
          Theme.of(context).colorScheme.primaryContainer,
          Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ModelTier.fast => (
          '快速',
          Colors.green.shade100,
          Colors.green.shade700,
        ),
      ModelTier.experimental => (
          '实验',
          Colors.deepOrange.shade100,
          Colors.deepOrange.shade700,
        ),
      ModelTier.custom => (
          '自定义',
          Theme.of(context).colorScheme.surfaceContainerHighest,
          Theme.of(context).colorScheme.onSurfaceVariant,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: foreground,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(tierIcon, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        model.name,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      tierBadge,
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              model.description,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              '${model.sizeDisplay} · ${model.ramRequirement}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            _buildActionArea(theme, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildActionArea(ThemeData theme, WidgetRef ref) {
    if (isInstalled) {
      return Row(
        children: [
          Chip(
            avatar: const Icon(Icons.check_circle, size: 16),
            label: const Text('已安装'),
            backgroundColor: Colors.green.shade100,
          ),
          const Spacer(),
          TextButton(
            onPressed: onDelete,
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
      );
    }

    if (isDownloadingThis && activeDownload!.progress != null) {
      final progress = activeDownload!.progress!;
      final fraction = progress.fraction;
      final speedMBps =
          (progress.speedBytesPerSec / 1048576).toStringAsFixed(1);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('下载中 ${(fraction * 100).toStringAsFixed(0)}%'),
          const SizedBox(height: 4),
          LinearProgressIndicator(value: fraction),
          const SizedBox(height: 4),
          Text(
            '$speedMBps MB/s',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onCancel,
              child: const Text('取消'),
            ),
          ),
        ],
      );
    }

    if (isVerifyingThis) {
      return const Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text('校验中…'),
        ],
      );
    }

    if (isErrorThis) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            activeDownload!.errorMessage ?? '下载失败',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              onPressed: onDownload,
              child: const Text('重新下载'),
            ),
          ),
        ],
      );
    }

    // Idle state (not installed, no active download, or another downloading)
    return Align(
      alignment: Alignment.centerRight,
      child: FilledButton.icon(
        onPressed: isAnotherDownloading ? null : onDownload,
        icon: const Icon(Icons.download, size: 18),
        label: Text(isAnotherDownloading ? '等待中' : '下载'),
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
    return Card(
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
                  Text(
                    fileName,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$sizeDisplay · 本地导入',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Chip(
              avatar: const Icon(Icons.check_circle, size: 16),
              label: const Text('已安装'),
              backgroundColor: Colors.green.shade100,
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: onDelete,
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
              child: const Text('删除'),
            ),
          ],
        ),
      ),
    );
  }
}
