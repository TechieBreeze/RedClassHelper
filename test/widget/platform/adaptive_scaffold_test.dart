// test/widget/platform/adaptive_scaffold_test.dart
//
// AdaptiveScaffold now wraps a plain Scaffold — the drawer is always rendered
// as Scaffold.drawer (off-canvas + hamburger in AppBar), never as a permanent
// side rail.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redclass/core/widgets/adaptive_scaffold.dart';

void main() {
  testWidgets('renders AppBar with title, actions, and body', (t) async {
    await t.pumpWidget(
      MaterialApp(
        home: AdaptiveScaffold(
          title: 'T',
          actions: const [Icon(Icons.settings)],
          body: const Text('B'),
          drawer: const Drawer(child: Text('D')),
        ),
      ),
    );
    expect(find.text('T'), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
  });
}
