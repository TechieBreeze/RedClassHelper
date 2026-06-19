---
phase: 01-foundation-persistence
plan: "05"
subsystem: ui
tags: [material3, flutter, dynamic_color, home-screen, theme, go_router, widget-test]

# Dependency graph
requires:
  - phase: 01-foundation-persistence
    plan: "04"
    provides: GoRouter 6 routes + placeholder screens

provides:
  - Material 3 theme system (buildAppTheme + buildDynamicTheme per D-22/D-23)
  - DynamicColorBuilder wrapper in main.dart (Pitfall 7 mitigation)
  - Full home screen with UI-SPEC layout (3 mode tiles + stats + bank empty state)
  - 20 new widget tests (theme + home screen)
  - kSeedColor = Color(0xFF6750A4) as M3 fallback seed

affects: [01-06, 02-01, 04-05, 06-01]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - DynamicColorBuilder → buildAppTheme fallback chain (D-20/D-23)
    - GoRouter singleton setUp pattern for test isolation (appRouter.go('/'))
    - LayoutBuilder responsive gutters (md/lg/xl for compact/medium/expanded)
    - ignore_for_file for const lints when LayoutBuilder prevents const context

key-files:
  created:
    - lib/core/theme.dart
    - test/core/theme/theme_test.dart
    - test/core/theme/dynamic_color_fallback_test.dart
    - test/features/home/home_screen_test.dart
  modified:
    - lib/main.dart
    - lib/features/home/presentation/home_screen.dart

key-decisions:
  - "kSeedColor = Color(0xFF6750A4) as M3 baseline fallback seed (D-20)"
  - "Settings gear icon added to AppBar → /settings (deferred to Phase 2)"
  - "GoRouter state leak between tests fixed with setUp appRouter.go('/')"
  - "ignore_for_file: prefer_const_constructors in HomeScreen (LayoutBuilder prevents const context)"

patterns-established:
  - "DynamicColorBuilder pattern: wrap MaterialApp.router, pass ColorScheme? to buildAppTheme, harmonized() with fromSeed fallback"
  - "GoRouter test isolation: setUp { appRouter.go('/') } before each testWidgets"
  - "ensureVisible before tapping off-screen widgets in scroll views"
  - "ThemeData component themes: AppBarTheme(elevation:0, scrolledUnderElevation:1) + CardThemeData(borderRadius:12)"

requirements-completed: []

# Metrics
duration: 45min
completed: "2026-06-19"
---

# Phase 01 Plan 05: Material 3 Theme + Full Home Screen UI-SPEC Summary

**Material 3 theme system with DynamicColorBuilder fallback chain, full home screen with 3 mode tiles + stats entry + bank empty state, and 20 widget tests**

## Performance

- **Duration:** ~45 min
- **Started:** 2026-06-19T14:00:00Z
- **Completed:** 2026-06-19T14:45:00Z
- **Tasks:** 4 completed
- **Files modified:** 6 (2 source + 3 test + 1 test modified)
- **Tests:** 39 total (19 previous + 20 new), all green

## Accomplishments

- Created `lib/core/theme.dart` with `buildAppTheme(Brightness, ColorScheme?)` and `buildDynamicTheme(Brightness, ColorScheme?)` per D-22/D-23
- Wired `DynamicColorBuilder` around `MaterialApp.router` in `main.dart` (Pitfall 7 mitigation)
- Replaced placeholder HomeScreen with full UI-SPEC layout: 3 mode tiles (乱序抽题 / 错题复习 / 错题抽查), bank empty state, stats entry tile
- 20 new widget tests covering theme correctness, dynamic color fallback, and home screen navigation

## Task Commits

Each task was committed atomically:

1. **Task 1: Create lib/core/theme.dart** — `145f203` (feat)
2. **Task 2: Replace HomeScreen with full UI-SPEC layout** — `dc9b2cb` (feat)
3. **Task 3: Wire DynamicColorBuilder in main.dart** — `9f18663` (feat)
4. **Task 4: Write 12 widget tests** — `1f1fb9b` (test)

## Files Created/Modified

- `lib/core/theme.dart` — `buildAppTheme`, `buildDynamicTheme`, `kSeedColor`, M3 component themes
- `lib/main.dart` — DynamicColorBuilder wrapper, imports dynamic_color + theme
- `lib/features/home/presentation/home_screen.dart` — Full home screen (3 mode tiles + stats + bank empty state + Settings gear)
- `test/core/theme/theme_test.dart` — 11 tests: buildAppTheme, buildDynamicTheme, component themes
- `test/core/theme/dynamic_color_fallback_test.dart` — 4 tests: fallback chain, kSeedColor, all 4 modes
- `test/features/home/home_screen_test.dart` — 5 tests: UI layout, mode/stats/import navigation, disabled buttons

## Decisions Made

- Settings gear icon added to AppBar (→ `/settings`, deferred to Phase 2) per test #7 requirement
- `ignore_for_file: prefer_const_constructors` in HomeScreen — LayoutBuilder builder is not a const context
- GoRouter state leak between tests resolved with `setUp { appRouter.go('/') }` pattern
- Stats entry navigation test uses `ensureVisible` because chevron_right icon is below fold in 800×600 viewport

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 — Missing Critical] Added settings gear icon to AppBar**
- **Found during:** Task 2 (HomeScreen implementation)
- **Issue:** Plan task code omitted the trailing gear icon but critical_guidance test #7 required it
- **Fix:** Added `Icons.settings_outlined` IconButton in AppBar actions → `/settings`
- **Files modified:** `lib/features/home/presentation/home_screen.dart`
- **Verification:** `grep -c "Icons.settings_outlined"` returns 1; `find.byIcon(Icons.settings_outlined)` test passes
- **Committed in:** `dc9b2cb` (Task 2 commit)

**2. [Rule 1 — Bug] "数据统计" text appears twice in the widget tree**
- **Found during:** Task 4 (home screen test)
- **Issue:** Section header `_SectionHeader(title: '数据统计')` and stats tile `Text('数据统计')` both match `find.text('数据统计')`
- **Fix:** Changed test assertion from `findsOneWidget` to `findsNWidgets(2)` for the layout test
- **Files modified:** `test/features/home/home_screen_test.dart`
- **Verification:** Test passes
- **Committed in:** Part of `1f1fb9b` (Task 4 commit)

**3. [Rule 3 — Blocking] GoRouter singleton state leaked between test suites**
- **Found during:** Task 4 (test suite integration)
- **Issue:** Router tests navigate to non-home locations; subsequent home screen tests rendered wrong screens
- **Fix:** Added `setUp { appRouter.go('/') }` in home_screen_test.dart
- **Files modified:** `test/features/home/home_screen_test.dart`
- **Verification:** All 5 home screen tests pass in full suite
- **Committed in:** Part of `1f1fb9b` (Task 4 commit)

**4. [Rule 1 — Bug] Stats entry chevron_right icon rendered below viewport**
- **Found during:** Task 4 (stats navigation test)
- **Issue:** In 800×600 test viewport, the stats entry tile (at the bottom of the SingleChildScrollView) was off-screen at y=692
- **Fix:** Added `await tester.ensureVisible(statsIcon)` before tapping
- **Files modified:** `test/features/home/home_screen_test.dart`
- **Verification:** Navigation test passes, StatsScreen loads correctly
- **Committed in:** Part of `1f1fb9b` (Task 4 commit)

---

**Total deviations:** 4 auto-fixed (1 missing critical, 2 bugs, 1 blocking)
**Impact on plan:** All auto-fixes were necessary for test correctness and spec compliance. No scope creep.

## Issues Encountered

- `prefer_const_constructors` lint fired inside LayoutBuilder builder (not const context) — resolved with `ignore_for_file` directive
- GoRouter global singleton state is not isolated between `testWidgets` calls — documented pattern: `setUp { appRouter.go('/') }`
- Disabled `FilledButton.tonal(onPressed: null)` text found only when GoRouter starts at `/` (dependency on test isolation fix above)

## Next Phase Readiness

- Theme system ready for Plan 01-06 cross-platform smoke test
- Home screen layout complete — mode tiles route to existing placeholder screens
- `/settings` route deferred to Phase 2 (SettingsScreen)
- All mode tile CTAs disabled per Phase 1 design (`onPressed: null`)

---
*Phase: 01-foundation-persistence*
*Completed: 2026-06-19*
