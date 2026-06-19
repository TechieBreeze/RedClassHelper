// lib/features/models/providers/model_download_provider.dart
// ── Download state management ──
// Riverpod Notifier that manages the active model download lifecycle:
// idle → downloading → verifying → done / error / cancelled.
// Enforces single-download queue (StateError on concurrent start).
// On completion, invalidates installedModelsProvider.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/paths.dart';
import '../services/model_downloader.dart';
import '../providers/model_catalog_provider.dart';
import '../providers/installed_models_provider.dart';

part 'model_download_provider.g.dart';

/// Download state exposed by the provider.
enum DownloadProviderStatus {
  idle,
  downloading,
  verifying,
  done,
  error,
  cancelled,
}

/// Snapshot of the active download, exposed by [modelDownloadNotifierProvider].
class ActiveDownload {
  final String modelId;
  final DownloadProviderStatus status;
  final DownloadProgress? progress;
  final String? errorMessage;

  const ActiveDownload({
    required this.modelId,
    required this.status,
    this.progress,
    this.errorMessage,
  });

  ActiveDownload copyWith({
    String? modelId,
    DownloadProviderStatus? status,
    DownloadProgress? progress,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ActiveDownload(
      modelId: modelId ?? this.modelId,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Manages the single-download queue.
///
/// Only one download runs at a time. Calling [startDownload] while a download
/// is active throws [StateError].
@Riverpod(keepAlive: true)
class ModelDownloadNotifier extends _$ModelDownloadNotifier {
  ModelDownloader? _currentDownloader;

  @override
  ActiveDownload? build() => null;

  /// Starts downloading the given [model].
  ///
  /// Throws [StateError] if another download is already in progress.
  Future<void> startDownload(ModelInfo model) async {
    if (state != null && state!.status == DownloadProviderStatus.downloading) {
      throw StateError('已有模型正在下载中');
    }

    final resolver = await ref.read(pathResolverProvider.future);
    final modelsDir = await resolver.modelsDir;
    final destPath = '${modelsDir.path}/${model.id}.gguf';

    state = ActiveDownload(
      modelId: model.id,
      status: DownloadProviderStatus.downloading,
      progress: DownloadProgress(
        bytesDownloaded: 0,
        totalBytes: model.sizeBytes,
      ),
    );

    _currentDownloader = ModelDownloader(
      url: model.downloadUrl,
      destPath: destPath,
      expectedSha256: model.sha256Hash,
      onProgress: (progress) {
        if (state != null) {
          state = state!.copyWith(progress: progress);
        }
      },
    );

    try {
      await _currentDownloader!.startDownload();

      // Verification phase
      state = state!.copyWith(status: DownloadProviderStatus.verifying);

      // Verification happens inside startDownload() — throws if mismatch

      state = state!.copyWith(status: DownloadProviderStatus.done);
      ref.invalidate(installedModelsProvider);
    } on DownloadNetworkException catch (e) {
      // Don't set error state if download was explicitly cancelled
      if (e.originalError == '下载已取消') {
        state = state!.copyWith(status: DownloadProviderStatus.cancelled);
      } else {
        state = state!.copyWith(
          status: DownloadProviderStatus.error,
          errorMessage: e.toString(),
        );
      }
    } on DownloadVerificationException catch (e) {
      state = state!.copyWith(
        status: DownloadProviderStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Cancels the active download, if any.
  void cancelDownload() {
    _currentDownloader?.cancel();
    if (state != null) {
      state = state!.copyWith(status: DownloadProviderStatus.cancelled);
    }
  }

  /// Resets the provider back to idle state.
  void clearState() {
    state = null;
  }
}
