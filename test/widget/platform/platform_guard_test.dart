// test/widget/platform/platform_guard_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redclass/core/platform/platform_guard.dart';
import 'package:redclass/core/platform/platform_info.dart';

void main() {
  testWidgets('shows child when requiresDesktop and platform is windows', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: UnsupportedFeatureGuard(
          requiresDesktop: true,
          info: PlatformInfo.forTesting(
            platform: AppPlatform.windows,
            shortestSide: 1200,
          ),
          fallback: const Text('FALLBACK'),
          child: const Text('CHILD'),
        ),
      ),
    );
    expect(find.text('CHILD'), findsOneWidget);
    expect(find.text('FALLBACK'), findsNothing);
  });

  testWidgets('shows fallback when requiresDesktop and platform is android', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: UnsupportedFeatureGuard(
          requiresDesktop: true,
          info: PlatformInfo.forTesting(
            platform: AppPlatform.android,
            shortestSide: 400,
          ),
          fallback: const Text('FALLBACK'),
          child: const Text('CHILD'),
        ),
      ),
    );
    expect(find.text('FALLBACK'), findsOneWidget);
    expect(find.text('CHILD'), findsNothing);
  });
}
