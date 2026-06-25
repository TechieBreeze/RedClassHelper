import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/quiz/providers/quiz_settings_provider.dart';

part 'color_scheme_provider.g.dart';

/// 预设主题色系
enum AppColorScheme {
  teal,
  bluePurple,
}

/// 主题色系选择 — 持久化在 SharedPreferences 中。
@riverpod
class AppColorSchemeNotifier extends _$AppColorSchemeNotifier {
  @override
  AppColorScheme build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final value = prefs.getString('app_color_scheme') ?? 'teal';
    return _fromString(value);
  }

  void setColorScheme(AppColorScheme scheme) {
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setString('app_color_scheme', scheme.name);
    state = scheme;
  }

  static AppColorScheme _fromString(String value) {
    return switch (value) {
      'bluePurple' => AppColorScheme.bluePurple,
      _ => AppColorScheme.teal,
    };
  }
}
