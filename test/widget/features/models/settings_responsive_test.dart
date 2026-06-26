// test/widget/features/models/settings_responsive_test.dart
// Task 17 — verifies SettingsScreen renders the right layout per form factor.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:redclass/core/platform/platform_info.dart';
import 'package:redclass/core/platform/responsive.dart';
import 'package:redclass/features/models/presentation/settings_screen.dart';
import 'package:redclass/features/quiz/providers/quiz_settings_provider.dart';

bool _hasDescendantConstrainedBoxMaxWidth(
  WidgetTester tester,
  Finder startFinder,
  double targetMaxWidth,
) {
  final matches = find
      .descendant(
        of: startFinder,
        matching: find.byWidgetPredicate(
          (w) =>
              w is ConstrainedBox && w.constraints.maxWidth == targetMaxWidth,
        ),
      )
      .evaluate();
  return matches.isNotEmpty;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'compact width (400x800) renders vertical layout key (no 720 ConstrainedBox)',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      final router = GoRouter(
        initialLocation: '/settings',
        routes: [
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: ResponsiveBuilder(
            info: PlatformInfo.forTesting(
              platform: AppPlatform.android,
              shortestSide: 400,
            ),
            builder: (context, _) => MediaQuery(
              data: const MediaQueryData(size: Size(400, 800)),
              child: MaterialApp.router(routerConfig: router),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('settings_vertical_layout')), findsOneWidget);
      expect(find.byKey(const Key('settings_horizontal_layout')), findsNothing);

      expect(
        _hasDescendantConstrainedBoxMaxWidth(
          tester,
          find.byKey(const Key('settings_vertical_layout')),
          720,
        ),
        isFalse,
      );
    },
  );

  testWidgets(
    'medium width (700x900) renders vertical layout key with 720 ConstrainedBox',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(700, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      final router = GoRouter(
        initialLocation: '/settings',
        routes: [
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: ResponsiveBuilder(
            info: PlatformInfo.forTesting(
              platform: AppPlatform.android,
              shortestSide: 700,
            ),
            builder: (context, _) => MediaQuery(
              data: const MediaQueryData(size: Size(700, 900)),
              child: MaterialApp.router(routerConfig: router),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('settings_vertical_layout')), findsOneWidget);
      expect(find.byKey(const Key('settings_horizontal_layout')), findsNothing);

      expect(
        _hasDescendantConstrainedBoxMaxWidth(
          tester,
          find.byKey(const Key('settings_vertical_layout')),
          720,
        ),
        isTrue,
      );
    },
  );

  testWidgets(
    'expanded width (1500x1000) renders horizontal layout key with 960 ConstrainedBox',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1500, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      final router = GoRouter(
        initialLocation: '/settings',
        routes: [
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: ResponsiveBuilder(
            info: PlatformInfo.forTesting(
              platform: AppPlatform.windows,
              shortestSide: 1500,
            ),
            builder: (context, _) => MediaQuery(
              data: const MediaQueryData(size: Size(1500, 1000)),
              child: MaterialApp.router(routerConfig: router),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('settings_horizontal_layout')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('settings_vertical_layout')), findsNothing);

      expect(
        _hasDescendantConstrainedBoxMaxWidth(
          tester,
          find.byKey(const Key('settings_horizontal_layout')),
          960,
        ),
        isTrue,
      );

      // Verify both section columns rendered (both 外观 and 高级 visible).
      expect(find.text('外观'), findsOneWidget);
      expect(find.text('高级'), findsOneWidget);
    },
  );
}
