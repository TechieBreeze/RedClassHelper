import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/quiz/providers/quiz_settings_provider.dart';

part 'theme_mode_provider.g.dart';

/// 主题模式设置 — 跟随系统 / 亮色 / 暗色。
///
/// 持久化在 SharedPreferences 中，key 为 'theme_mode'。
/// 默认跟随系统。
@riverpod
class ThemeModeNotifier extends _$ThemeModeNotifier {
  @override
  ThemeMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final modeStr = prefs.getString('theme_mode') ?? 'system';
    return _fromString(modeStr);
  }

  /// 设置主题模式并持久化。
  void setThemeMode(ThemeMode mode) {
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setString('theme_mode', mode.name);
    state = mode;
  }

  static ThemeMode _fromString(String value) {
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }
}
