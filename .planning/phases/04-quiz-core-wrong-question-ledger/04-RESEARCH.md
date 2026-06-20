# Phase 4: Quiz Core & Wrong-Question Ledger - Research

**Researched:** 2026-06-20
**Domain:** Flutter/Dart quiz engine with shared wrong-question ledger state machine
**Confidence:** HIGH

## Summary

Phase 4 implements the core quiz loop for single-choice questions with three review modes (random shuffle, wrong-question review, wrong-question spot-check) and a shared wrong-question ledger state machine. All components are desktop-only (Windows/Linux).

The existing codebase already provides the three database tables needed (Questions, WrongLedgerEntries, AnswerAttempts), a placeholder QuizScreen, three mode entry points on HomeScreen, and a GoRouter route for `/quiz/:bankId/:mode`. The work is primarily about building the quiz engine state machine, wiring the ledger repository, adding keyboard shortcuts, and persisting quiz settings via shared_preferences.

**Primary recommendation:** Use a single `@riverpod` `QuizSessionController` (AsyncNotifier) parameterized by `bankId` + `mode` that owns the question queue, current index, submitted answers, and elapsed time. Wrap all ledger mutations (markWrong + insert attempt) in a single drift `transaction()` call inside a dedicated `LedgerRepository` class. Use `CallbackShortcuts` for desktop keyboard bindings -- simplest pattern for a single-view quiz screen.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

| ID | Decision | Scope |
|----|----------|-------|
| D-01 | 单题逐个展示，提交后自动跳转下一题。一屏只显示一道题的题干 + 选项。 | QuizScreen layout |
| D-02 | 默认提交方式为"点击选项即提交"。设置页提供开关切换为"选中后点提交确认"（quiz_submit_mode: 'instant' \| 'confirm'，默认 'instant'）。 | Settings persistence |
| D-03 | 默认自动跳转延迟约 2 秒，期间展示对错反馈。设置页提供开关切换为"手动翻题"（quiz_advance_mode: 'auto' \| 'manual'，默认 'auto'）。 | Auto-advance timer |
| D-04 | 答对/答错反馈：展示 ✔/✘ 图标 + 高亮正确答案 + 标记用户错误选项。选项以绿色（正确）/ 红色（错误）/ 默认色（未选）区分。 | Feedback rendering |
| D-05 | 进度指示：顶部显示线性进度条 + 文字"第 3/20 题"。 | Progress UI |
| D-06 | 桌面端键盘快捷键支持：A/B/C/D 键选择选项，空格键提交，→ 键下一题。快捷键提示以半透明小字显示在选项区域下方。 | Keyboard handling |
| D-07 | 设置页（/settings）新增"答题设置" section，暴露 quiz_submit_mode 和 quiz_advance_mode 两个开关。使用 shared_preferences 持久化。 | Settings screen extension |
| D-08 | 三种模式进入答题前都需要题库选择——每次都弹出独立全屏选择页，即使只有 1 个题库也显示。 | Bank pick routing |
| D-09 | 题库选择页显示每个题库的名称、题目总数、错题数（来自 WrongLedgerEntries + Questions JOIN WHERE mastered_at IS NULL）。空题库显示"N/A"并置灰。 | Bank pick data |
| D-10 | 路由方案：主页 → `/quiz/pick/{mode}` → 题库选择页 → `/quiz/{bankId}/{mode}` → 答题页。GoRouter 新增 `/quiz/pick/:mode` 路由。 | GoRouter routes |
| D-11 | 一轮答题结束后显示统计摘要页：正确率（百分比）、总用时、答错题数、错题本新增/已掌握数。 | Summary screen |
| D-12 | 摘要页提供两个行动按钮："再来一轮"（同题库 + 同模式重新开始）和"返回主页"。 | Summary actions |
| D-13 | 错题复习中所有错题已掌握时，摘要页显示"全部掌握"提示，错题本为空。 | All-mastered state |
| D-14 | 主页的"错题复习"和"错题抽查"卡片右上角显示错题数 badge（全局，WHERE mastered_at IS NULL）。错题数为 0 时隐藏 badge。 | HomeScreen badge |
| D-15 | 答题中答错时，反馈区域显示"已加入错题本"chip 标签（短暂出现，约 1.5 秒），给予实时反馈。 | Feedback chip |
| D-16 | 所有账本状态变更（markWrong / markMastered）通过单一 `LedgerRepository` 方法完成，每次变更包裹在 SQLite 事务中。 | LedgerRepository |
| D-17 | markWrong: INSERT OR REPLACE into WrongLedgerEntries, timesWrong+1, lastWrongAt=now。markMastered: UPDATE masteredAt=now。getActiveCount(): SELECT COUNT WHERE masteredAt IS NULL。getActiveByBank(bankId): JOIN Questions WHERE masteredAt IS NULL AND bankId=?。 | Ledger queries |
| D-18 | 三种模式进入答题前都需要题库选择——每次都弹出独立全屏选择页，即使只有 1 个题库也显示。（Duplicate of D-08） | Bank pick |

### Claude's Discretion

- 答题页（QuizScreen）具体布局——选项卡片排列（竖排 vs 横排）、间距、反馈动画
- 键盘快捷键提示的 UI 样式（半透明 overlay vs tooltip vs 底部固定条）
- 统计摘要页的视觉设计（布局、图表、颜色）
- 题库选择页的列表样式（沿用已有 Card+InkWell 模式）
- 进度条的具体颜色和动画
- 设置页两个开关的 UI 位置和样式
- 答题设置的 shared_preferences key 命名

### Deferred Ideas (OUT OF SCOPE)

- 多选题渲染与判分 -- Phase 5
- 答题统计页完整实现 -- Phase 5（Phase 4 只有摘要，不做持久化统计页）
- 收藏功能 -- Phase 5
- JSON 导出/导入 -- Phase 5
- 暗色/浅色主题切换 -- Phase 6
- 答题页动画打磨 -- Phase 6
- session state 恢复（杀应用重开回到题目） -- Phase 6

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| QST-01 | App supports single-choice questions (one correct option) | Single-option selection + canonical-set comparison grading [VERIFIED: codebase Questions table has correctJson TEXT column] |
| REV-01 | Random quiz mode: questions randomly drawn from bank, graded immediately | Fisher-Yates shuffle via `dart:math` + instant grading in submitAnswer [VERIFIED: CONTEXT.md D-01/D-02] |
| REV-02 | Wrong answers in random quiz auto-added to wrong-question ledger | markWrong() called within same transaction as attempt insert [VERIFIED: CONTEXT.md D-16/D-17] |
| REV-03 | Wrong-question review mode: only ledger questions presented | Query Questions JOIN WrongLedgerEntries WHERE mastered_at IS NULL [VERIFIED: CONTEXT.md D-17] |
| REV-04 | Correct answer in review mode marks as mastered, removes from ledger | markMastered(questionId) sets masteredAt=now [VERIFIED: CONTEXT.md D-17] |
| REV-05 | Spot-check mode: small random sample from wrong-question ledger | Sample N from active ledger entries, shuffle, present [VERIFIED: CONTEXT.md D-17] |
| REV-06 | Spot-check never draws mastered questions | filter WHERE mastered_at IS NULL on draw [VERIFIED: CONTEXT.md D-17] |
| STAT-01 | Records each answer attempt (question id, correct/incorrect, elapsed, mode, timestamp) | Insert into AnswerAttempts table with all fields populated [VERIFIED: codebase AnswerAttempts table schema] |
| UI-03 | Quiz screen presents clear stems, tappable options, immediate feedback, correct/incorrect display | Single-question-per-screen layout + color-coded option feedback [VERIFIED: CONTEXT.md D-01/D-04] |

</phase_requirements>

## Standard Stack

### Core (Already in Project)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Flutter | 3.44.2+ | UI framework | Project bootstrap [VERIFIED: pubspec.yaml] |
| flutter_riverpod | ^3.3.2 | State management, DI | All screens use ConsumerWidget pattern [VERIFIED: CONVENTIONS.md] |
| riverpod_annotation | ^4.0.3 | Code generation for providers | @riverpod / @Riverpod(keepAlive: true) macros [VERIFIED: CONVENTIONS.md] |
| drift | ^2.34.0 | SQLite ORM with reactive streams | All 7 tables defined; drift_dev for codegen [VERIFIED: database.dart] |
| go_router | ^17.3.0 | Declarative navigation | Only navigation API allowed [VERIFIED: router.dart, CONVENTIONS.md] |

### New for Phase 4

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| shared_preferences | ^2.3.0 | Simple key-value persistence | Quiz settings (quiz_submit_mode, quiz_advance_mode) [ASSUMED] |
| dart:math | (stdlib) | Fisher-Yates shuffle | Randomizing question order [VERIFIED: Dart stdlib] |
| dart:async | (stdlib) | Timer for auto-advance | 2-second feedback display timer [VERIFIED: Dart stdlib] |
| dart:convert | (stdlib) | JSON encode/decode options | Storing option selections as canonical JSON sets [VERIFIED: codebase pattern] |

**Installation:**
```bash
flutter pub add shared_preferences
```

**Version verification:** `shared_preferences` is NOT currently in pubspec.yaml [VERIFIED: grep of pubspec.yaml]. The exact latest version should be confirmed via `dart pub add shared_preferences --dry-run` or `flutter pub add shared_preferences` at plan execution time. Estimated ~2.3.x range based on training data [ASSUMED].

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| shared_preferences | shared_preferences_async | Async API is cleaner for Flutter but shared_preferences 2.x is battle-tested and already used by plan for Phase 6 [ASSUMED] |

## Architecture Patterns

### Recommended Project Structure
```
lib/
├── data/
│   └── repositories/
│       └── ledger_repository.dart       # LedgerRepository - atomic DB transactions
├── features/
│   ├── quiz/
│   │   ├── models/
│   │   │   ├── review_mode.dart         # enum ReviewMode { random, review, spotcheck }
│   │   │   ├── quiz_session_state.dart  # Freezed sealed class for session state tree
│   │   │   └── quiz_settings.dart       # Settings model (submitMode, advanceMode)
│   │   ├── providers/
│   │   │   ├── quiz_session_controller.dart  # @riverpod AsyncNotifier
│   │   │   ├── wrong_questions_provider.dart # @Riverpod StreamProvider
│   │   │   ├── quiz_settings_provider.dart   # @riverpod for shared_preferences
│   │   │   └── bank_pick_provider.dart       # @riverpod for bank selection data
│   │   └── presentation/
│   │       ├── quiz_screen.dart              # Main quiz screen (replace placeholder)
│   │       ├── bank_pick_screen.dart         # Bank selection screen
│   │       ├── quiz_summary_screen.dart      # Post-round summary
│   │       └── widgets/
│   │           ├── option_card.dart          # Single option card with feedback states
│   │           ├── quiz_progress_bar.dart    # Linear progress + "第 3/20 题"
│   │           ├── feedback_overlay.dart     # Correct/incorrect feedback + "已加入错题本" chip
│   │           └── keyboard_hint_bar.dart    # A/B/C/D/space/right hint (bottom)
│   ├── home/
│   │   └── presentation/home_screen.dart     # Add wrong-count badge to mode tiles
│   └── models/
│       └── presentation/settings_screen.dart # Add "答题设置" section
```

### Pattern 1: Quiz Session State Machine (AsyncNotifier)

**What:** A single `@riverpod` AsyncNotifier that owns the entire quiz session lifecycle: loading questions, tracking current index, recording answers, managing elapsed time, and writing results to DB.

**When to use:** The quiz session spans multiple screens/operations (loading, quizzing, summarizing) and needs mutable async state. A single notifier avoids provider proliferation and keeps the session atomic.

**Example:**
[ASSUMED - Riverpod 3.x AsyncNotifier pattern based on training knowledge]
```dart
@riverpod
class QuizSessionController extends _$QuizSessionController {
  @override
  Future<QuizSessionState> build(String bankId, ReviewMode mode) async {
    final db = await ref.watch(appDatabaseProvider.future);
    final questions = await _loadQuestions(db, bankId, mode);
    questions.shuffle();
    return QuizSessionState(
      bankId: bankId,
      mode: mode,
      questions: questions,
      currentIndex: 0,
      answers: [],
      startTime: DateTime.now(),
      status: QuizStatus.ready,
    );
  }

  Future<void> submitAnswer(String selectedOption) async { /* ... */ }
  Future<void> advanceToNext() async { /* ... */ }
}
```

### Pattern 2: LedgerRepository (Atomic DB Transactions)

**What:** A dedicated class wrapping drift `.transaction()` calls for all ledger mutations, guaranteeing that a markWrong + attempt insert never partially commits.

**When to use:** Every ledger state transition (D-16). No other code writes to WrongLedgerEntries directly.

**Example:**
[ASSUMED - drift transaction API based on training knowledge]
```dart
class LedgerRepository {
  final AppDatabase _db;
  LedgerRepository(this._db);

  Future<void> markWrong(String questionId) async {
    await _db.transaction(() async {
      // INSERT OR REPLACE using drift's insertOnConflictUpdate helper
      await _db.into(_db.wrongLedgerEntries).insertOnConflictUpdate(
        WrongLedgerEntriesCompanion.insert(
          questionId: questionId,
          timesWrong: 1,
          firstWrongAt: DateTime.now(),
          lastWrongAt: DateTime.now(),
          masteredAt: Value(null),
        ),
      );
    });
  }

  Future<void> markMastered(String questionId) async {
    await _db.transaction(() async {
      await (_db.update(_db.wrongLedgerEntries)
        ..where((e) => e.questionId.equals(questionId))
      ).write(
        WrongLedgerEntriesCompanion(
          masteredAt: Value(DateTime.now()),
        ),
      );
    });
  }

  // Reactive: Returns a Stream for StreamProvider
  Stream<int> watchActiveCount() =>
    (_db.selectOnly(_db.wrongLedgerEntries)
      ..addColumns([_db.wrongLedgerEntries.id.count()])
      ..where(_db.wrongLedgerEntries.masteredAt.isNull())
    ).map((row) => row.read(_db.wrongLedgerEntries.id.count()) ?? 0)
    .watchSingle();
}
```

### Pattern 3: Keyboard Shortcuts via CallbackShortcuts

**What:** Wrap the quiz body in `CallbackShortcuts` with `SingleActivator` bindings for A/B/C/D/space/right keys, plus a `Focus` node with `autofocus: true`.

**When to use:** Desktop-only quiz screen (D-06). This is the simplest pattern for a single-view key binding.

**Example:**
[ASSUMED - Flutter CallbackShortcuts API based on training knowledge]
```dart
CallbackShortcuts(
  bindings: <ShortcutActivator, VoidCallback>{
    const SingleActivator(LogicalKeyboardKey.keyA): () => controller.selectOption('A'),
    const SingleActivator(LogicalKeyboardKey.keyB): () => controller.selectOption('B'),
    const SingleActivator(LogicalKeyboardKey.keyC): () => controller.selectOption('C'),
    const SingleActivator(LogicalKeyboardKey.keyD): () => controller.selectOption('D'),
    const SingleActivator(LogicalKeyboardKey.space): () => controller.submitCurrent(),
    const SingleActivator(LogicalKeyboardKey.arrowRight): () => controller.advanceToNext(),
  },
  child: Focus(
    autofocus: true,
    child: /* QuizScreen content */,
  ),
)
```

### Pattern 4: Timer-Based Auto-Advance

**What:** After a correct/incorrect answer in 'auto' mode, start a 2-second `Timer` that calls `advanceToNext()`. Cancel on manual advance or navigation away.

**When to use:** `quiz_advance_mode == 'auto'` (D-03). In 'manual' mode, no timer is set.

**Example:**
[ASSUMED - Dart Timer API based on training knowledge]
```dart
Timer? _autoAdvanceTimer;

void _startAutoAdvance() {
  _autoAdvanceTimer?.cancel();
  _autoAdvanceTimer = Timer(const Duration(seconds: 2), () {
    advanceToNext();
  });
}

// In dispose (or on mode change):
_autoAdvanceTimer?.cancel();
```

**Key insight:** The timer MUST be cancelled when:
1. User manually advances (→ key or tap)
2. Quiz session completes (last question)
3. User navigates away (GoRouter pop or go)
4. The widget disposes

### Pattern 5: Canonical Answer Grading (Single-Choice)

**What:** Compare the user's selected option as a canonical JSON set against the correct answer set. For single-choice, both are single-element sets `["A"]`, but the comparison pattern supports Phase 5 multiple-choice.

**When to use:** Every answer submission. Store as `["A"]` in both `correctJson` and `givenAnswerJson` columns.

**Example:**
[VERIFIED: codebase - Questions table stores correctJson as text JSON array]
```dart
bool _gradeSingleChoice(List<String> correctKeys, List<String> givenKeys) {
  // Single choice: exactly one correct, one given, must match
  if (correctKeys.isEmpty || givenKeys.isEmpty) return false;
  if (correctKeys.length != 1 || givenKeys.length != 1) return false;
  return correctKeys.first == givenKeys.first;
}
```

### Anti-Patterns to Avoid

- **Mutable state in StatelessWidget:** Do NOT use StatefulWidget for quiz state. All state lives in Riverpod providers (CONVENTIONS.md enforces `const` StatelessWidget everywhere). [VERIFIED: CONVENTIONS.md]
- **Direct Navigator.push:** Never bypass GoRouter. The router already has `/quiz/:bankId/:mode`. New routes must use GoRouter. [VERIFIED: CONVENTIONS.md]
- **Non-transactional ledger writes:** Never commit an attempt insert without also committing the ledger update. Both succeed or both roll back. [VERIFIED: CONTEXT.md D-16]
- **Timer lifecycle leaks:** A Timer created during `submitAnswer` that outlives the widget will attempt `setState` or provider mutation after disposal. Always cancel in dispose/on-navigation. [ASSUMED]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Random shuffle | Custom randomizer | `list.shuffle(Random())` from `dart:math` | Fisher-Yates is built-in, optimized, seeded if needed [ASSUMED] |
| JSON canonical comparison | Custom set comparator | `dart:convert` + Set equality | Already in codebase pattern [VERIFIED: codebase] |
| Timer/countdown | Custom event loop | `Timer` / `Timer.periodic` from `dart:async` | Cancel semantics, single-shot vs periodic built in [ASSUMED] |
| SQL transactions | Raw SQL with BEGIN/COMMIT | drift's `.transaction()` method | Auto rollback on exception, nested transaction support [ASSUMED] |
| Key-value persistence | File-based config | `shared_preferences` | Platform-native storage (Windows registry / Linux `~/.config`), battle-tested [ASSUMED] |

**Key insight:** Drift's `.transaction()` is the authoritative pattern for atomic writes. It automatically calls `ROLLBACK` if the callback throws, guaranteeing that `markWrong` + `attemptInsert` are atomic. The codebase already uses drift `into()`/`select()` patterns (never raw SQL), so ledger operations should follow the same typed-query approach.

## Common Pitfalls

### Pitfall 1: Timer Leak on Auto-Advance

**What goes wrong:** After submitting an answer with `quiz_advance_mode == 'auto'`, a 2-second Timer fires after the user has already navigated away, causing a provider mutation on a disposed context.

**Why it happens:** `Timer` is independent of the widget lifecycle. The timer callback holds a reference to the QuizSessionController, which is still alive as a Riverpod provider even though the widget tree no longer listens.

**How to avoid:**
1. Store the `Timer?` reference in the AsyncNotifier
2. In `advanceToNext()`, check `state.hasValue` and `state.value.status != QuizStatus.done` before mutating
3. Cancel the timer in the notifier's `dispose` (if the provider has autoDispose) or on manual advance
4. In the widget's `build()`, `ref.onDispose(() => timer?.cancel())` as a safety net

**Warning signs:** "Bad state: No element" errors after navigating away from quiz; timer firing on a completed session.

### Pitfall 2: Non-Atomic Wrong-Ledger + Answer-Attempt Writes

**What goes wrong:** The ledger entry (markWrong) succeeds but the answer attempt insert fails (or vice versa), leaving the DB in an inconsistent state. App crash mid-write is the classic trigger.

**Why it happens:** Writes to two tables without a transaction boundary. SQLite commits are per-statement by default.

**How to avoid:** Wrap ALL paired writes in `db.transaction(() async { ... })`. One repository method (LedgerRepository.recordWrongAnswer) does both the ledger upsert and attempt insert inside a single transaction block.

**Warning signs:** WrongLedgerEntries shows a question but no corresponding AnswerAttempts row; ledger count doesn't match attempt log.

### Pitfall 3: GoRouter Parameter Parsing for bankId + mode

**What goes wrong:** The route `/quiz/:bankId/:mode` receives `bankId` and `mode` as raw strings. If `mode` is misspelled or invalid ('rando' instead of 'random'), the AsyncNotifier builds with an invalid mode enum.

**Why it happens:** GoRouter passes path parameters as `String`. No compile-time validation.

**How to avoid:**
1. Parse mode with a factory constructor or `fromString` method: `ReviewMode.fromString(mode)`
2. Provide a redirect guard on the `/quiz/:bankId/:mode` route that validates mode is one of `['random', 'review', 'spotcheck']` and bankId exists in the DB
3. Redirect to `/` with an error snackbar on invalid parameters

**Warning signs:** App crashes on quiz route with invalid mode; empty quiz when bank doesn't exist.

### Pitfall 4: shared_preferences Async Initialization Race

**What goes wrong:** A widget reads `quiz_submit_mode` from shared_preferences before `SharedPreferences.getInstance()` has completed, defaulting to 'instant' when the user actually set 'confirm'.

**Why it happens:** `SharedPreferences.getInstance()` is async. Reading it in a synchronous provider `build()` will fail.

**How to avoid:**
1. Use a `@riverpod FutureProvider` for SharedPreferences instance
2. Or pre-initialize in `main()` before `runApp` and provide as an override (same pattern as PathResolver)
3. Quiz settings provider reads from the initialized instance

**Warning signs:** Settings reverting to defaults on app restart; `LateInitializationError` on preferences read.

### Pitfall 5: Empty Bank Edge Cases for Review/Spotcheck Modes

**What goes wrong:** User enters "错题复习" or "错题抽查" mode but the selected bank has zero wrong questions. The quiz session starts with an empty question list.

**Why it happens:** The bank pick screen shows the bank is available (has questions), but the ledger is empty for that bank (no wrong questions yet), or all wrong questions have been mastered.

**How to avoid:**
1. In the bank pick screen for review/spotcheck modes, disable banks with zero active wrong questions (D-09: show "N/A" and grey out)
2. Add a route guard: if the quiz session loads zero questions, redirect to summary with "no questions" state immediately
3. Bank pick provider already queries `count active WHERE mastered_at IS NULL AND bank_id = ?` for D-09

**Warning signs:** Quiz screen renders empty "第 0/0 题"; user stuck on loading spinner.

### Pitfall 6: Platform Gate Regression (Android)

**What goes wrong:** Phase 4 features are desktop-only but the Flutter code compiles for Android. If quiz providers lack `Platform.isWindows || Platform.isLinux` guards, they crash on Android launch.

**Why it happens:** GoRouter routes are global; if a route like `/quiz/pick/random` is accessible on Android and tries to build a QuizSessionController, it will try to access desktop-only patterns.

**How to avoid:**
1. Gate the QuizSessionController provider with a platform check (throw `UnsupportedError` on Android)
2. Or gate the route redirect: on Android, redirect `/quiz/*` routes to `/`
3. Follow existing pattern from `llmClientProvider` (providers.dart) which throws `UnsupportedError` on non-desktop

**Warning signs:** Android build crashes on quiz route navigation; `UnsupportedError` stack traces.

## Code Examples

Verified patterns from the existing codebase that Phase 4 must follow:

### Drift Typed Query (existing pattern)
```dart
// Source: lib/features/import/providers/import_notifier.dart (lines 203-231)
// [VERIFIED: codebase]
await db.into(db.parseJobs).insert(job);
await db.into(db.questionBanks).insert(bank);
await db.into(db.questions).insert(question);
```

### Riverpod ConsumerWidget + const constructor (existing pattern)
```dart
// Source: lib/features/home/presentation/home_screen.dart
// [VERIFIED: codebase - all screens follow this]
class QuizScreen extends StatelessWidget {
  const QuizScreen({super.key, required this.bankId, required this.mode});
  final String bankId;
  final String mode;
  // build() uses ref.watch(...) via ConsumerWidget or Consumer
}
```

### Platform Gate (existing pattern)
```dart
// Source: lib/data/llm_client/providers.dart (lines 32-37)
// [VERIFIED: codebase]
if (!(Platform.isWindows || Platform.isLinux)) {
  throw UnsupportedError('LLM is desktop-only; use JSON import on Android');
}
```

### Responsive Layout (existing pattern)
```dart
// Source: lib/features/home/presentation/home_screen.dart (lines 41-58)
// [VERIFIED: codebase]
LayoutBuilder(
  builder: (context, constraints) {
    final width = constraints.maxWidth;
    // 3 breakpoints: <600 / <840 / >=840, maxWidth = 720
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
        child: SingleChildScrollView(/* ... */),
      ),
    );
  },
)
```

## Runtime State Inventory

> Phase 4 is a greenfield feature implementation (no rename, refactor, or migration). The quiz feature is net-new code built on existing database tables.

**Verdict: SKIPPED** -- No runtime state to inventory. Phase 4 builds new screens and providers on top of the existing Phase 1 database schema. The Questions, WrongLedgerEntries, and AnswerAttempts tables already exist but have no user-facing behavior yet.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | All compilation, testing | ✓ (detected in PATH from flutter create output) | 3.44.2 | -- |
| Dart SDK | Analysis, formatting | ✓ (bundled with Flutter) | 3.12.2 | -- |
| shared_preferences | Quiz settings persistence | Needs install | ~2.3.x | -- |
| dart:math | Fisher-Yates shuffle | ✓ (stdlib) | -- | -- |
| dart:async | Timer for auto-advance | ✓ (stdlib) | -- | -- |
| dart:convert | JSON option handling | ✓ (stdlib) | -- | -- |
| build_runner | Code generation (providers.g.dart) | ✓ (installed) | ^2.4.13 | -- |

**Note:** Flutter and Dart tools were not directly executable from bash in this session (not in shell PATH), but the project was built with `flutter create` and has a full `.dart_tool/` directory, confirming the tools are installed on this system. Plan execution must use the correct Flutter invocation method (PowerShell / cmd / full path).

**Missing dependencies with no fallback:**
- None. `shared_preferences` is the only new dependency and must be installed.

**Missing dependencies with fallback:**
- None.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | flutter_test (bundled with Flutter SDK) |
| Config file | none -- existing tests use standard `flutter test` |
| Quick run command | `flutter test` |
| Full suite command | `flutter test --coverage` |

### Phase Requirements to Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| QST-01 | Single-choice option selection and grading | unit | `flutter test test/features/quiz/quiz_grading_test.dart` | No -- Wave 0 |
| REV-01 | Random shuffle produces valid order | unit | `flutter test test/features/quiz/quiz_shuffle_test.dart` | No -- Wave 0 |
| REV-02 | Wrong answer triggers ledger upsert + attempt insert atomically | unit | `flutter test test/data/repositories/ledger_repository_test.dart` | No -- Wave 0 |
| REV-03 | Review mode loads only active ledger questions | unit | `flutter test test/features/quiz/review_mode_test.dart` | No -- Wave 0 |
| REV-04 | Correct answer in review mode calls markMastered | unit | `flutter test test/data/repositories/ledger_repository_test.dart` | No -- Wave 0 |
| REV-05 | Spot-check samples N from ledger, excludes mastered | unit | `flutter test test/features/quiz/spotcheck_mode_test.dart` | No -- Wave 0 |
| REV-06 | Spot-check query filters mastered_at IS NULL | unit | `flutter test test/features/quiz/spotcheck_mode_test.dart` | No -- Wave 0 |
| STAT-01 | Answer attempt written with all fields populated | unit | `flutter test test/features/quiz/answer_logging_test.dart` | No -- Wave 0 |
| UI-03 | QuizScreen renders stem, options, feedback | widget | `flutter test test/features/quiz/presentation/quiz_screen_test.dart` | No -- Wave 0 |
| D-02 | submit_mode switch works in settings | widget | `flutter test test/features/models/presentation/settings_screen_test.dart` | Partially (existing settings test, needs extension) |
| D-03 | auto/manual advance mode works | widget | `flutter test test/features/quiz/presentation/quiz_advance_test.dart` | No -- Wave 0 |

### Sampling Rate
- **Per task commit:** `flutter test test/features/quiz/ --reporter compact`
- **Per wave merge:** `flutter test --coverage`
- **Phase gate:** Full suite green (`flutter test`) before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/features/quiz/` directory -- does not exist yet; all quiz tests are new
- [ ] `test/data/repositories/` directory -- does not exist yet; ledger repository tests are new
- [ ] `test/features/models/presentation/settings_screen_test.dart` -- extensible (existing), needs "答题设置" test cases added
- [ ] `shared_preferences` mock/fake -- needs test setup (shared_preferences provides `SharedPreferences.setMockInitialValues({})` for testing)

## Security Domain

> `security_enforcement` is enabled (default). Phase 4 handles user data (quiz answers, wrong-question ledger) stored locally.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | No | No auth in scope -- local desktop app |
| V3 Session Management | No | Local state, no sessions |
| V4 Access Control | No | Single-user desktop app |
| V5 Input Validation | Yes | Option key validation (A/B/C/D only), route parameter validation (mode enum, bankId UUID format) |
| V6 Cryptography | No | No cryptographic operations in quiz phase |
| V7 Error Handling | Yes | Graceful handling of empty banks, invalid routes, DB errors without crash; user-facing error messages |

### Known Threat Patterns for Flutter Desktop + SQLite

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| SQL injection via raw queries | Tampering | Drift typed queries (not raw SQL) -- already the project standard [VERIFIED: codebase] |
| JSON injection in options data | Tampering | Parse with `jsonDecode()`, validate expected structure, use typed Option class [ASSUMED] |
| Path traversal via bank import | Tampering | Not applicable in Phase 4 (quiz only; imports are Phase 2/5) |
| Debug logging sensitivity | Information Disclosure | Use `debugPrint` (not `print`), avoid logging full answer data in release [VERIFIED: CONVENTIONS.md] |
| Corrupt DB state from app kill | Tampering | Drift transactions for atomic writes; WAL mode already enabled [VERIFIED: database.dart] |

## Sources

### Primary (HIGH confidence)
- `.planning/phases/04-quiz-core-wrong-question-ledger/04-CONTEXT.md` -- All 17 implementation decisions, phase boundary, deferred items
- `lib/data/db/tables/questions.dart` -- Questions table schema (type, stem, optionsJson, correctJson)
- `lib/data/db/tables/wrong_ledger_entries.dart` -- WrongLedgerEntries table schema (UNIQUE question_id, timesWrong, masteredAt nullable)
- `lib/data/db/tables/answer_attempts.dart` -- AnswerAttempts table schema (questionId, givenAnswerJson, isCorrect, mode, elapsedMs, createdAt)
- `lib/data/db/database.dart` -- AppDatabase with all 7 tables + WAL pragma + migration strategy
- `lib/features/quiz/presentation/quiz_screen.dart` -- Existing placeholder QuizScreen (bankId + mode params)
- `lib/routing/router.dart` -- GoRouter config with `/quiz/:bankId/:mode` route already registered
- `lib/features/home/presentation/home_screen.dart` -- HomeScreen with 3 _ModeTile entries pointing to `/quiz/new/{mode}`, Card+InkWell pattern, LayoutBuilder responsive pattern
- `lib/features/models/presentation/settings_screen.dart` -- Existing SettingsScreen ready for quiz settings section extension
- `.planning/codebase/CONVENTIONS.md` -- Const constructors, Riverpod ConsumerWidget, Card+InkWell, LayoutBuilder patterns
- `.planning/REQUIREMENTS.md` -- QST-01, REV-01 through REV-06, STAT-01, UI-03
- `.planning/ROADMAP.md` Phase 4 section -- 8 plans, success criteria, phase boundary
- `pubspec.yaml` -- All existing dependencies (riverpod ^3.3.2, drift ^2.34.0, go_router ^17.3.0, etc.)
- `.planning/config.json` -- nyquist_validation: true, research: true

### Secondary (MEDIUM confidence)
- Flutter `CallbackShortcuts` API documentation (web search) -- keyboard shortcut binding pattern for desktop quiz [CITED: flutter-docs-prod.web.app, codewithandrea.com]
- Riverpod 3.x AsyncNotifier migration guide -- confirmed `@riverpod class X extends _$X` pattern [CITED: riverpod.dev, dev.to]
- Drift transaction API -- confirmed `db.transaction()` wraps multiple operations atomically [CITED: drift.simonbinder.eu/dart_api/transactions/]
- shared_preferences pub.dev -- API surface confirmed (getString, setString, getBool, setBool) [CITED: pub.dev/packages/shared_preferences]

### Tertiary (LOW confidence)
- shared_preferences exact latest version (~2.3.x) -- web search blocked by corporate policy; needs `flutter pub add --dry-run` verification at plan execution time
- Drift `insertOnConflictUpdate` helper exact API -- assumed based on training knowledge; verify against codebase's drift version (2.34.0)

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | shared_preferences latest version is ~2.3.x | Standard Stack | Low -- `flutter pub add` resolves latest automatically at plan execution |
| A2 | Drift transaction() API: `await db.transaction(() async { ... })` wraps all inner operations atomically | Architecture Patterns Pattern 2 | Medium -- if API differs in 2.34.0, ledger writes won't be atomic; must verify against drift 2.34.0 docs before implementing |
| A3 | Riverpod 3.x AsyncNotifier uses `ref.invalidateSelf()` to reload data after mutation | Architecture Patterns Pattern 1 | Low -- alternative is to manually update state within the notifier |
| A4 | Dart's `Timer` is sufficient for 2-second auto-advance (no need for `RestartableTimer` from async package) | Architecture Patterns Pattern 4 | Low -- Timer.timer + cancel() handles the use case; RestartableTimer is a convenience only |
| A5 | Drift's `.watchSingle()` on a `selectOnly` query returns a `Stream<int>` usable in a StreamProvider | Architecture Patterns Pattern 2 | Medium -- if drift 2.34.0 stream API changed, ledger badge won't update reactively |

## Open Questions (RESOLVED)

1. **Bank pick screen design: full-screen vs modal bottom sheet?**
   - What we know: D-08 says "每次都弹出独立全屏选择页" -- full screen
   - Recommendation: Use a GoRouter route (`/quiz/pick/:mode`) rendering a full Scaffold, consistent with D-08's "全屏选择页" wording

2. **QuizSessionController auto-dispose timing?**
   - What we know: The controller needs to stay alive for the duration of the quiz session, including across navigation to the summary screen
   - What's unclear: GoRouter `go()` to summary screen may dispose the provider if no widget is watching it during transition
   - Recommendation: Use `@Riverpod(keepAlive: true)` for QuizSessionController, explicitly disposed when user clicks "返回主页"

3. **shared_preferences init timing relative to quiz screen load?**
   - What we know: SharedPreferences.getInstance() is async and must complete before quiz settings are read
   - Recommendation: Initialize in main() before runApp, override provider (same pattern as PathResolver in Phase 1). Simpler alternative: use a @riverpod FutureProvider<SharedPreferences>

4. **HomeScreen badging update mechanism?**
   - What we know: D-14 requires wrong-count badge on mode tiles, updated when ledger changes
   - What's unclear: Whether to use StreamProvider (reactive) or periodic poll
   - Recommendation: Use StreamProvider watching `db.wrongLedgerEntries` with `WHERE mastered_at IS NULL`, which drift auto-updates on any table change

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all core libs verified in pubspec.yaml; only shared_preferences is new (trivial add)
- Architecture: HIGH -- AsyncNotifier + LedgerRepository + shared_preferences follows existing project patterns; drift transactions are well-documented
- Pitfalls: MEDIUM -- timer lifecycle, platform gating, and empty-state handling are common Flutter gotchas well-documented online; drift transaction API specifics need verification against exact version

**Research date:** 2026-06-20
**Valid until:** 2026-07-20 (stable domain -- Flutter/drift/Riverpod APIs are mature; no breaking changes expected)
