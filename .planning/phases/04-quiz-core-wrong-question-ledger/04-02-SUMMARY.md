---
phase: 04-quiz-core-wrong-question-ledger
plan: 02
type: execute
subsystem: quiz-controller
tags: [riverpod, async-notifier, quiz-state-machine, ledger-integration, tdd]
dependency_graph:
  requires:
    - 04-01 (quiz_session_state, review_mode, LedgerRepository, wrongQuestionsProvider)
  provides:
    - QuizSessionController AsyncNotifier
    - quizSessionControllerProvider family
  affects:
    - 04-03 (QuizScreen)
    - 04-04 (SummaryScreen)
    - 04-05 (BankPickScreen)
tech-stack:
  added:
    - dart:math (Fisher-Yates shuffle)
    - dart:async (Timer for auto-advance)
    - dart:convert (JSON canonical grading)
  patterns:
    - @riverpod AsyncNotifier (Riverpod 3.x codegen)
    - Drift typed JOIN queries (innerJoin)
    - LedgerRepository delegation (atomic transactions via D-16)
    - Freezed sealed state with abstract class
    - ProviderContainer + in-memory DB test isolation
key-files:
  created:
    - lib/features/quiz/providers/quiz_session_controller.dart (243 lines)
    - lib/features/quiz/providers/quiz_session_controller.g.dart (generated)
    - test/features/quiz/providers/quiz_session_controller_test.dart (15 tests, 15 passes)
  modified:
    - lib/features/quiz/models/quiz_session_state.dart (import fix + abstract keyword)
    - lib/features/quiz/models/quiz_session_state.freezed.dart (regenerated)
decisions:
  - Used @riverpod (autoDispose) over @Riverpod(keepAlive: true) per plan action section — controller auto-disposes when QuizScreen stops watching
  - Used abstract class for freezed classes (QuizSessionState, AnswerRecord) for Dart 3.12 compatibility
  - Timer stored in controller instance (not widget) to survive rebuilds
  - Single-choice grading via canonical JSON set comparison (Research Pattern 5)
metrics:
  duration: ~45min
  completed_date: 2026-06-20
  tasks: 2
  files: 7 (3 new, 2 modified, 2 generated)
---

# Phase 4 Plan 2: QuizSessionController Summary

**One-liner:** Implemented QuizSessionController — a @riverpod AsyncNotifier that orchestrates the entire quiz lifecycle across all three review modes (random, review, spotcheck) with atomic ledger writes, single-choice grading via canonical JSON set comparison, and 2-second auto-advance timer.

## Execution Summary

Plan 04-02 implemented the brain of the quiz system: `QuizSessionController`, an `@riverpod` AsyncNotifier that owns the question queue, current index, submitted answers, elapsed time, and auto-advance timer. All DB writes are delegated to `LedgerRepository` for atomicity (D-16). The controller serves as the state backbone for all downstream UI plans (04-03 QuizScreen, 04-04 SummaryScreen).

### Task 1: Implement QuizSessionController (TDD)

**RED phase:** Wrote 15 comprehensive tests covering all three quiz modes, grading logic, ledger mutation rules, timer lifecycle, and edge cases.

**GREEN phase:** Implemented the full controller with:
- `build(String bankId, String modeStr)` — validates mode via `reviewModeFromString()`, loads questions based on mode (random: all bank questions; review: JOIN with active WrongLedgerEntries; spotcheck: ≤10 random from active ledger), shuffles via Fisher-Yates
- `submitAnswer(String optionKey)` — decodes `correctJson` and grades single-choice via canonical set comparison; delegates to `LedgerRepository.recordWrongAnswer()` for incorrect answers in random/review modes; calls `LedgerRepository.recordCorrectReview()` for correct answers in review mode (marks mastered); records `AnswerAttempts` row for all submissions (STAT-01); spotcheck mode never mutates the ledger
- `advanceToNext()` — increments `currentIndex`, detects session completion, populates summary fields (`elapsedSeconds`, `totalQuestions`, `correctCount`, `wrongCount`, `newlyWrongCount`, `newlyMasteredCount`)
- `startAutoAdvance()` / `cancelAutoAdvance()` — 2-second Timer lifecycle; cancelled on manual advance, session complete, or navigation away
- Invalidates `wrongQuestionsProvider` after each answer so badge updates reactively

### Task 2: Codegen + Verification

- `build_runner` generated `quiz_session_controller.g.dart`
- Committed 3 missing `.g.dart` files from Plan 04-01 (`bank_pick_provider.g.dart`, `quiz_settings_provider.g.dart`, `wrong_questions_provider.g.dart`)
- `dart analyze lib/features/quiz/providers/quiz_session_controller.dart` exits 0 (no errors, no warnings)
- `flutter test test/features/quiz/providers/` passes (15/15 tests)

### Test Coverage

| # | Test | Mode | Verified Behavior |
|---|------|------|-------------------|
| 1 | build() loads all questions and shuffles | random | REV-01 |
| 2 | build() loads only active ledger questions | review | REV-03 |
| 3 | build() loads at most 10 from active ledger | spotcheck | REV-05, REV-06 |
| 4 | submitAnswer() correct → showingFeedback, correctCount=1 | random | QST-01 |
| 5 | submitAnswer() incorrect → wrongCount=1, ledger written | random | REV-02, STAT-01 |
| 6 | submitAnswer() correct → recordCorrectReview, master | review | REV-04 |
| 7 | submitAnswer() never mutates ledger | spotcheck | REV-05 |
| 8 | advanceToNext() → next index, completion detection | all | D-01 |
| 9 | Invalid mode throws ArgumentError | build | Pitfall 3 |
| 10 | Empty bank → status complete immediately | build | Edge case |
| 11 | Non-existent bank → status error | build | Edge case |
| 12 | submitAnswer() no-op when complete | all | Defensive |
| 13 | Review mode excludes mastered questions | review | REV-03 |
| 14 | Spotcheck returns min(10, activeCount) | spotcheck | REV-06 |
| 15 | startAutoAdvance + cancelAutoAdvance lifecycle | all | D-03 |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed broken import path in quiz_session_state.dart**
- **Found during:** Test compilation (Task 2)
- **Issue:** `import '../../data/db/database.dart'` resolved to `lib/features/data/db/database.dart` instead of `lib/data/db/database.dart`. The file at `lib/features/quiz/models/` needs 3 levels of `../` not 2.
- **Fix:** Changed import to `../../../data/db/database.dart`
- **Files modified:** `lib/features/quiz/models/quiz_session_state.dart`
- **Commit:** `b4f2223`

**2. [Rule 1 - Bug] Freezed classes missing abstract keyword for Dart 3.12**
- **Found during:** Test compilation (Task 2)
- **Issue:** `@freezed class QuizSessionState with _$QuizSessionState` and `@freezed class AnswerRecord with _$AnswerRecord` would not compile because the non-abstract classes used a mixin (`_$QuizSessionState`) containing abstract getters.
- **Fix:** Added `abstract` keyword to both class declarations
- **Files modified:** `lib/features/quiz/models/quiz_session_state.dart`
- **Commit:** `b4f2223`

**3. [Rule 3 - Blocking] Missing .g.dart files from Plan 04-01**
- **Found during:** Build verification
- **Issue:** `bank_pick_provider.g.dart`, `quiz_settings_provider.g.dart`, and `wrong_questions_provider.g.dart` were generated by build_runner but never committed. The controller's `import 'wrong_questions_provider.dart'` depends on its `.g.dart` part file.
- **Fix:** Committed the 3 generated files
- **Files:** `lib/features/quiz/providers/bank_pick_provider.g.dart`, `quiz_settings_provider.g.dart`, `wrong_questions_provider.g.dart`
- **Commit:** `9fb981a`

## Known Stubs

None. The controller is fully wired — all methods delegate to real `LedgerRepository` and `AppDatabase` instances. The auto-advance timer is functional. The only deferred behavior is the full timer integration test with `fake_async` (Test 9 in the plan was noted as "skip" due to the complexity of synchronizing fake time with async DB operations).

## Threat Flags

None. The `<threat_model>` from the plan was satisfied:
- T-04-06 (optionKey validation): `submitAnswer()` guards on `status != QuizStatus.active` and `isComplete`, preventing submission outside active state. Option key validation against `optionsJson` is deferred to QuizScreen (UI layer per plan 04-03).
- T-04-07 (Ledger atomicity): All writes delegate to `LedgerRepository.transaction()` methods. Controller never writes to `WrongLedgerEntries` directly.
- T-04-08 (Repudiation): Every `submitAnswer()` call records an `AnswerAttempts` row with all STAT-01 fields.
- T-04-09 (Empty questions): `build()` returns `QuizStatus.complete` immediately when questions list is empty.
- T-04-10 (Timer lifecycle): Timer cancelled in `advanceToNext()`, on session complete, and via public `cancelAutoAdvance()`.

## Verification

- [/] `dart analyze lib/features/quiz/providers/quiz_session_controller.dart` exits 0 (0 errors, 0 warnings)
- [/] `lib/features/quiz/providers/quiz_session_controller.g.dart` generated and committed
- [/] Controller test file exists with 15 tests covering all 3 modes + grading + timer
- [/] grep confirms: controller calls `ledgerRepo!.recordWrongAnswer()` and `ledgerRepo!.recordCorrectReview()` — never calls `db.into(db.wrongLedgerEntries)`
- [/] grep confirms: `_autoAdvanceTimer?.cancel()` called in `advanceToNext()` and `cancelAutoAdvance()`
- [/] All 15 tests pass with `flutter test test/features/quiz/providers/`

## Commits

| Commit | Type | Description |
|--------|------|-------------|
| `b4f2223` | feat | Implement QuizSessionController AsyncNotifier + bug fixes |
| `31dff48` | test | Add 15 tests for QuizSessionController |
| `9fb981a` | chore | Commit missing .g.dart files from 04-01 codegen |

## Self-Check

- [/] `lib/features/quiz/providers/quiz_session_controller.dart` exists
- [/] `lib/features/quiz/providers/quiz_session_controller.g.dart` exists
- [/] `test/features/quiz/providers/quiz_session_controller_test.dart` exists
- [/] `lib/features/quiz/models/quiz_session_state.dart` — import fixed
- [/] Commit `b4f2223` exists in git log
- [/] Commit `31dff48` exists in git log
- [/] Commit `9fb981a` exists in git log
- [/] All 15 tests pass with `flutter test`
- [/] `dart analyze` on controller exits 0
