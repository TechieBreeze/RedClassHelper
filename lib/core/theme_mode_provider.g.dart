// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_mode_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 主题模式设置 — 跟随系统 / 亮色 / 暗色。
///
/// 持久化在 SharedPreferences 中，key 为 'theme_mode'。
/// 默认跟随系统。

@ProviderFor(ThemeModeNotifier)
final themeModeProvider = ThemeModeNotifierProvider._();

/// 主题模式设置 — 跟随系统 / 亮色 / 暗色。
///
/// 持久化在 SharedPreferences 中，key 为 'theme_mode'。
/// 默认跟随系统。
final class ThemeModeNotifierProvider
    extends $NotifierProvider<ThemeModeNotifier, ThemeMode> {
  /// 主题模式设置 — 跟随系统 / 亮色 / 暗色。
  ///
  /// 持久化在 SharedPreferences 中，key 为 'theme_mode'。
  /// 默认跟随系统。
  ThemeModeNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeModeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeModeNotifierHash();

  @$internal
  @override
  ThemeModeNotifier create() => ThemeModeNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThemeMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThemeMode>(value),
    );
  }
}

String _$themeModeNotifierHash() => r'edea70b52d57e3fea0bb95ee570b5618538b5067';

/// 主题模式设置 — 跟随系统 / 亮色 / 暗色。
///
/// 持久化在 SharedPreferences 中，key 为 'theme_mode'。
/// 默认跟随系统。

abstract class _$ThemeModeNotifier extends $Notifier<ThemeMode> {
  ThemeMode build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ThemeMode, ThemeMode>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ThemeMode, ThemeMode>,
              ThemeMode,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
