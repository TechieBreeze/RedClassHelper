// lib/core/theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'color_scheme_provider.dart';

/// 桌面端统一光标
final _clickCursor = WidgetStateProperty.all(SystemMouseCursors.click);

/// Hero 横幅渐变色
List<Color> heroGradient(ColorScheme cs, Brightness brightness) {
  if (brightness == Brightness.dark) {
    return [cs.primary.withAlpha(40), cs.tertiary.withAlpha(30)];
  }
  return [cs.primary, cs.tertiary];
}

/// Hero 横幅阴影色
Color heroShadowColor(ColorScheme cs, Brightness brightness) {
  return cs.primary.withAlpha(brightness == Brightness.dark ? 20 : 50);
}

/// 构造 App 全局 ThemeData
ThemeData buildAppTheme(Brightness brightness, ColorScheme? dynamicScheme, {AppColorScheme colorScheme = AppColorScheme.teal}) {
  final seedColor = seedColorForScheme(colorScheme);
  final scheme = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: brightness,
  );
  return _buildThemeData(scheme, brightness, colorScheme);
}

/// 根据预设主题返回 seedColor
Color seedColorForScheme(AppColorScheme scheme) {
  return switch (scheme) {
    AppColorScheme.teal => const Color(0xFF00897B),
    AppColorScheme.bluePurple => const Color(0xFF5C6BC0),
  };
}

/// 暗色模式手动调制的 ColorScheme
ColorScheme _darkSchemeFor(AppColorScheme scheme) {
  return switch (scheme) {
    AppColorScheme.teal => const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF80CBC4),
      onPrimary: Color(0xFF003731),
      primaryContainer: Color(0xFF005048),
      onPrimaryContainer: Color(0xFF9DF5EC),
      secondary: Color(0xFFB0CCC5),
      onSecondary: Color(0xFF1D342F),
      secondaryContainer: Color(0xFF334B46),
      onSecondaryContainer: Color(0xFFCCDFD8),
      tertiary: Color(0xFFAECAE2),
      onTertiary: Color(0xFF143248),
      tertiaryContainer: Color(0xFF2C4960),
      onTertiaryContainer: Color(0xFFCBE6FF),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),
      surface: Color(0xFF0F1512),
      onSurface: Color(0xFFDEE4E0),
      onSurfaceVariant: Color(0xFFBFC9C4),
      surfaceContainerHighest: Color(0xFF2A312E),
      surfaceContainerHigh: Color(0xFF1E2522),
      surfaceContainer: Color(0xFF171D1A),
      surfaceContainerLow: Color(0xFF121816),
      surfaceDim: Color(0xFF0F1512),
      surfaceBright: Color(0xFF353B38),
      outline: Color(0xFF8A938F),
      outlineVariant: Color(0xFF3F4945),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFFDEE4E0),
      inversePrimary: Color(0xFF006B5E),
    ),
    AppColorScheme.bluePurple => const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF9FA8DA),
      onPrimary: Color(0xFF283593),
      primaryContainer: Color(0xFF3949AB),
      onPrimaryContainer: Color(0xFFD1D9FF),
      secondary: Color(0xFFB0BEC5),
      onSecondary: Color(0xFF263238),
      secondaryContainer: Color(0xFF37474F),
      onSecondaryContainer: Color(0xFFCFD8DC),
      tertiary: Color(0xFFCE93D8),
      onTertiary: Color(0xFF4A148C),
      tertiaryContainer: Color(0xFF6A1B9A),
      onTertiaryContainer: Color(0xFFF3E5F5),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),
      surface: Color(0xFF111318),
      onSurface: Color(0xFFE1E2E8),
      onSurfaceVariant: Color(0xFFC4C6CF),
      surfaceContainerHighest: Color(0xFF2D2F36),
      surfaceContainerHigh: Color(0xFF22232A),
      surfaceContainer: Color(0xFF1C1D24),
      surfaceContainerLow: Color(0xFF16171E),
      surfaceDim: Color(0xFF111318),
      surfaceBright: Color(0xFF37393F),
      outline: Color(0xFF8E9099),
      outlineVariant: Color(0xFF44474E),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFFE1E2E8),
      inversePrimary: Color(0xFF5361C4),
    ),
  };
}

ThemeData _buildThemeData(ColorScheme scheme, Brightness brightness, AppColorScheme colorScheme) {
  final base = brightness == Brightness.dark
      ? Typography.whiteMountainView
      : Typography.blackMountainView;
  final notoSans = GoogleFonts.notoSansScTextTheme(base);

  final ColorScheme effectiveScheme;
  if (brightness == Brightness.dark) {
    effectiveScheme = _darkSchemeFor(colorScheme);
  } else {
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

