# Testing

## Framework

- **`flutter_test`** (SDK package) — unit + widget tests
- **39 tests total** across 6 test files
- All tests pass: `flutter test` → `39/39 passed`

## Test Files

| File | Tests | Focus |
|------|-------|-------|
| `test/core/paths/path_resolver_test.dart` | 8 | PathResolver platform directories, create() async |
| `test/core/theme/dynamic_color_fallback_test.dart` | 4 | Null fallback → fromSeed, non-null harmonized() |
| `test/core/theme/theme_test.dart` | 4 | ThemeData brightness, typography, color scheme |
| `test/data/db/migration_test.dart` | 5 | schemaVersion, 7-table creation, FK PRAGMA, CRUD round-trip, UNIQUE constraint |
| `test/features/home/home_screen_test.dart` | 12 | Widget rendering, tile count, navigation taps |
| `test/routing/router_test.dart` | 6 | All 6 routes resolve, error builder, path params |

## Test Patterns

### Database Testing (migration_test.dart)

```dart
void main() {
  group('AppDatabase schema', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());   // in-memory, no disk
    });

    tearDown(() async {
      await db.close();
    });

    test('schemaVersion is 1', () {
      expect(db.schemaVersion, 1);
    });
  });
}
```

- **In-memory database** via `NativeDatabase.memory()` — no file system dependency
- **`setUp`/`tearDown`** create fresh DB per test — full isolation
- **PRAGMA verification:** `db.customSelect('PRAGMA foreign_keys').getSingle()`
- **UNIQUE constraint testing:** `expectLater(() => db.insert(...), throwsA(isA<Exception>()))`

### Widget Testing (home_screen_test.dart)

```dart
testWidgets('renders section headers', (tester) async {
  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: appRouter,
    ),
  );
  await tester.pumpAndSettle();

  expect(find.text('题库'), findsOneWidget);
  expect(find.text('复习模式'), findsOneWidget);
});
```

- **Wraps in `MaterialApp.router`** with real `appRouter` — integration-level widget tests
- **`pumpAndSettle()`** waits for animations to complete
- **Content assertion** via `find.text()`, `find.byIcon()`, `find.byType()`

### GoRouter Testing (router_test.dart)

```dart
test('navigates to /import', () {
  final matches = appRouter.routerDelegate.matches('/import');
  expect(matches, isNotEmpty);
});
```

- Tests route resolution directly against GoRouter configuration
- No widget pumping needed for route matching

## Coverage

No coverage tool configured yet. All tests are focused on public API / behavior, not internal implementation.

## Testing Gaps (for later phases)

| Gap | Priority | Phase |
|-----|----------|-------|
| drift DAO query tests | Medium | 2 |
| File parsing unit tests (with real .doc/.docx samples) | High | 2 |
| Import pipeline integration tests | High | 2 |
| LLM integration tests | High | 3 |
| Quiz logic TDD | High | 4 |
| E2E smoke tests (real device) | Medium | 7 |
| Coverage enforcement (80%+) | Low | 7 |
