// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'import_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 导入管道 Notifier。
///
/// 通过 Riverpod 管理导入全流程状态，依赖 PathResolver 和 AppDatabase。

@ProviderFor(ImportNotifier)
final importProvider = ImportNotifierProvider._();

/// 导入管道 Notifier。
///
/// 通过 Riverpod 管理导入全流程状态，依赖 PathResolver 和 AppDatabase。
final class ImportNotifierProvider
    extends $NotifierProvider<ImportNotifier, ImportState> {
  /// 导入管道 Notifier。
  ///
  /// 通过 Riverpod 管理导入全流程状态，依赖 PathResolver 和 AppDatabase。
  ImportNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'importProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$importNotifierHash();

  @$internal
  @override
  ImportNotifier create() => ImportNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ImportState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ImportState>(value),
    );
  }
}

String _$importNotifierHash() => r'2f01246394bbe1e2af1efaa656d9d8bc97d39b54';

/// 导入管道 Notifier。
///
/// 通过 Riverpod 管理导入全流程状态，依赖 PathResolver 和 AppDatabase。

abstract class _$ImportNotifier extends $Notifier<ImportState> {
  ImportState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ImportState, ImportState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ImportState, ImportState>,
              ImportState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
