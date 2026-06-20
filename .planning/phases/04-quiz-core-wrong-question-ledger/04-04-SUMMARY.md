---
phase: 04-quiz-core-wrong-question-ledger
plan: 04
type: execute
subsystem: quiz-routing
tags: [flutter, material3, riverpod, go_router, redirect-guards]
dependency_graph:
  requires:
    - 04-01 (bank_pick_provider, quiz_settings, LedgerRepository)
    - 04-02 (QuizSessionController, quizSessionControllerProvider)
  provides:
    - BankPickerScreen (bank selection with counts)
    - QuizSummaryScreen (post-quiz stats + celebration)
    - GoRouter /quiz/pick/:mode + summary + redirect guards
  affects:
    - 04-05 (HomeScreen badges wire to wrong_questions_provider)
tech-stack:
  added:
    - go_router (ProviderScope.containerOf for redirect guards)
  patterns:
    - ConsumerWidget + WidgetRef (Riverpod 3.x pattern)
    - LayoutBuilder + Center + ConstrainedBox(maxWidth:720) (layout convention)
    - GoRouter redirect guards with ref containerOf access
---

## Self-Check: PASSED

### Task 1: BankPickerScreen ✓
- [x] Full-screen ConsumerWidget with bank list from `bankPickListProvider`
- [x] Bank cards display name, question count, active wrong count
- [x] Empty/loading/error states handled
- [x] Desktop-only platform guard (`Platform.isWindows || Platform.isLinux`)
- [x] `dart analyze` exits 0

### Task 2: QuizSummaryScreen ✓
- [x] Post-quiz ConsumerWidget reading completed session state
- [x] Stats card: accuracy %, correct count, wrong count, newly wrong, newly mastered
- [x] "再来一轮" FilledButton and "返回主页" OutlinedButton
- [x] "全部掌握" celebration for review mode all-mastered
- [x] Empty/error states handled
- [x] `dart analyze` exits 0

### Task 3: GoRouter routes + redirect guards ✓
- [x] `/quiz/pick/:mode` route → BankPickerScreen
- [x] `/quiz/:bankId/:mode/summary` route → QuizSummaryScreen
- [x] Mode validation redirect guard on `/quiz/:bankId/:mode` (rejects invalid modes)
- [x] Session completeness guard on summary route (redirects incomplete sessions)
- [x] Home mode tiles updated from `/quiz/new/$mode` to `/quiz/pick/$mode`
- [x] No references to `/quiz/new/` remain in lib/
- [x] `dart analyze` exits 0 on router.dart

## Key Artifacts

| File | Lines | Status |
|------|-------|--------|
| `lib/features/quiz/presentation/bank_pick_screen.dart` | 188 | Created |
| `lib/features/quiz/presentation/quiz_summary_screen.dart` | 228 | Created |
| `lib/routing/router.dart` | ~185 | Modified |
| `lib/features/home/presentation/home_screen.dart` | ~80 | Modified |

## Commit Log

| Commit | Type | Description |
|--------|------|-------------|
| `3bc7af0` | feat | Create BankPickerScreen with bank list, counts, and empty states |
| `67b5435` | feat | Create QuizSummaryScreen with stats, actions, and all-mastered celebration |
| `3c3ae59` | feat | Add /quiz/pick/:mode, summary route, mode redirect guards, rewire home tiles |

## Issues

None.
