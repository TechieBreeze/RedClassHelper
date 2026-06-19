// lib/core/theme.dart
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';

/// Material 3 主题种子色 — fallback (D-20)
const Color kSeedColor = Color(0xFF6750A4);

/// 构造 App 全局 ThemeData
///
/// [brightness]: Brightness.light / Brightness.dark
/// [dynamicScheme]: 来自 dynamic_color 包的 ColorScheme?;为 null 时回退到 ColorScheme.fromSeed
/// (D-22: 手写 ThemeData, 不使用 flex_color_scheme)
/// (D-23: 函数名固定为 buildAppTheme)
ThemeData buildAppTheme(Brightness brightness, ColorScheme? dynamicScheme) {
  final scheme = dynamicScheme?.harmonized() ??
      ColorScheme.fromSeed(seedColor: kSeedColor, brightness: brightness);
  return _buildThemeData(scheme, brightness);
}

/// 构造 Dynamic Color ThemeData (D-23 命名) — 与 buildAppTheme 行为一致, 命名以备 future 扩展
ThemeData buildDynamicTheme(Brightness brightness, ColorScheme? dynamicScheme) {
  return buildAppTheme(brightness, dynamicScheme);
}

ThemeData _buildThemeData(ColorScheme scheme, Brightness brightness) {
  return ThemeData(
    useMaterial3: true, // M3 baseline (D-22)
    colorScheme: scheme,
    brightness: brightness,
    // Material 3 默认 typography (4 sizes / 2 weights per UI-SPEC §Typography)
    // 36/24/16/14 来自 M3 headlineLarge / headlineSmall / bodyLarge / bodyMedium
    // 不显式覆盖以减少维护成本 — Phase 6 polish 阶段可微调
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 1,
    ),
    cardTheme: CardThemeData(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 40),
      ),
    ),
  );
}
