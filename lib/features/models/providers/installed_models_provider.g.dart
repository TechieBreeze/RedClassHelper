// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'installed_models_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Lists installed .gguf model files in [PathResolver.modelsDir].
///
/// Invalidated by [ModelDownloadNotifier] when a download completes.

@ProviderFor(installedModels)
final installedModelsProvider = InstalledModelsProvider._();

/// Lists installed .gguf model files in [PathResolver.modelsDir].
///
/// Invalidated by [ModelDownloadNotifier] when a download completes.

final class InstalledModelsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<InstalledModel>>,
          List<InstalledModel>,
          FutureOr<List<InstalledModel>>
        >
    with
        $FutureModifier<List<InstalledModel>>,
        $FutureProvider<List<InstalledModel>> {
  /// Lists installed .gguf model files in [PathResolver.modelsDir].
  ///
  /// Invalidated by [ModelDownloadNotifier] when a download completes.
  InstalledModelsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'installedModelsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$installedModelsHash();

  @$internal
  @override
  $FutureProviderElement<List<InstalledModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<InstalledModel>> create(Ref ref) {
    return installedModels(ref);
  }
}

String _$installedModelsHash() => r'c5754f7e2498e707d898d50bb607aa66034de479';
