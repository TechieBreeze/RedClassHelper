// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model_download_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages the single-download queue.
///
/// Only one download runs at a time. Calling [startDownload] while a download
/// is active throws [StateError].

@ProviderFor(ModelDownloadNotifier)
final modelDownloadProvider = ModelDownloadNotifierProvider._();

/// Manages the single-download queue.
///
/// Only one download runs at a time. Calling [startDownload] while a download
/// is active throws [StateError].
final class ModelDownloadNotifierProvider
    extends $NotifierProvider<ModelDownloadNotifier, ActiveDownload?> {
  /// Manages the single-download queue.
  ///
  /// Only one download runs at a time. Calling [startDownload] while a download
  /// is active throws [StateError].
  ModelDownloadNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'modelDownloadProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$modelDownloadNotifierHash();

  @$internal
  @override
  ModelDownloadNotifier create() => ModelDownloadNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ActiveDownload? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ActiveDownload?>(value),
    );
  }
}

String _$modelDownloadNotifierHash() =>
    r'6370f72b14def41e52614e14a71602a590e81f16';

/// Manages the single-download queue.
///
/// Only one download runs at a time. Calling [startDownload] while a download
/// is active throws [StateError].

abstract class _$ModelDownloadNotifier extends $Notifier<ActiveDownload?> {
  ActiveDownload? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ActiveDownload?, ActiveDownload?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ActiveDownload?, ActiveDownload?>,
              ActiveDownload?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
