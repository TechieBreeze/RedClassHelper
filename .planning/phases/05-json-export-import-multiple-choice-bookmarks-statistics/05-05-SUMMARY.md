---
phase: 05-json-export-import-multiple-choice-bookmarks-statistics
plan: 05
subsystem: stats
tags: [stats, provider, drift, aggregation, screen, ui, tdd]
requires: [appDatabaseProvider, LedgerRepository]
provides: [bankStatsListProvider, StatsScreen]
affects: [/stats route]
tech-stack:
  added: []
  patterns:
    - "drift selectOnly() COUNT aggregation for question counting"
    - "drift select().join() pattern (same as getActiveByBank) for attempt counting"
    - "Riverpod @riverpod AutoDisposeFutureProvider (no keepAlive)"
    - "ConsumerWidget with AsyncValue.when for 4-state screen"
    - "StatefulWidget for ephemeral expand/collapse toggle (CONVENTIONS.md exception)"
    - "LayoutBuilder + ConstrainedBox(720) responsive (same as HomeScreen)"
    - "AnimatedRotation for chevron toggle animation"
    - "FontWeight.w700 only for stat summary emphasis values"
key-files:
  created:
    - lib/features/stats/providers/stats_provider.dart
    - lib/features/stats/providers/stats_provider.g.dart
    - test/features/stats/stats_provider_test.dart
    - test/features/stats/stats_screen_test.dart
  modified:
    - lib/features/stats/presentation/stats_screen.dart
key-decisions:
  - "Select().join() pattern used for attempt counting instead of selectOnly + join (selectOnly.join() cascade chain incompatible with drift 2.34.0)"
  - "withOpacity() replaced with withValues() per Flutter 3.x deprecation"
  - "No keepAlive on bankStatsListProvider — recomputes on each visit for freshness after quiz answers"
  - "StatefulWidget used for _StatsBankCard expanded state — CONVENTIONS.md exception for ephemeral toggle UI"
metrics:
  duration: 10min
  completed_date: "2026-06-20"
---

# Phase 5 Plan 5: Statistics Data Layer + StatsScreen Summary

**One-liner:** Implemented drift aggregation stats provider with per-bank/per-mode breakdown and full StatsScreen replacing the TODO placeholder — 14 tests pass, dart analyze clean.

## Tasks Executed

| # | Task | Type | Status | Commit |
|---|------|------|--------|--------|
| 1 | Create stats provider with drift aggregation queries (TDD) | auto (tdd) | Complete | RED: `1cb1ba2`, GREEN: `8f3adde` |
| 2 | Implement StatsScreen (full replacement of placeholder) | auto | Complete | `7184e32` |

## Task 1: Stats Provider (TDD)

**RED phase** (`1cb1ba2`): Wrote 9 unit tests for `bankStatsListProvider` and `BankStats`/`ModeBreakdown` data classes. Stub provider returned `[]`. All 5 aggregation tests failed.

**GREEN phase** (`8f3adde`): Implemented full provider with:
- `ModeBreakdown` — immutable data class with `correctRate`, `displayName` (Chinese labels per UI-SPEC)
- `BankStats` — immutable data class with `correctRate`, `correctRateDisplay` (division-by-zero guard → '暂无')
- `bankStatsListProvider` — Riverpod `@riverpod` provider (no keepAlive)
  - `selectOnly()` + `COUNT()` for question counting per bank
  - `select().join()` pattern for attempt counting (JOIN questions + answer_attempts)
  - Per-mode breakdown (random/review/spotcheck) with attempt count and correct count
  - Active ledger count via `LedgerRepository.getActiveByBank()`
- 9/9 tests pass

**Drift API deviation (Rule 3):** The plan's pseudocode used `selectOnly().join()` with cascade `..` chaining, but `selectOnly().join()` returns `JoinedSelectOnlyStatement` while cascade `..` keeps the `SelectOnlyStatement` reference. Switched to `select().join()` + `..where()` pattern (same as existing `getActiveByBank()`) which is verified working in drift 2.34.0.

## Task 2: StatsScreen Implementation

Replaced the 15-line TODO placeholder with a full `ConsumerWidget` implementation:

- **4 states** via `AsyncValue.when`:
  - Loading: `CircularProgressIndicator` + "加载统计..."
  - Empty: `Icons.insights_outlined` + "暂无统计数据" + helper text
  - Error: `Icons.error_outline` + "加载失败" + "请返回重试" + OutlinedButton "重试"
  - Data: Expandable bank card list with `LayoutBuilder` + `ConstrainedBox(720)`
- **`_StatsBankCard`** — StatefulWidget with `_expanded` toggle, `AnimatedRotation` chevron
- **`_StatChip`** — stat summary with `FontWeight.w700` for values, primary/error color
- **`_PerModeRow`** — mode label (Chinese) + "N次 · X%" display
- Copy matches UI-SPEC §3 contract exactly
- No charts or graphs (D-11 enforced)
- 5 widget tests pass covering all states

**Deprecation fix (Rule 1):** Replaced 3x `withOpacity()` calls with `withValues(alpha:)` per Flutter 3.x — dart analyze now clean.

## Verification

```bash
flutter test test/features/stats/   # 14/14 pass (9 provider + 5 screen)
dart analyze lib/features/stats/    # No issues found
```

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Drift selectOnly().join() cascade chain incompatible**
- **Found during:** Task 1 (GREEN phase)
- **Issue:** Plan pseudocode used `db.selectOnly(table)..addColumns([...])..join([...])..where(...)` but `selectOnly().join()` returns `JoinedSelectOnlyStatement` while cascade `..` continues on the original `SelectOnlyStatement`. The `where()` on `SelectOnlyStatement` cannot reference joined table columns.
- **Fix:** Switched to `db.select(table).join([...])..where(...)` pattern (same as existing `getActiveByBank()` in `ledger_repository.dart`). This loads rows via `.get()` and counts via `.length` rather than `selectOnly` COUNT aggregation. For the small data volumes of a desktop quiz app, the performance difference is negligible.
- **Files modified:** `lib/features/stats/providers/stats_provider.dart`

**2. [Rule 1 - Bug] Flutter 3.x withOpacity() deprecation**
- **Found during:** Task 2 (post-implementation analyze)
- **Issue:** Three `colorScheme.onSurface.withOpacity()` calls triggered `deprecated_member_use` warnings.
- **Fix:** Replaced `withOpacity(0.6)` → `withValues(alpha: 0.6)` and `withOpacity(0.4)` → `withValues(alpha: 0.4)`.
- **Files modified:** `lib/features/stats/presentation/stats_screen.dart`

**3. [Rule 1 - Bug] Test assertion ambiguous textContaining match**
- **Found during:** Task 2 (widget test execution)
- **Issue:** `find.textContaining('5次')` matched both "15次" and "5次".
- **Fix:** Changed to exact text matches: `'15次 · 80%'` and `'5次 · 60%'`.
- **Files modified:** `test/features/stats/stats_screen_test.dart`

**4. [Rule 1 - Bug] Non-const DateTime in const BankStats construction**
- **Found during:** Task 1 (RED phase compilation)
- **Issue:** `const BankStats(...)` with `DateTime(2026)` failed because `QuestionBank` (drift-generated) doesn't have a `const` constructor.
- **Fix:** Removed `const` from the `BankStats` declaration in Test 6, using `final` instead.
- **Files modified:** `test/features/stats/stats_provider_test.dart`

## Auth Gates

None — all features are local-only (SQLite reads), no authentication required.

## Known Stubs

None — all data flows are wired end-to-end. The provider queries real data from DB, the screen renders real provider output.

## Threat Flags

None — no new endpoints, auth paths, file access, or schema changes. All data reads are from local SQLite via existing infrastructure. The plan's threat model (T-05-12, T-05-13) covers the relevant surface.

## Self-Check: PASSED

- All 6 files exist on disk
- All 3 commits (`1cb1ba2`, `8f3adde`, `7184e32`) found in git history
- `flutter test test/features/stats/` — 14/14 pass
- `dart analyze lib/features/stats/` — No issues found
