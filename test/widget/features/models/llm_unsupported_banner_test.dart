// test/widget/features/models/llm_unsupported_banner_test.dart
// Task 18 — verifies LlmUnsupportedBanner renders correctly per platform.
//
// Note: PlatformInfo.fromContext(context) detects platform via dart:io
// (which is the host platform in tests, i.e. Windows on this machine).
// To exercise the mobile/desktop branching in tests we pass `info:`
// directly to the banner; this matches the test-seam pattern used by
// UnsupportedFeatureGuard.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:redclass/core/platform/platform_info.dart';
import 'package:redclass/core/platform/responsive.dart';
import 'package:redclass/features/models/presentation/widgets/llm_unsupported_banner.dart';

void main() {
  testWidgets('renders SizedBox.shrink() on windows desktop', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ResponsiveBuilder(
            info: PlatformInfo.forTesting(
              platform: AppPlatform.windows,
              shortestSide: 1200,
            ),
            builder: (context, _) => const LlmUnsupportedBanner(
              info: PlatformInfo(
                platform: AppPlatform.windows,
                shortestSide: 1200,
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.byType(MaterialBanner), findsNothing);
    expect(find.byType(LlmUnsupportedBanner), findsOneWidget);
  });

  testWidgets('renders MaterialBanner with content on android mobile', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ResponsiveBuilder(
            info: PlatformInfo.forTesting(
              platform: AppPlatform.android,
              shortestSide: 400,
            ),
            builder: (context, _) => const LlmUnsupportedBanner(
              info: PlatformInfo(
                platform: AppPlatform.android,
                shortestSide: 400,
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.byType(MaterialBanner), findsOneWidget);
    expect(find.text('当前平台不支持本地 LLM 解析。请使用桌面端或回退到启发式解析。'), findsOneWidget);
    expect(find.text('知道了'), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
  });

  testWidgets(
    'explicit info override renders MaterialBanner without ResponsiveBuilder',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const LlmUnsupportedBanner(
              info: PlatformInfo(
                platform: AppPlatform.android,
                shortestSide: 400,
              ),
            ),
          ),
        ),
      );
      expect(find.byType(MaterialBanner), findsOneWidget);
      expect(find.text('当前平台不支持本地 LLM 解析。请使用桌面端或回退到启发式解析。'), findsOneWidget);
    },
  );
}
