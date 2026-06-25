// test/widget/platform/responsive_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redclass/core/platform/responsive.dart';

Widget _wrap(Widget child, {required double width, required double height}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(size: Size(width, height)),
      child: child,
    ),
  );
}

void main() {
  testWidgets('AdaptiveLayout renders compact branch on small screen', (t) async {
    await t.pumpWidget(_wrap(
      AdaptiveLayout(compact: (_) => const Text('C'), medium: (_) => const Text('M'), expanded: (_) => const Text('E')),
      width: 400, height: 800,
    ));
    expect(find.text('C'), findsOneWidget);
  });
  testWidgets('AdaptiveLayout renders medium branch on tablet', (t) async {
    await t.pumpWidget(_wrap(
      AdaptiveLayout(compact: (_) => const Text('C'), medium: (_) => const Text('M'), expanded: (_) => const Text('E')),
      width: 720, height: 1024,
    ));
    expect(find.text('M'), findsOneWidget);
  });
  testWidgets('AdaptiveLayout falls back to compact when medium/expanded missing', (t) async {
    await t.pumpWidget(_wrap(AdaptiveLayout(compact: (_) => const Text('C')), width: 720, height: 1024));
    expect(find.text('C'), findsOneWidget);
  });
}
