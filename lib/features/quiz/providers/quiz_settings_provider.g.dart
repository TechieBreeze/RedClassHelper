// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz_settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// SharedPreferences 实例 -- 在 main() 中预初始化, 通过 ProviderScope override 注入。
///
/// 避免 shared_preferences 的异步初始化竞态 (RESEARCH.md Pitfall 4)。
/// 使用模式与 [pathResolverProvider] 相同: 预初始化 + override。

@ProviderFor(sharedPreferences)
final sharedPreferencesProvider = SharedPreferencesProvider._();

/// SharedPreferences 实例 -- 在 main() 中预初始化, 通过 ProviderScope override 注入。
///
/// 避免 shared_preferences 的异步初始化竞态 (RESEARCH.md Pitfall 4)。
/// 使用模式与 [pathResolverProvider] 相同: 预初始化 + override。

final class SharedPreferencesProvider
    extends
        $FunctionalProvider<
          SharedPreferences,
          SharedPreferences,
          SharedPreferences
        >
    with $Provider<SharedPreferences> {
  /// SharedPreferences 实例 -- 在 main() 中预初始化, 通过 ProviderScope override 注入。
  ///
  /// 避免 shared_preferences 的异步初始化竞态 (RESEARCH.md Pitfall 4)。
  /// 使用模式与 [pathResolverProvider] 相同: 预初始化 + override。
  SharedPreferencesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sharedPreferencesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sharedPreferencesHash();

  @$internal
  @override
  $ProviderElement<SharedPreferences> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SharedPreferences create(Ref ref) {
    return sharedPreferences(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SharedPreferences value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SharedPreferences>(value),
    );
  }
}

String _$sharedPreferencesHash() => r'd8a123f8131dddc25218cf0b7e15eff43b58543c';

/// 答题设置 Notifier -- D-02, D-03, D-07。
///
/// 从 shared_preferences 读取 quiz_submit_mode (默认 'instant') 和
/// quiz_advance_mode (默认 'auto')。
/// 写入时同步持久化到 shared_preferences。

@ProviderFor(QuizSettingsNotifier)
final quizSettingsProvider = QuizSettingsNotifierProvider._();

/// 答题设置 Notifier -- D-02, D-03, D-07。
///
/// 从 shared_preferences 读取 quiz_submit_mode (默认 'instant') 和
/// quiz_advance_mode (默认 'auto')。
/// 写入时同步持久化到 shared_preferences。
final class QuizSettingsNotifierProvider
    extends $NotifierProvider<QuizSettingsNotifier, QuizSettings> {
  /// 答题设置 Notifier -- D-02, D-03, D-07。
  ///
  /// 从 shared_preferences 读取 quiz_submit_mode (默认 'instant') 和
  /// quiz_advance_mode (默认 'auto')。
  /// 写入时同步持久化到 shared_preferences。
  QuizSettingsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'quizSettingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$quizSettingsNotifierHash();

  @$internal
  @override
  QuizSettingsNotifier create() => QuizSettingsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(QuizSettings value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<QuizSettings>(value),
    );
  }
}

String _$quizSettingsNotifierHash() =>
    r'e15d616b973eddf58ded8b64c662c5d9b5718cae';

/// 答题设置 Notifier -- D-02, D-03, D-07。
///
/// 从 shared_preferences 读取 quiz_submit_mode (默认 'instant') 和
/// quiz_advance_mode (默认 'auto')。
/// 写入时同步持久化到 shared_preferences。

abstract class _$QuizSettingsNotifier extends $Notifier<QuizSettings> {
  QuizSettings build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<QuizSettings, QuizSettings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<QuizSettings, QuizSettings>,
              QuizSettings,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
