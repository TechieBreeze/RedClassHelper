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
  // Noto Sans SC — 只应用字体，不设置颜色。
  // GoogleFonts.notoSansScTextTheme() 返回固定黑色文字，会覆盖 M3 暗色模式颜色。
  // 用 fontFamily 方式让 M3 的 onSurface/onPrimary 等颜色系统正常工作。
  final base = brightness == Brightness.dark
      ? Typography.whiteMountainView
      : Typography.blackMountainView;
  final notoSans = GoogleFonts.notoSansScTextTheme(base);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: brightness,
    textTheme: notoSans,
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
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.primary,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: scheme.primary,
      ),
    ),
  );
}
