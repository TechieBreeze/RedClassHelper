import 'package:flutter_test/flutter_test.dart';

import 'package:redclass/main.dart';

void main() {
  testWidgets('RedClassApp renders scaffold', (WidgetTester tester) async {
    await tester.pumpWidget(const RedClassApp());
    expect(find.text('RedClass'), findsOneWidget);
  });
}
