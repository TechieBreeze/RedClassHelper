import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redclass/core/nav/safe_nav.dart';
import 'package:redclass/features/quiz/providers/quiz_settings_provider.dart';
import 'package:redclass/routing/router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stage C nav tests covering the NavGuard cooldown contract.
///
/// The actual back-navigation from QuizScreen → BankDetail is already
/// covered by `bank_detail/navigation_test.dart`. This file focuses on
/// the NavGuard primitive itself (the one piece of state shared
/// between multiple screens).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    NavGuard.resetForTest();
  });

  group('NavGuard.tryAcquire', () {
    test('first call returns true', () {
      expect(NavGuard.tryAcquire(), isTrue);
    });

    test(
      'second call within cooldown window returns false',
      () async {
        expect(NavGuard.tryAcquire(), isTrue);
        // Any sub-400ms delay should keep us in the cooldown window.
        // Use 50ms — fast enough to stay well within cooldown even with
        // test-framework overhead.
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(NavGuard.tryAcquire(), isFalse);
      },
      timeout: const Timeout(Duration(seconds: 1)),
    );

    test(
      'call after cooldown elapses returns true again',
      () async {
        expect(NavGuard.tryAcquire(), isTrue);
        await Future<void>.delayed(const Duration(milliseconds: 450));
        expect(NavGuard.tryAcquire(), isTrue);
      },
      timeout: const Timeout(Duration(seconds: 2)),
    );

    test(
      'fakeAsync: elapsed time contracts multiple calls into one window',
      () {
        fakeAsync((async) {
          expect(NavGuard.tryAcquire(), isTrue);
          async.elapse(const Duration(milliseconds: 100));
          expect(NavGuard.tryAcquire(), isFalse);
          async.elapse(const Duration(milliseconds: 299));
          expect(NavGuard.tryAcquire(), isFalse);
        });
      },
    );
  });

  group('SafeNavContext.safePush integration', () {
    testWidgets(
      'safePush on a descendant context reaches GoRouter.push (no throw)',
      (tester) async {
        final prefs = await SharedPreferences.getInstance();
        appRouter.go('/');
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
            ],
            child: MaterialApp.router(routerConfig: appRouter),
          ),
        );
        await tester.pumpAndSettle();

        // Use a context deep enough that the GoRouter ancestor is in scope.
        final scaffoldCtx = tester.element(find.byType(Scaffold).first);
        final future = scaffoldCtx.safePush('/some-route');
        await tester.pumpAndSettle();

        expect(future, isA<Future<dynamic>>());
      },
    );
  });
}