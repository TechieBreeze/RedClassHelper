# Phase 1 — Smoke Test Report

Generated: 2026-06-19T10:19:12Z

## Section 1: Static Analysis + Unit Tests

### flutter analyze

```
Analyzing RedClass...                                           
No issues found! (ran in 7.1s)
```

**Result: ✅ PASSED** — 0 errors, 0 warnings, 0 info.

### flutter test

```
00:00 +0: loading .../test/core/paths/path_resolver_test.dart
00:00 +1: PathResolver databasePath is appSupport/redclass.db (D-17)
00:00 +2: PathResolver tempDir returns the temp directory path
00:00 +3: PathResolver modelsDir creates appDocs/models/ if missing (D-18)
00:00 +4: PathResolver cacheDir creates appDocs/cache/ if missing
00:00 +5: PathResolver diagnosticsDir creates appDocs/diagnostics/ if missing
00:00 +6: PathResolver modelsDir is idempotent
00:00 +7: dynamic_color fallback null dynamicScheme falls back to ColorScheme.fromSeed
00:00 +8: dynamic_color all 4 modes (light/dark x null/dynamic) produce valid ThemeData
00:00 +9: dynamic_color kSeedColor is Color(0xFF6750A4)
00:00 +10: dynamic_color buildDynamicTheme handles null dynamicScheme
00:01 +11: buildAppTheme light + null dynamic returns non-null ThemeData with M3
00:01 +12: buildAppTheme dark + null dynamic returns non-null ThemeData with M3
00:01 +13: buildAppTheme seed color influences light scheme primary (D-20)
00:01 +14: buildAppTheme harmonized() dynamic scheme is used when provided
00:01 +15: buildAppTheme filledButtonTheme uses styleFrom with minimumSize
00:01 +16: buildDynamicTheme light mode + null dynamic returns light theme
00:01 +17: buildDynamicTheme dark mode + null dynamic returns dark theme
00:01 +18: ThemeData component themes useMaterial3 is always true
00:01 +19: ThemeData component themes colorScheme is never null
00:01 +20: ThemeData component themes appBarTheme elevation and scrolledUnderElevation are set
00:01 +21: ThemeData component themes cardTheme shape has 12px border radius
00:01 +22: AppDatabase schemaVersion is 1 (D-14)
00:01 +23: AppDatabase onCreate creates all 7 tables
00:01 +24: AppDatabase foreign_keys PRAGMA is ON after open
00:01 +25: AppDatabase QuestionBank insert + read round-trip (D-07)
00:02 +26: AppDatabase WrongLedgerEntry has UNIQUE on question_id (D-09)
00:03 +27: HomeScreen renders all sections per UI-SPEC (UI-02)
00:03 +28: appRouter initial location renders HomeScreen
00:03 +29: Tapping mode tile navigates to /quiz/new/<mode>
00:03 +30: Tapping stats entry navigates to /stats
00:03 +31: Tapping stats entry navigates to /stats (duplicate verification)
00:03 +32: appRouter navigates to /stats renders StatsScreen
00:03 +33: Disabled buttons are present
00:03 +34: appRouter navigates to /import renders ImportScreen
00:03 +35: Tapping bank empty state navigates to /import
00:03 +36: Tapping bank empty state navigates to /import (duplicate verification)
00:03 +37: appRouter navigates to /bank/some-id renders BankDetailScreen
00:03 +38: appRouter navigates to /quiz/bank-1/random renders QuizScreen
00:03 +39: appRouter unknown route renders errorBuilder
00:03 +39: All tests passed!
```

**Result: ✅ PASSED** — 39/39 tests passing across 6 test files.

### Test Suite Breakdown

| Test File | Tests | Status |
|-----------|-------|--------|
| `test/core/paths/path_resolver_test.dart` | 6 | ✅ |
| `test/core/theme/dynamic_color_fallback_test.dart` | 4 | ✅ |
| `test/core/theme/theme_test.dart` | 11 | ✅ |
| `test/data/db/migration_test.dart` | 5 | ✅ |
| `test/features/home/home_screen_test.dart` | 6 | ✅ |
| `test/routing/router_test.dart` | 7 | ✅ |
| **Total** | **39** | **✅ ALL PASSED** |

