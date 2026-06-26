// test/widget/platform/adaptive_scaffold_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redclass/core/platform/platform_info.dart';
import 'package:redclass/core/widgets/adaptive_scaffold.dart';

void main() {
  testWidgets('compact shows AppBar with drawer', (t) async {
    await t.pumpWidget(
      MaterialApp(
        home: AdaptiveScaffold(
          title: 'T',
          body: const Text('B'),
          drawer: const Text('D'),
          info: PlatformInfo.forTesting(
            platform: AppPlatform.android,
            shortestSide: 400,
          ),
        ),
      ),
    );
    expect(find.byType(AppBar), findsOneWidget);
  });

  testWidgets('expanded renders drawer inline as side rail', (t) async {
    await t.pumpWidget(
      MaterialApp(
        home: AdaptiveScaffold(
          title: 'T',
          body: const Text('B'),
          drawer: const Text('D'),
          info: PlatformInfo.forTesting(
            platform: AppPlatform.windows,
            shortestSide: 1200,
          ),
        ),
      ),
    );
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('D'), findsOneWidget);
  });
}
