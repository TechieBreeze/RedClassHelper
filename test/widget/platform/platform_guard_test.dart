// test/widget/platform/platform_guard_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redclass/core/platform/platform_guard.dart';

void main() {
  // PlatformInfo._detect() reads dart:io.Platform directly. On a Windows test
  // host Platform.isWindows is true so isDesktop=true; on a non-Windows host
  // isDesktop would be false and these tests would render fallback. The test
  // below assumes the test runner is a desktop OS (the project targets
  // Android+Windows). Size thresholds: shortestSide < 600 compact, < 840
  // medium, else expanded.

  testWidgets(
    'UnsupportedFeatureGuard(requiresDesktop:true) shows child on expanded',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(
        home: UnsupportedFeatureGuard(
          requiresDesktop: true,
          child: Text('CHILD'),
          fallback: Text('FALLBACK'),
        ),
      ));
      expect(find.text('CHILD'), findsOneWidget);
    },
  );
  testWidgets(
    'UnsupportedFeatureGuard(requiresDesktop:true) shows fallback on compact',
    (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(
        home: UnsupportedFeatureGuard(
          requiresDesktop: true,
          child: Text('CHILD'),
          fallback: Text('FALLBACK'),
        ),
      ));
      expect(find.text('FALLBACK'), findsOneWidget);
    },
  );
}