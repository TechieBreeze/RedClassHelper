---
phase: 04-quiz-core-wrong-question-ledger
verified: 2026-06-20T00:00:00Z
status: human_needed
score: 9/9 truths verified
re_verification: false
human_verification:
  - test: "在 Windows/Linux 上运行应用，进入乱序抽题模式，回答一题并观察反馈状态"
    expected: "选项卡正确显示绿色背景 + check_circle 图标，错误显示红色边框 + cancel 图标，未选中的正确选项显示 check_circle_outline"
    why_human: "视觉反馈状态（颜色、图标、透明度）无法通过静态代码分析验证"
  - test: "在桌面端使用键盘快捷键 A/B/C/D 选择选项、Space 提交（确认模式）、ArrowRight 翻题（手动模式）"
    expected: "按键响应正确，对应选项高亮/提交/翻题"
    why_human: "CallbacksShortcuts + Focus 键盘捕获行为依赖实际平台事件分发，无法静态验证"
  - test: "在即时提交 + 自动翻题模式下答题，观察 2 秒后是否自动跳转下一题"
    expected: "答完后 2 秒自动翻题，手动翻题时 Timer 被取消"
    why_human: "Timer 生命周期（取消时机、内存泄漏风险）需要在真实运行环境中验证"
  - test: "在非随机模式下答错一题，观察页面底部是否出现 '已加入错题本' 动画 chip"
    expected: "Chip 从底部滑入（200ms）+ 淡入，1.5 秒后自动消失"
    why_human: "动画行为（AnimationController 时间线、didUpdateWidget 触发时机）需要运行时验证"
  - test: "运行 dart analyze lib/ 确认无编译错误和警告"
    expected: "dart analyze 退出码 0，无 errors，无 warnings"
    why_human: "多个 SUMMARY 报告指出 Flutter/Dart SDK 在当前工作区环境不可用，需在具备 SDK 的环境中执行"
  - test: "运行 flutter test 确认所有测试通过"
    expected: "ledger_repository_test.dart (7 test) + quiz_session_controller_test.dart (15 test) 全部通过"
    why_human: "同上 — Flutter/Dart SDK 环境不可用"
---

# Phase 4: Quiz Core & Wrong-Question Ledger Verification Report

**Phase Goal:** Ship a runnable quiz loop with single-choice questions, all three review modes wired to a shared wrong-question ledger via an atomic state machine. Desktop-only (Windows/Linux).
**Verified:** 2026-06-20
**Status:** human_needed
**Re-verification:** No -- initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | LedgerRepository exposes markWrong, markMastered, getActiveCount, getActiveByBank, recordWrongAnswer, recordCorrectReview, watchActiveCount | VERIFIED | `lib/data/repositories/ledger_repository.dart` -- all 7 methods exist with correct signatures; all writes use `_db.transaction()` |
| 2 | wrongQuestionsProvider emits Stream<int> of active wrong count | VERIFIED | `lib/features/quiz/providers/wrong_questions_provider.dart` -- `@riverpod Stream<int> wrongQuestions(Ref ref) async*` bridges `repo.watchActiveCount()` |
| 3 | QuizSessionController.build() loads questions per mode: random (all shuffled), review (JOIN ledger WHERE masteredAt IS NULL), spotcheck (≤10 random from ledger) | VERIFIED | `lib/features/quiz/providers/quiz_session_controller.dart` lines 54-60 -- `_loadRandomQuestions`, `_loadReviewQuestions` (JOIN with `masteredAt.isNull()`), `_loadSpotcheckQuestions` (take(10)) |
| 4 | submitAnswer() grades single-choice via canonical JSON set comparison and delegates to correct LedgerRepository method per mode+correctness | VERIFIED | Controller lines 136-222 -- `_gradeSingleChoice()` compares single-element JSON arrays; `recordCorrectReview()` for review-correct, `recordWrongAnswer()` for random/review-wrong, direct `AnswerAttempts` insert for random-correct/spotcheck |
| 5 | Advance/complete flow works: advanceToNext increments index, detects completion, populates summary fields; auto-advance Timer is cancellable | VERIFIED | Controller lines 227-264 -- `advanceToNext` cancels timer, computes `elapsedSeconds`/`totalQuestions` on complete; `startAutoAdvance`/`cancelAutoAdvance` manage 2s Timer |
| 6 | QuizScreen renders completed quiz UI: question stem, option cards with feedback states, progress bar, keyboard shortcuts, wrong-question chip | VERIFIED | `lib/features/quiz/presentation/quiz_screen.dart` (446 lines, `ConsumerWidget`) -- `CallbackShortcuts` with A/B/C/D/Space/ArrowRight bindings, `computeOptionState()` for 5 post-submit visual states, `WrongQuestionChip`, `QuizProgressBar`, `KeyboardShortcutHint` |
| 7 | GoRouter has /quiz/pick/:mode, /quiz/:bankId/:mode (with mode validation guard), /quiz/:bankId/:mode/summary (with completion guard) | VERIFIED | `lib/routing/router.dart` lines 39-80 -- all 3 routes present; redirect guards validate `reviewModeFromString()` and `QuizStatus.complete` |
| 8 | BankPickerScreen shows all banks with name, question count, active wrong count; empty banks greyed out | VERIFIED | `lib/features/quiz/presentation/bank_pick_screen.dart` -- `ConsumerWidget` with `bankPickListProvider`; `_BankCard` uses `Opacity(0.4)` + disabled `onTap` for empty banks |
| 9 | HomeScreen mode tiles (review/spotcheck) show reactive wrong-count badge; SettingsScreen has quiz submit/advance toggles | VERIFIED | `lib/features/home/presentation/home_screen.dart` -- `Consumer` wraps `wrongQuestionsProvider`, `_ModeTile.badgeCount` renders `Stack+Positioned` badge; `lib/features/models/presentation/settings_screen.dart` -- `ConsumerWidget` with `quizSettingsNotifierProvider`, two `SwitchListTile` toggles |

**Score:** 9/9 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/features/quiz/models/review_mode.dart` | ReviewMode enum with 3 values + fromString factory | VERIFIED | Exists, 3 values (random/review/spotcheck), `reviewModeFromString` with switch + ArgumentError, Chinese display names |
| `lib/features/quiz/models/quiz_session_state.dart` | @freezed QuizSessionState + AnswerRecord + QuizStatus | VERIFIED | Exists, all fields per plan, `.freezed.dart` generated |
| `lib/features/quiz/models/quiz_settings.dart` | QuizSettings with submitMode/advanceMode + copyWith | VERIFIED | Exists, const constructor with defaults (instant/auto), `copyWith` method |
| `lib/data/repositories/ledger_repository.dart` | LedgerRepository with 7 methods, all writes atomic | VERIFIED | Exists (204 lines), all 7 methods, all writes in `_db.transaction()` |
| `lib/features/quiz/providers/wrong_questions_provider.dart` | Stream<int> via async* generator | VERIFIED | Exists, `.g.dart` generated, bridges Future<DB> to Stream |
| `lib/features/quiz/providers/quiz_settings_provider.dart` | SharedPreferences provider + QuizSettingsNotifier | VERIFIED | Exists, `.g.dart` generated, reads/writes 'quiz_submit_mode'/'quiz_advance_mode' keys |
| `lib/features/quiz/providers/bank_pick_provider.dart` | Future<List<BankPickItem>> with counts | VERIFIED | Exists, `.g.dart` generated, COUNT queries per bank |
| `lib/features/quiz/providers/quiz_session_controller.dart` | AsyncNotifier with build/submit/advance/timer | VERIFIED | Exists (272 lines), `.g.dart` generated, all 3 modes + timer lifecycle |
| `lib/features/quiz/presentation/widgets/option_card.dart` | OptionCard with 7 visual states | VERIFIED | Exists (180+ lines), `OptionCardState` enum (7 values), per-state background/border/icon logic |
| `lib/features/quiz/presentation/widgets/quiz_progress_bar.dart` | LinearProgressIndicator + "第 N/M 题" | VERIFIED | Exists (45 lines), determinite progress, bodyMedium text |
| `lib/features/quiz/presentation/widgets/keyboard_shortcut_hint.dart` | Desktop-gated shortcut hint | VERIFIED | Exists (40 lines), Platform.isWindows/Linux gate, correct copywriting |
| `lib/features/quiz/presentation/widgets/wrong_question_chip.dart` | Animated chip, 200ms in, 1.5s auto-dismiss | VERIFIED | Exists (110 lines), AnimationController(200ms), Timer(1500ms) |
| `lib/features/quiz/presentation/quiz_screen.dart` | Full QuizScreen replacing Phase 1 placeholder | VERIFIED | Exists (446 lines), ConsumerWidget, instanct/confirm modes, auto/manual advance, all states |
| `lib/features/quiz/presentation/bank_pick_screen.dart` | Bank selection before quiz | VERIFIED | Exists (189 lines), ConsumerWidget, loading/empty/error states |
| `lib/features/quiz/presentation/quiz_summary_screen.dart` | Post-quiz stats + actions | VERIFIED | Exists (229 lines), ConsumerWidget, accuracy/counts/time, "再来一轮"/"返回主页", all-mastered celebration |
| `lib/routing/router.dart` | /quiz/pick/:mode + summary route + redirect guards | VERIFIED | All routes present; mode validation + session completeness guards |
| `lib/features/home/presentation/home_screen.dart` | Wrong-count badges on review/spotcheck tiles | VERIFIED | Consumer wraps wrongQuestionsProvider, badgeCount passed to _ModeTile, Stack+Positioned badge |
| `lib/features/models/presentation/settings_screen.dart` | Quiz settings section with two SwitchListTile toggles | VERIFIED | ConsumerWidget, "答题设置" section, "点击即提交"/"自动翻题" toggles, desktop-gated |
| `lib/main.dart` | SharedPreferences init before runApp | VERIFIED | `SharedPreferences.getInstance()` before `runApp`, `sharedPreferencesProvider.overrideWith()` in ProviderScope |
| `pubspec.yaml` | shared_preferences dependency | VERIFIED | `shared_preferences: ^2.3.0` present |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| LedgerRepository | AppDatabase | Constructor injection | WIRED | `LedgerRepository(this._db)` |
| wrongQuestionsProvider | LedgerRepository.watchActiveCount() | async* yield* | WIRED | `yield* repo.watchActiveCount()` |
| main.dart | sharedPreferencesProvider | ProviderScope override | WIRED | `sharedPreferencesProvider.overrideWith((ref) => sharedPrefs)` |
| QuizSessionController | LedgerRepository | recordWrongAnswer/recordCorrectReview | WIRED | Calls `_ledgerRepo!.recordWrongAnswer()` and `_ledgerRepo!.recordCorrectReview()` |
| QuizSessionController | appDatabaseProvider | ref.watch future | WIRED | `await ref.watch(appDatabaseProvider.future)` |
| QuizScreen | quizSessionControllerProvider | ref.watch | WIRED | `ref.watch(quizSessionControllerProvider(bankId, mode))` |
| QuizScreen | quizSettingsNotifierProvider | ref.watch | WIRED | `ref.watch(quizSettingsNotifierProvider)` |
| BankPickerScreen | bankPickListProvider | ref.watch | WIRED | `ref.watch(bankPickListProvider)` |
| QuizSummaryScreen | quizSessionControllerProvider | ref.watch | WIRED | `ref.watch(quizSessionControllerProvider(bankId, mode))` |
| GoRouter /quiz/pick/:mode | BankPickerScreen | GoRoute builder | WIRED | `BankPickerScreen(mode: state.pathParameters['mode']!)` |
| GoRouter /quiz/:bankId/:mode/summary | QuizSummaryScreen | GoRoute builder | WIRED | `QuizSummaryScreen(bankId: ..., mode: ...)` |
| GoRouter /quiz/:bankId/:mode redirect | reviewModeFromString | mode validation | WIRED | `try { reviewModeFromString(mode); } on ArgumentError { return '/'; }` |
| HomeScreen mode tiles | /quiz/pick/:mode | context.go | WIRED | ALL 3 tiles navigate to `/quiz/pick/$mode`; no `/quiz/new/` references remain |
| HomeScreen badge | wrongQuestionsProvider | ref.watch(Consumer) | WIRED | `ref.watch(wrongQuestionsProvider)` inside Consumer wrapper |
| SettingsScreen toggles | quizSettingsNotifierProvider | ref.watch + setSubmitMode/setAdvanceMode | WIRED | `ref.watch(...)` reads; `ref.read(...notifier).setSubmitMode(...)` writes |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|-------------|-------|-------------------|--------|
| QuizScreen | session state | quizSessionControllerProvider | DB queries via drift (typed SELECT/JOIN) | FLOWING |
| BankPickerScreen | bank list | bankPickListProvider | DB COUNT queries + LedgerRepository.getActiveByBank | FLOWING |
| QuizSummaryScreen | session state | quizSessionControllerProvider | Computed from controller state (answers, correctCount, etc.) | FLOWING |
| HomeScreen badge | wrongCount | wrongQuestionsProvider | drift watchSingle() on COUNT WHERE masteredAt IS NULL | FLOWING |
| SettingsScreen toggles | settings | quizSettingsNotifierProvider | shared_preferences getString with defaults | FLOWING |
| WrongQuestionChip | show (animate in) | QuizScreen local logic | Derived from session.answers.last.isCorrect + mode check | FLOWING |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| QST-01 | 04-02 | Single-choice questions (one correct option) | SATISFIED | `_gradeSingleChoice()` compares canonical JSON set equality; `QuizScreen` renders single-choice options |
| REV-01 | 04-02, 04-04, 04-05 | 乱序抽题 (random quiz) mode | SATISFIED | `_loadRandomQuestions()` loads ALL bank questions + shuffles; HomeScreen tile routes to `/quiz/pick/random` |
| REV-02 | 04-01, 04-02 | Wrong answers auto-add to ledger | SATISFIED | `submitAnswer()` calls `recordWrongAnswer()` when !isCorrect && mode != spotcheck |
| REV-03 | 04-01, 04-02, 04-04, 04-05 | 错题复习 mode (ledger questions only) | SATISFIED | `_loadReviewQuestions()` JOIN with WrongLedgerEntries WHERE masteredAt IS NULL |
| REV-04 | 04-01, 04-02 | Correct in review marks mastered | SATISFIED | `submitAnswer()` calls `recordCorrectReview()` (inserts attempt + sets masteredAt) when isCorrect && mode == review |
| REV-05 | 04-02, 04-04, 04-05 | 错题抽查 mode (random sample, no ledger mutation) | SATISFIED | `_loadSpotcheckQuestions()` samples ≤10 from active ledger; `submitAnswer()` never calls markWrong/markMastered for spotcheck |
| REV-06 | 04-01, 04-02 | Spot-check excludes mastered | SATISFIED | Same JOIN as review mode with `masteredAt.isNull()` filter |
| STAT-01 | 04-01, 04-02 | Records answer attempts with all fields | SATISFIED | Every `submitAnswer()` path inserts into AnswerAttempts with questionId, givenAnswerJson, isCorrect, mode, elapsedMs, createdAt |
| UI-03 | 04-03, 04-05 | Quiz screen with stems, options, feedback | SATISFIED | `QuizScreen` renders question stem in Card, option cards with 5 post-submit visual states, progress bar, keyboard shortcuts |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `widgets/option_card.dart` | 56 | `_isDesktop` getter defined but never referenced in build() | INFO (minor) | Dead code -- no functional impact. The platform check is handled at screen level. |

Only 1 anti-pattern found: a dead `_isDesktop` getter in `OptionCard`. It does not affect functionality since the desktop/Android gating is correctly handled at the `QuizScreen` level (line 83: `if (!_isDesktop) return Scaffold(...)`).

### Behavioral Spot-Checks

Skipped: Flutter/Dart SDK not available in this worktree environment (confirmed by multiple SUMMARY.md reports). `dart analyze` and `flutter test` require SDK toolchain. Structural verification passes all acceptance criteria -- 20 source files, all wiring confirmed via grep/read analysis.

### Human Verification Required

1. **OptionCard visual feedback states** -- Test: Answer a question correctly and incorrectly in each mode; Expected: All 5 post-submit states (correct/wrongSelected/correctUnselected/dimmed) render with correct colors per UI-SPEC D-04 contract.

2. **Desktop keyboard shortcuts** -- Test: Press A/B/C/D keys to select options, Space to confirm (in confirm mode), ArrowRight to advance (in manual mode); Expected: Keys produce correct behavior without double-firing.

3. **Auto-advance timer** -- Test: Answer a question in instant+auto mode; Expected: 2 seconds after feedback, the next question appears. Test manual advance: pressing ArrowRight should cancel the pending auto-advance timer.

4. **Wrong-question chip animation** -- Test: Answer incorrectly in random/review mode; Expected: "已加入错题本" chip slides up with fade over ~200ms, auto-dismisses after ~1.5s with reverse fade.

5. **Badge reactivity** -- Test: Answer a wrong question, then go back to home screen; Expected: Badge count on review/spotcheck tiles updates automatically without manual refresh.

6. **dart analyze + flutter test** -- Run `dart analyze lib/` and `flutter test` in a Flutter-equipped environment; Expected: 0 errors, 0 warnings from dart analyze; all 22+ tests pass.

7. **Full quiz flow** -- Test: Home -> tap "乱序抽题" -> select bank -> answer all questions -> see summary; Expected: Complete flow works without crashes, summary shows correct statistics, "再来一轮" restarts quiz.

### Code Generator Files Check

All generated files are present and committed:
- `quiz_session_state.freezed.dart` -- PRESENT
- `wrong_questions_provider.g.dart` -- PRESENT
- `quiz_settings_provider.g.dart` -- PRESENT
- `bank_pick_provider.g.dart` -- PRESENT
- `quiz_session_controller.g.dart` -- PRESENT

(No new code generation needed -- `quiz_screen.dart` uses `StateProvider` which requires no codegen.)

---

_Verified: 2026-06-20_
_Verifier: Claude (gsd-verifier)_
