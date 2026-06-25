// lib/core/theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 统一主色调 — 青绿色，亮暗模式共用同一个色系
const Color kSeedColor = Color(0xFF00897B);

/// 桌面端统一光标
final _clickCursor = WidgetStateProperty.all(SystemMouseCursors.click);

/// Hero 横幅渐变色
List<Color> heroGradient(ColorScheme cs, Brightness brightness) {
  if (brightness == Brightness.dark) {
    return const [
      Color(0xFF1A3A35),
      Color(0xFF1E3340),
    ];
  }
  return [cs.primary, cs.tertiary];
}

/// Hero 横幅阴影色
Color heroShadowColor(ColorScheme cs, Brightness brightness) {
  return cs.primary.withAlpha(brightness == Brightness.dark ? 20 : 50);
}

/// 构造 App 全局 ThemeData
ThemeData buildAppTheme(Brightness brightness, ColorScheme? dynamicScheme) {
  // 不使用 dynamicColor，统一用 kSeedColor 生成配色
  final scheme = ColorScheme.fromSeed(
    seedColor: kSeedColor,
    brightness: brightness,
  );
  return _buildThemeData(scheme, brightness);
}

ThemeData buildDynamicTheme(Brightness brightness, ColorScheme? dynamicScheme) {
  return buildAppTheme(brightness, dynamicScheme);
}

ThemeData _buildThemeData(ColorScheme scheme, Brightness brightness) {
  final base = brightness == Brightness.dark
      ? Typography.whiteMountainView
      : Typography.blackMountainView;
  final notoSans = GoogleFonts.notoSansScTextTheme(base);

  // 暗色模式：基于同色系手动调制更柔和的版本
  final ColorScheme effectiveScheme;
  if (brightness == Brightness.dark) {
    effectiveScheme = const ColorScheme(
      brightness: Brightness.dark,
      // 主色 — 柔和青绿
      primary: Color(0xFF80CBC4),
      onPrimary: Color(0xFF003731),
      primaryContainer: Color(0xFF005048),
      onPrimaryContainer: Color(0xFF9DF5EC),
      // 次要色 — 灰青
      secondary: Color(0xFFB0CCC5),
      onSecondary: Color(0xFF1D342F),
      secondaryContainer: Color(0xFF334B46),
      onSecondaryContainer: Color(0xFFCCDFD8),
      // 第三色 — 蓝灰
      tertiary: Color(0xFFAECAE2),
      onTertiary: Color(0xFF143248),
      tertiaryContainer: Color(0xFF2C4960),
      onTertiaryContainer: Color(0xFFCBE6FF),
      // 错误
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),
      // 表面
      surface: Color(0xFF0F1512),
      onSurface: Color(0xFFDEE4E0),
      onSurfaceVariant: Color(0xFFBFC9C4),
      surfaceContainerHighest: Color(0xFF2A312E),
      surfaceContainerHigh: Color(0xFF1E2522),
      surfaceContainer: Color(0xFF171D1A),
      surfaceContainerLow: Color(0xFF121816),
      surfaceDim: Color(0xFF0F1512),
      surfaceBright: Color(0xFF353B38),
      // 轮廓
      outline: Color(0xFF8A938F),
      outlineVariant: Color(0xFF3F4945),
      // 其他
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFFDEE4E0),
      inversePrimary: Color(0xFF006B5E),
    );
  } else {
    // 亮色模式：直接用 fromSeed 生成的配色
    effectiveScheme = scheme;
  }

  return ThemeData(
    useMaterial3: true,
    colorScheme: effectiveScheme,
    brightness: brightness,
    textTheme: notoSans,
    scaffoldBackgroundColor: effectiveScheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: effectiveScheme.surface,
      foregroundColor: effectiveScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 1,
    ),
    cardTheme: CardThemeData(
      elevation: 1,
      margin: EdgeInsets.zero,
      color: effectiveScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        mouseCursor: _clickCursor,
        minimumSize: WidgetStateProperty.all(const Size(64, 40)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        mouseCursor: _clickCursor,
        foregroundColor: WidgetStateProperty.all(effectiveScheme.primary),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        mouseCursor: _clickCursor,
        foregroundColor: WidgetStateProperty.all(effectiveScheme.primary),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        mouseCursor: _clickCursor,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        mouseCursor: _clickCursor,
      ),
    ),
    listTileTheme: ListTileThemeData(
      mouseCursor: WidgetStateProperty.all(SystemMouseCursors.click),
    ),
    switchTheme: SwitchThemeData(
      mouseCursor: WidgetStateProperty.all(SystemMouseCursors.click),
    ),
    radioTheme: RadioThemeData(
      mouseCursor: WidgetStateProperty.all(SystemMouseCursors.click),
    ),
    checkboxTheme: CheckboxThemeData(
      mouseCursor: WidgetStateProperty.all(SystemMouseCursors.click),
    ),
    tabBarTheme: TabBarThemeData(
      mouseCursor: WidgetStateProperty.all(SystemMouseCursors.click),
    ),
  );
}
