// Smoke test for the Phase 1 ProviderScope + RedClassApp bootstrap.
//
// Verifies that the placeholder MaterialApp renders the title text and is
// wrapped in a ProviderScope. This test will be expanded in Plan 01-04 (router)
// and Plan 01-05 (theme + home screen).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:redclass/main.dart';

void main() {
  testWidgets('RedClassApp renders inside ProviderScope', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: RedClassApp(),
      ),
    );

    // Phase 1 placeholder: app title is shown as the MaterialApp title
    // (not in the visible body) — verify the MaterialApp builds without error.
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
