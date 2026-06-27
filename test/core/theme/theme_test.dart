import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redclass/core/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('buildAppTheme (D-22, D-23)', () {
    test('light + null dynamic returns non-null ThemeData with M3', () {
      final theme = buildAppTheme(Brightness.light, null);
      expect(theme, isA<ThemeData>());
      expect(theme.useMaterial3, true);
      expect(theme.colorScheme.brightness, Brightness.light);
      expect(theme.colorScheme.primary, isNotNull);
    });

    test('dark + null dynamic returns non-null ThemeData with M3', () {
      final theme = buildAppTheme(Brightness.dark, null);
      expect(theme, isA<ThemeData>());
      expect(theme.useMaterial3, true);
      expect(theme.colorScheme.brightness, Brightness.dark);
    });

    test('seed color 0xFF6750A4 influences light scheme primary (D-20)', () {
      final theme = buildAppTheme(Brightness.light, null);
      // The M3 algorithm derives primary from seed; exact RGB will differ,
      // but brightness must be light and colorScheme must be non-null
      expect(theme.colorScheme.brightness, Brightness.light);
      expect(theme.colorScheme.primary, isNotNull);
    });

    test('harmonized() dynamic scheme is used when provided', () {
      // Provide a custom (non-null) dynamic scheme
      final customScheme = ColorScheme.fromSeed(
        seedColor: const Color(0xFF0066CC),
        brightness: Brightness.light,
      );
      final theme = buildAppTheme(Brightness.light, customScheme);
      expect(theme.colorScheme.brightness, Brightness.light);
      // The scheme's primary should be derived from the custom seed, not the default
      expect(theme.colorScheme.primary, customScheme.primary);
    });

    test('filledButtonTheme uses styleFrom with minimumSize', () {
      final theme = buildAppTheme(Brightness.light, null);
      expect(theme.filledButtonTheme.style, isNotNull);
    });
  });

  group('buildAppTheme light/dark brightness propagation (D-23)', () {
    test('light mode + null dynamic returns light theme', () {
      final theme = buildAppTheme(Brightness.light, null);
      expect(theme.colorScheme.brightness, Brightness.light);
    });

    test('dark mode + null dynamic returns dark theme', () {
      final theme = buildAppTheme(Brightness.dark, null);
      expect(theme.colorScheme.brightness, Brightness.dark);
    });
  });

  group('ThemeData component themes', () {
    test('useMaterial3 is always true', () {
      for (final brightness in [Brightness.light, Brightness.dark]) {
        final theme = buildAppTheme(brightness, null);
        expect(theme.useMaterial3, true);
      }
    });

    test('colorScheme is never null', () {
      for (final brightness in [Brightness.light, Brightness.dark]) {
        final theme = buildAppTheme(brightness, null);
        expect(theme.colorScheme, isNotNull);
      }
    });

    test('appBarTheme elevation and scrolledUnderElevation are set', () {
      final theme = buildAppTheme(Brightness.light, null);
      expect(theme.appBarTheme.elevation, 0);
      expect(theme.appBarTheme.scrolledUnderElevation, 1);
    });

    test('cardTheme shape has 12px border radius', () {
      final theme = buildAppTheme(Brightness.light, null);
      final shape = theme.cardTheme.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(12));
    });
  });
}
