// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model_catalog_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The 3-tier preset model catalog.
///
/// D-04: Three tiers — Recommended (1.5B ~1.0 GB), Fast (0.5B ~0.5 GB),
/// Experimental (3B ~2.0 GB). Download on demand; no auto-download.
/// SHA-256 hashes are TBD until first verified download.

@ProviderFor(modelCatalog)
final modelCatalogProvider = ModelCatalogProvider._();

/// The 3-tier preset model catalog.
///
/// D-04: Three tiers — Recommended (1.5B ~1.0 GB), Fast (0.5B ~0.5 GB),
/// Experimental (3B ~2.0 GB). Download on demand; no auto-download.
/// SHA-256 hashes are TBD until first verified download.

final class ModelCatalogProvider
    extends
        $FunctionalProvider<List<ModelInfo>, List<ModelInfo>, List<ModelInfo>>
    with $Provider<List<ModelInfo>> {
  /// The 3-tier preset model catalog.
  ///
  /// D-04: Three tiers — Recommended (1.5B ~1.0 GB), Fast (0.5B ~0.5 GB),
  /// Experimental (3B ~2.0 GB). Download on demand; no auto-download.
  /// SHA-256 hashes are TBD until first verified download.
  ModelCatalogProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'modelCatalogProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$modelCatalogHash();

  @$internal
  @override
  $ProviderElement<List<ModelInfo>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<ModelInfo> create(Ref ref) {
    return modelCatalog(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<ModelInfo> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<ModelInfo>>(value),
    );
  }
}

String _$modelCatalogHash() => r'c4d46a8d9b445017dac278f1eff091bb26b6536e';
