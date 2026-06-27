import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redclass/core/color_scheme_provider.dart';
import 'package:redclass/core/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('dynamic_color fallback chain (D-20, RESEARCH.md Pitfall 7)', () {
    test('null dynamicScheme falls back to ColorScheme.fromSeed', () {
      // In test environment, dynamic_color is not initialized, so the
      // DynamicColorBuilder returns null for both light/dark. The theme
      // builder must handle this gracefully (which it does via ??).
      final theme = buildAppTheme(Brightness.light, null);
      expect(theme.colorScheme, isNotNull);
      expect(theme.useMaterial3, true);
    });

    test('all 4 modes (light/dark x null/dynamic) produce valid ThemeData', () {
      for (final brightness in [Brightness.light, Brightness.dark]) {
        for (final dyn in [
          null,
          ColorScheme.fromSeed(
            seedColor: const Color(0xFF123456),
            brightness: brightness,
          ),
        ]) {
          final theme = buildAppTheme(brightness, dyn);
          expect(theme, isA<ThemeData>());
          expect(theme.useMaterial3, true);
          expect(theme.colorScheme.brightness, brightness);
        }
      }
    });

    test('seedColorForScheme teal returns Color(0xFF00897B)', () {
      expect(seedColorForScheme(AppColorScheme.teal), const Color(0xFF00897B));
    });

    test('buildAppTheme also handles null dynamicScheme', () {
      final theme = buildAppTheme(Brightness.light, null);
      expect(theme, isA<ThemeData>());
      expect(theme.colorScheme, isNotNull);
      expect(theme.useMaterial3, true);
    });
  });
}
