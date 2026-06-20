---
phase: 05-json-export-import-multiple-choice-bookmarks-statistics
plan: 01
subsystem: export
tags: [flutter, dart, tdd, json, drift, format-conversion]

# Dependency graph
requires:
  - phase: 01-foundation-persistence
    provides: Question, QuestionBank data classes, AppDatabase
  - phase: 04-quiz-core-wrong-question-ledger
    provides: Question entities persisted in DB
provides:
  - bankToUserJson: DB entities → user JSON format (D-01)
  - userJsonToEntities: user JSON → QuestionsCompanion list (D-01)
affects: [05-02-export-dialog, 05-03-json-import-fast-track]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Top-level functions (no class wrapper) for pure data transforms
    - Record return type for multi-value returns (Dart 3+)
    - FormatException for input validation failures at trust boundary

key-files:
  created:
    - lib/features/export/services/json_export_service.dart
    - test/features/export/json_export_service_test.dart
  modified: []

key-decisions:
  - "Used top-level functions (not a class) for pure bidirectional data transforms — no state, no DI needed"
  - "Used Dart 3 record return type for userJsonToEntities to return (bankName, companions) tuple"
  - "Validated key charset with regex ^[A-H]+$ at parse boundary per threat model T-05-01"
  - "Used const Uuid().v4() for generated IDs in import path — matches existing codebase convention"

patterns-established:
  - "TDD RED-GREEN for data transform functions: 13 test cases drive implementation, round-trip test validates integrity"
  - "Helper factory functions in test files (_testBank, _singleChoiceQuestion, _multiChoiceQuestion) for constructing drift data classes without DB"
  - "In-memory AppDatabase for round-trip integration test (test 9)"

requirements-completed: [IMP-06]

# Metrics
duration: 8min
completed: 2026-06-20
---

# Phase 5 Plan 1: JSON Export Service Summary

**Bidirectional JSON format conversion layer between drift DB schema and user JSON format with 13 passing unit tests**

## Performance

- **Duration:** ~8 min
- **Started:** 2026-06-20
- **Completed:** 2026-06-20
- **Tasks:** 1 (TDD: RED + GREEN commits)
- **Files created:** 2

## Accomplishments
- `bankToUserJson(QuestionBank, List<Question>)` converts DB entities to the user's established JSON format (D-01):
  - Numbered object keys (1-based, not zero-based)
  - `answer` option map (`{"A":"text1","B":"text2"}`)
  - `key` concatenated string (`"B"` or `"AC"`)
  - `answer_type` 0 for single-choice, 1 for multi-choice
  - No timestamps, UUIDs, rawText, or source leaked in output (D-02)
- `userJsonToEntities(Map, String)` converts user JSON back to `QuestionsCompanion.insert()` instances:
  - Validates numeric question keys (non-numeric → FormatException)
  - Validates key charset `^[A-H]+$` (outside A-H → FormatException)
  - Validates answer_type is 0 or 1 (invalid → FormatException)
  - Validates required top-level fields (missing → FormatException)
  - Sorts keys numerically (prevents Pitfall 2: lexicographic ordering)
- Round-trip test: export bank → import back → same stems, keys, option texts preserved
- `dart analyze lib/features/export/` exits 0 with no issues

## Task Commits

Each TDD phase committed atomically:

1. **RED: test(05-01)** - `f9b7966` — 13 test cases covering all format conversion behaviors, validation, and round-trip
2. **GREEN: feat(05-01)** - `aec3e7d` — Service implementation with `bankToUserJson` and `userJsonToEntities` functions

## Files Created
- `lib/features/export/services/json_export_service.dart` (156 lines) — Two top-level functions for bidirectional format conversion
- `test/features/export/json_export_service_test.dart` (494 lines) — 13 tests organized in `bankToUserJson` and `userJsonToEntities` groups with helper factory functions

## Test Coverage
- 13 tests, all passing
- `bankToUserJson` tests (5): single-choice, multi-choice, empty list, 5-question ordering, privacy (D-02)
- `userJsonToEntities` tests (8): valid parse, answer_type mapping, key character split, round-trip, 4 validation failure modes
- Round-trip test uses in-memory AppDatabase for realistic DB → JSON → DB flow

## Deviations from Plan

None — plan executed exactly as written.

## Threat Surface Scan

| Threat ID | Status |
|-----------|--------|
| T-05-01 (Tampering - key field validation) | Mitigated: `^[A-H]+$` regex validation at `userJsonToEntities` entry; FormatException on reject |
| T-05-03 (Information Disclosure - timestamps/UUIDs) | Mitigated: D-02 grep verification in test 5 confirms no timestamps/UUIDs in output |

## Issues Encountered

- `dart analyze` flagged unused import `package:drift/drift.dart` — removed on first pass (QuestionsCompanion is accessible from database.dart via part file)

---

*Phase: 05-json-export-import-multiple-choice-bookmarks-statistics*
*Plan: 01*
*Completed: 2026-06-20*

## Self-Check: PASSED

- `lib/features/export/services/json_export_service.dart` — exists (156 lines)
- `test/features/export/json_export_service_test.dart` — exists (494 lines)
- `.planning/phases/05-.../05-01-SUMMARY.md` — exists
- Commit `f9b7966` — exists (RED: test)
- Commit `aec3e7d` — exists (GREEN: feat)
- All 13 tests pass
- `dart analyze lib/features/export/` exits 0 with no issues
