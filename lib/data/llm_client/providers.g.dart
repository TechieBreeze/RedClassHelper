// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// LLM 客户端模式——默认 stub。
///
/// 用户在设置页（Phase 6）切换模式。
/// 此 provider 不执行平台检查——模式的值在所有平台上都可自由读取。

@ProviderFor(llmMode)
final llmModeProvider = LlmModeProvider._();

/// LLM 客户端模式——默认 stub。
///
/// 用户在设置页（Phase 6）切换模式。
/// 此 provider 不执行平台检查——模式的值在所有平台上都可自由读取。

final class LlmModeProvider
    extends $FunctionalProvider<LlmMode, LlmMode, LlmMode>
    with $Provider<LlmMode> {
  /// LLM 客户端模式——默认 stub。
  ///
  /// 用户在设置页（Phase 6）切换模式。
  /// 此 provider 不执行平台检查——模式的值在所有平台上都可自由读取。
  LlmModeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'llmModeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$llmModeHash();

  @$internal
  @override
  $ProviderElement<LlmMode> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LlmMode create(Ref ref) {
    return llmMode(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LlmMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LlmMode>(value),
    );
  }
}

String _$llmModeHash() => r'7fc0b21f8ebf4057af373b8162bb945f0dd5a3cf';

/// LLM 客户端实例——平台门控。
///
/// 在非桌面平台（Android/iOS）上访问此 provider 抛出 [UnsupportedError]。
/// 在桌面平台上根据 [llmModeProvider] 的值切换具体实现：
///   - [LlmMode.stub] → TODO: StubLlmClient (03-02)
///   - [LlmMode.http]  → TODO: HttpLlmClient (03-03)

@ProviderFor(llmClient)
final llmClientProvider = LlmClientProvider._();

/// LLM 客户端实例——平台门控。
///
/// 在非桌面平台（Android/iOS）上访问此 provider 抛出 [UnsupportedError]。
/// 在桌面平台上根据 [llmModeProvider] 的值切换具体实现：
///   - [LlmMode.stub] → TODO: StubLlmClient (03-02)
///   - [LlmMode.http]  → TODO: HttpLlmClient (03-03)

final class LlmClientProvider
    extends $FunctionalProvider<LlmClient, LlmClient, LlmClient>
    with $Provider<LlmClient> {
  /// LLM 客户端实例——平台门控。
  ///
  /// 在非桌面平台（Android/iOS）上访问此 provider 抛出 [UnsupportedError]。
  /// 在桌面平台上根据 [llmModeProvider] 的值切换具体实现：
  ///   - [LlmMode.stub] → TODO: StubLlmClient (03-02)
  ///   - [LlmMode.http]  → TODO: HttpLlmClient (03-03)
  LlmClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'llmClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$llmClientHash();

  @$internal
  @override
  $ProviderElement<LlmClient> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LlmClient create(Ref ref) {
    return llmClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LlmClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LlmClient>(value),
    );
  }
}

String _$llmClientHash() => r'691f684cf5b46697563b240892b2b64f5517fe7c';
