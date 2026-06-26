// lib/features/models/widgets/model_card.dart
// ── ModelCard widget ──
// Renders a catalog model with tier badge, metadata, and
// context-sensitive action area (download / progress / installed badge).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform/platform_guard.dart';
import '../../../core/platform/platform_info.dart';
import '../providers/model_catalog_provider.dart';
import '../providers/model_download_provider.dart';
import 'download_progress.dart';

/// Renders a single model in the catalog with tier badge and action area.
///
/// Handles all download states: idle, downloading, verifying, installed,
/// error, and another-model-downloading.
class ModelCard extends ConsumerWidget {
  const ModelCard({
    required this.model,
    this.isInstalled = false,
    this.activeDownload,
    this.info,
    super.key,
  });

  final ModelInfo model;
  final bool isInstalled;
  final ActiveDownload? activeDownload;

  /// Optional [PlatformInfo] override forwarded to descendant guards so the
  /// catalog matches the platform branching expected by the caller.
  final PlatformInfo? info;

  bool get _isDownloadingThis =>
      activeDownload != null &&
      activeDownload!.modelId == model.id &&
      activeDownload!.status == DownloadProviderStatus.downloading;

  bool get _isVerifyingThis =>
      activeDownload != null &&
      activeDownload!.modelId == model.id &&
      activeDownload!.status == DownloadProviderStatus.verifying;

  bool get _isErrorThis =>
      activeDownload != null &&
      activeDownload!.modelId == model.id &&
      activeDownload!.status == DownloadProviderStatus.error;

  bool get _isAnotherDownloading =>
      activeDownload != null &&
      activeDownload!.status == DownloadProviderStatus.downloading &&
      activeDownload!.modelId != model.id;

  IconData get _tierIcon {
    return switch (model.tier) {
      ModelTier.recommended => Icons.psychology,
      ModelTier.fast => Icons.bolt,
      ModelTier.experimental => Icons.science_outlined,
      ModelTier.custom => Icons.upload_file,
    };
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
                Icon(_tierIcon, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(model.name, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      _TierBadge(tier: model.tier),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(model.description, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(
              '${model.sizeDisplay} · ${model.ramRequirement}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            _buildActionArea(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildActionArea(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (isInstalled) {
      return Row(
        children: [
          Chip(
            avatar: const Icon(Icons.check_circle, size: 16),
            label: const Text('已安装'),
            backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
            labelStyle: TextStyle(
              color: Theme.of(context).colorScheme.onTertiaryContainer,
            ),
          ),
          const Spacer(),
          UnsupportedFeatureGuard(
            requiresDesktop: true,
            info: info,
            fallback: const Tooltip(
              message: '桌面端功能',
              child: TextButton(onPressed: null, child: Text('删除')),
            ),
            child: TextButton(
              onPressed: () => _showDeleteDialog(context, ref),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
              child: const Text('删除'),
            ),
          ),
        ],
      );
    }

    if (_isDownloadingThis && activeDownload!.progress != null) {
      final progress = activeDownload!.progress!;
      return Column(
        children: [
          DownloadProgressWidget(progress: progress),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () =>
                  ref.read(modelDownloadProvider.notifier).cancelDownload(),
              child: const Text('取消'),
            ),
          ),
        ],
      );
    }

    if (_isVerifyingThis) {
      return Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          const Text('校验中…'),
        ],
      );
    }

    if (_isErrorThis) {
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
              onPressed: () =>
                  ref.read(modelDownloadProvider.notifier).startDownload(model),
              child: const Text('重新下载'),
            ),
          ),
        ],
      );
    }

    // Idle (not installed, not downloading, or another downloading)
    return Align(
      alignment: Alignment.centerRight,
      child: UnsupportedFeatureGuard(
        requiresDesktop: true,
        info: info,
        fallback: Tooltip(
          message: '桌面端功能',
          child: FilledButton.icon(
            onPressed: null,
            icon: const Icon(Icons.download, size: 18),
            label: Text(_isAnotherDownloading ? '等待中' : '下载'),
          ),
        ),
        child: FilledButton.icon(
          onPressed: _isAnotherDownloading
              ? null
              : () => ref
                    .read(modelDownloadProvider.notifier)
                    .startDownload(model),
          icon: const Icon(Icons.download, size: 18),
          label: Text(_isAnotherDownloading ? '等待中' : '下载'),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
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
              Navigator.of(ctx).pop();
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

/// Small colored chip indicating model tier per UI-SPEC color contract.
class _TierBadge extends StatelessWidget {
  const _TierBadge({required this.tier});

  final ModelTier tier;

  @override
  Widget build(BuildContext context) {
    final (String label, Color background, Color foreground) = switch (tier) {
      ModelTier.recommended => (
        '推荐',
        Theme.of(context).colorScheme.primaryContainer,
        Theme.of(context).colorScheme.onPrimaryContainer,
      ),
      ModelTier.fast => (
        '快速',
        Theme.of(context).colorScheme.tertiaryContainer,
        Theme.of(context).colorScheme.onTertiaryContainer,
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
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: foreground),
      ),
    );
  }
}
