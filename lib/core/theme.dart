// lib/core/theme.dart
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
  // Noto Sans SC — consistent CJK stroke weight across all sizes.
  // google_fonts caches the font locally after first download.
  final textTheme = GoogleFonts.notoSansScTextTheme();
  return ThemeData(
    useMaterial3: true, // M3 baseline (D-22)
    colorScheme: scheme,
    brightness: brightness,
    textTheme: textTheme,
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
