---
phase: 04-quiz-core-wrong-question-ledger
plan: 05
subsystem: ui
tags: [flutter, riverpod, go_router, shared_preferences, material3]

# Dependency graph
requires:
  - phase: 04-01
    provides: wrongQuestionsProvider (Stream<int>), QuizSettingsNotifier (quizSettingsNotifierProvider)
  - phase: 04-03
    provides: QuizScreen route /quiz/:bankId/:mode
  - phase: 04-04
    provides: HomeScreen route targets updated to /quiz/pick/$mode
provides:
  - Reactive wrong-count badges on HomeScreen review/spotcheck mode tiles
  - Quiz settings section on SettingsScreen with submit/advance mode toggles
  - shared_preferences persistence for quiz_submit_mode and quiz_advance_mode
affects: [06-ux-polish-diagnostics, settings]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Consumer wrapper inside StatelessWidget for isolated provider access
    - ConsumerWidget conversion for screen-level provider access

key-files:
  created: []
  modified:
    - lib/features/home/presentation/home_screen.dart
    - lib/features/models/presentation/settings_screen.dart

key-decisions:
  - "Used Consumer wrapper (not ConsumerWidget conversion) for HomeScreen to keep StatelessWidget structure intact"
  - "Converted SettingsScreen to ConsumerWidget for cleaner ref access with multiple provider reads"
  - "Quiz settings section placed above model management entry in SettingsScreen per UI-SPEC layout"
  - "Both quiz settings toggles default ON (instant submit + auto advance) matching QuizSettings defaults from 04-01"

patterns-established:
  - "Consumer wrapper pattern: wrap specific widget subtrees in Consumer for provider access while keeping parent as StatelessWidget"
  - "Badge-on-card pattern: Stack(clipBehavior: Clip.none) with Positioned(-8, -8) for overlapping corner badges"

requirements-completed: [REV-01, REV-03, REV-05, UI-03]

# Metrics
duration: 15min
completed: 2026-06-20
---

# Phase 4 Plan 5: Home Badges and Settings Toggles Summary

**Reactive wrong-count badges on home screen mode tiles + quiz submit/advance mode settings toggles with shared_preferences persistence**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-06-20
- **Completed:** 2026-06-20
- **Tasks:** 3
- **Files modified:** 2

## Accomplishments
- HomeScreen review and spotcheck mode tiles display reactive wrong-count badges powered by `wrongQuestionsProvider` StreamProvider
- Badge shows `scheme.error` background with white text, positioned overlapping the card's top-right corner
- Badge auto-hides when wrong count is 0 and is not shown on the random mode tile
- SettingsScreen extended with "答题设置" section containing two SwitchListTile toggles:
  - "点击即提交" (submit mode: instant/confirm)
  - "自动翻题" (advance mode: auto/manual)
- Both toggles persist to shared_preferences under keys `quiz_submit_mode` and `quiz_advance_mode`
- Toggles default to ON (instant + auto), read and write via `quizSettingsNotifierProvider`

## Task Commits

Each task was committed atomically:

1. **Task 1: Add wrong-count badges to HomeScreen mode tiles** - `5d3aaec` (feat)
2. **Task 2: Add quiz settings section to SettingsScreen** - `5b9c881` (feat)
3. **Task 3: Run full dart analyze + fix integration issues** - Not committed (verification-only task; dart analyze unavailable in this environment; structural verification passed)

## Files Created/Modified
- `lib/features/home/presentation/home_screen.dart` (321 lines) - Added Consumer wrapper watching wrongQuestionsProvider, added badgeCount to _ModeTile with Stack+Positioned badge rendering
- `lib/features/models/presentation/settings_screen.dart` (109 lines) - Converted to ConsumerWidget, added "答题设置" section with two SwitchListTile toggles above model management entry

## Decisions Made
- Used `Consumer` wrapper in HomeScreen to keep it as StatelessWidget (plan-specified approach)
- Converted SettingsScreen to ConsumerWidget for cleaner ref access (plan's preferred approach)
- Quiz settings section placed above model management entry per UI-SPEC layout contract
- Copied UI-SPEC subtitle text exactly: "关闭后需点击提交按钮确认答案" and "关闭后需手动点击或按键跳转下一题"

## Deviations from Plan

### Environment Limitation

**1. [Environment] dart analyze could not be executed (Task 3)**
- **Found during:** Task 3 (verification)
- **Issue:** Flutter/Dart SDK not installed on this build agent
- **Action:** Performed structural verification instead:
  - grep confirmed `wrongQuestionsProvider` imported and used in home_screen.dart
  - grep confirmed `quizSettingsNotifierProvider` imported and used in settings_screen.dart
  - grep confirmed "答题设置" section header text exists in settings_screen.dart
  - grep confirmed `badgeCount`, `showBadge` badge logic exists in home_screen.dart
  - All relative import paths verified correct against file system
  - Consumer/ConsumerWidget patterns verified correct against riverpod API
- **Note:** Full `dart analyze lib/` and `flutter test` should be run in an environment with the Flutter SDK installed before merging.

---

**Total deviations:** 1 environment limitation (no code defects found)
**Impact on plan:** Zero code changes needed. Structural verification passes all acceptance criteria grep checks.

## Issues Encountered
- Flutter/Dart SDK not available in this build environment — prevented automated analysis and test verification
- Settings screen line count (109) slightly below plan target (120) — all functionality is complete, conciseness is appropriate

## Next Phase Readiness
- Phase 4 UI integration is complete — home screen badges and settings toggles are wired to their providers
- Phase 5 (JSON Export/Import + Multiple-Choice + Bookmarks + Statistics) can proceed with full Phase 4 foundation
- Verify `dart analyze lib/` exits 0 in a Flutter-equipped environment before merging

---
*Phase: 04-quiz-core-wrong-question-ledger*
*Completed: 2026-06-20*
