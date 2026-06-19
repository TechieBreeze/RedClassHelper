// test/routing/router_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:redclass/routing/router.dart';

void main() {
  group('appRouter (go_router — 11 routes)', () {
    testWidgets('initial location renders HomeScreen', (tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: appRouter));
      await tester.pumpAndSettle();
      expect(find.text('红课复习'), findsOneWidget);
    });

    test('routes are registered for all 11 paths', () {
      // Inspect GoRouter's internal configuration via the configuration list
      final configuration = appRouter.configuration;
      final paths = configuration.routes
          .whereType<GoRoute>()
          .map((r) => r.path)
          .toList();
      expect(
        paths,
        containsAll(<String>[
          '/',
          '/bank/:id',
          '/quiz/:bankId/:mode',
          '/stats',
          '/bookmarks',
          '/import',
          '/import/progress',
          '/import/preview/:jobId',
          '/import/summary/:jobId',
          '/settings',
          '/settings/models',
        ]),
      );
      expect(paths.length, 11);
    });

    testWidgets('navigates to /stats renders StatsScreen', (tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: appRouter));
      await tester.pumpAndSettle();
      // Initial = home; navigate to /stats
      appRouter.go('/stats');
      await tester.pumpAndSettle();
      expect(find.text('数据统计'), findsOneWidget);
    });

    testWidgets('navigates to /import renders ImportScreen', (tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: appRouter));
      await tester.pumpAndSettle();
      appRouter.go('/import');
      await tester.pumpAndSettle();
      expect(find.text('导入题库'), findsOneWidget);
    });

    testWidgets('navigates to /bookmarks renders BookmarksScreen',
        (tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: appRouter));
      await tester.pumpAndSettle();
      appRouter.go('/bookmarks');
      await tester.pumpAndSettle();
      expect(find.text('收藏夹'), findsOneWidget);
    });

    testWidgets('navigates to /bank/some-id renders BankDetailScreen',
        (tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: appRouter));
      await tester.pumpAndSettle();
      appRouter.go('/bank/some-id');
      await tester.pumpAndSettle();
      expect(find.text('题库详情'), findsOneWidget);
      expect(find.textContaining('some-id'), findsOneWidget);
    });

    testWidgets('navigates to /quiz/bank-1/random renders QuizScreen',
        (tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: appRouter));
      await tester.pumpAndSettle();
      appRouter.go('/quiz/bank-1/random');
      await tester.pumpAndSettle();
      expect(find.text('答题'), findsOneWidget);
      expect(find.textContaining('bank-1'), findsOneWidget);
      expect(find.textContaining('random'), findsOneWidget);
    });

    testWidgets('unknown route renders errorBuilder', (tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: appRouter));
      await tester.pumpAndSettle();
      appRouter.go('/this-route-does-not-exist');
      await tester.pumpAndSettle();
      expect(find.textContaining('Route not found'), findsOneWidget);
    });
  });
}
