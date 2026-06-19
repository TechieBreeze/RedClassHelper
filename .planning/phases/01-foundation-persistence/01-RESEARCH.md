# Phase 1: Foundation & Persistence - Research

**Researched:** 2026-06-19
**Domain:** Flutter cross-platform desktop + mobile app skeleton (3 v1 platforms + iOS/macOS source-level), drift SQLite, go_router, Material 3 theme
**Confidence:** HIGH

## Summary

Phase 1 builds the runnable app skeleton: Flutter project for **5 source-level platforms** (Windows / Linux / Android distributable; iOS / macOS source-level compile), a 6-table drift schema, a `PathResolver` (the only `path_provider` caller), go_router with 6 placeholder routes, and a Material 3 theme via `ColorScheme.fromSeed` + `dynamic_color` with fallback. Three notable findings: (1) **`sqlite3_flutter_libs` is EOL since v0.6.0**; drift 2.32+ bundles native SQLite through `package:sqlite3` 3.x via Dart hooks — no separate dep needed. (2) `path_provider` 2.1.6's `getApplicationSupportDirectory()` is supported on all 5 v1 platforms (Android, iOS, Linux, macOS, Windows 10+), so a single getter works for all 3 distributable targets. (3) `dynamic_color` 1.8.1 does return non-null `ColorScheme?` on Windows (Accent color), macOS (App accent color), and Linux (GTK `@theme_selected_bg_color`) — but only Android S+ and Windows 11 with accent-color settings reliably return values; the **fallback seed `Color(0xFF6750A4)` path is still the safe default**.

**Primary recommendation:** Initialize project with `flutter create --platforms=windows,linux,android,ios,macos --org com.redclass .`; depend on `drift ^2.34` + `path_provider ^2.1.6` (no `sqlite3_flutter_libs`); expose `databasePath` / `modelsDir` / `cacheDir` / `diagnosticsDir` / `tempDir` via a single `PathResolver` class; configure `go_router` with 6 routes; build theme from `ColorScheme.fromSeed` wrapped in `DynamicColorBuilder` with fallback; verify with `flutter analyze` + `flutter test` + build commands on all 5 platforms.

## User Constraints

### Locked Decisions

> Copied verbatim from `01-CONTEXT.md` (D-01 through D-23). Planner MUST honor these.

#### 项目初始化粒度
- **D-01:** Flutter 包名用 `com.redclass`（与项目名一致；Windows `.exe`、Linux `.AppImage`、Android `.apk` 三端产物名统一为 `redclass`）
- **D-02:** 代码组织采用按特性分层：`lib/core/`（paths / theme / utils）、`lib/data/`（db / repositories / llm_client）、`lib/domain/`（entities / value objects）、`lib/features/`（home / bank_detail / import / quiz / stats / bookmarks / settings）
- **D-03:** 启用 Riverpod 代码生成（`@riverpod` + `riverpod_generator` + `build_runner`）——与 drift/freezed 的 codegen 工具链统一
- **D-04:** `flutter create` 命令使用 `--platforms=windows,linux,android,ios,macos`（一次性创建 5 个源码目录；v1 只分发前 3 个，iOS/macOS 仅源码编译）
- **D-05:** Linux 桌面打包目标优先 AppImage（跨发行版，单文件可运行）
- **D-06:** 启用 `build_runner watch` 模式作为开发日常（自动重生成 drift/freezed/riverpod 产物）

#### DB schema 表设计（drift v1 schema）
- **D-07:** `QuestionBank` 表字段：`id` (TEXT, PK, UUID) / `name` (TEXT) / `source` (TEXT, 文件路径或描述) / `question_count` (INTEGER) / `created_at` (DATETIME) / `updated_at` (DATETIME)。不预留 import_source_type / parse_job_id 字段——Phase 2/3 需要时再迁移
- **D-08:** `Question` 表字段：`id` (TEXT, PK, UUID) / `bank_id` (TEXT, FK→QuestionBank.id) / `type` (TEXT, 'single' | 'multiple') / `stem` (TEXT) / `options_json` (TEXT, JSON 数组 `[{key, text}]`) / `correct_json` (TEXT, JSON 数组 `["A","B"]`) / `raw_text` (TEXT, 原始文本供 LLM 重放和调试) / `created_at` (DATETIME)
- **D-09:** `WrongLedgerEntry` 表（错题本独立表）：`id` (INTEGER, PK, autoincrement) / `question_id` (TEXT, FK→Question.id, UNIQUE) / `times_wrong` (INTEGER) / `first_wrong_at` (DATETIME) / `last_wrong_at` (DATETIME) / `mastered_at` (DATETIME, nullable)。**不**在 Question 表加 bool 字段——状态机清晰
- **D-10:** `AnswerAttempt` 表字段：`id` (INTEGER, PK, autoincrement) / `question_id` (TEXT, FK) / `given_answer_json` (TEXT) / `is_correct` (BOOL) / `mode` (TEXT, 'random' | 'review' | 'spotcheck') / `elapsed_ms` (INTEGER) / `created_at` (DATETIME)。v1 不加 `session_id` / `bank_id` 冗余 / `confidence` 自评
- **D-11:** `Bookmark` 表（Phase 1 占位 + Phase 5 完整实现）：`id` (INTEGER, PK) / `question_id` (TEXT, FK, UNIQUE) / `created_at` (DATETIME)
- **D-12:** `ParseJob` 表（Phase 1 占位 + Phase 2 完整实现）：`id` (TEXT, PK) / `source_path` (TEXT) / `status` (TEXT, 'pending' | 'running' | 'succeeded' | 'failed' | 'cancelled') / `progress` (REAL, 0-1) / `result_count` (INTEGER) / `error_message` (TEXT, nullable) / `created_at` / `updated_at`
- **D-13:** `ParseLog` 表（Phase 1 占位 + Phase 6 完整实现）：`id` / `parse_job_id` / `level` ('info' | 'warn' | 'error') / `message` / `context_json` / `created_at`。LRU 200 行由 Phase 6 实现
- **D-14:** DB schema 版本号 `schemaVersion = 1`；`MigrationStrategy.onCreate` 创建所有表，`onUpgrade` 暂留空（v1 起步，未来 schema 变更再补）

#### 路径分层（PathResolver 唯一来源）
- **D-15:** `PathResolver` 是整个 app 唯一调用 `path_provider` 的类。所有 DB / 模型 / 缓存 / 诊断路径都从它取。**禁止**业务代码直接调 `path_provider`
- **D-16:** 3 层路径分层：
  - **支持目录** (`getApplicationSupportDirectory()`)：`redclass.db` SQLite 文件
  - **文档目录** (`getApplicationDocumentsDirectory()`)：`models/*.gguf` (LLM 模型)、`cache/` (导入过程缓存)、`diagnostics/` (诊断包导出)
  - **临时目录** (`getTemporaryDirectory()`)：下载中分片、解析中临时文件
- **D-17:** `getApplicationSupportDirectory()` 而非 `getApplicationDocumentsDirectory()` 放 DB：Windows 下后者可能被 OneDrive 同步污染（详见 PITFALLS §3）
- **D-18:** 模型文件 `documents/models/*.gguf`：用户可在 Windows 资源管理器手动查看/备份/删除；Android 下位于 app-private external storage，卸载 app 会清除（用户接受此取舍）
- **D-19:** PathResolver 提供 `databasePath` / `modelsDir` / `cacheDir` / `diagnosticsDir` / `tempDir` 五个 getter；测试时可通过 Riverpod override 注入 fake paths

#### Material 3 主题种子
- **D-20:** 主色调使用 Material You `dynamic_color` 包的 `CorePalette`——Android 12+ / Windows 11 自动取系统壁纸色；不支持动态色的平台 fallback 为静态种子色（`Color(0xFF6750A4)` 紫色，与 RedClass 品牌色不强绑定）
- **D-21:** 亮度模式 `ThemeMode.system`（跟随系统）——不暴露主题切换 UI（v1 Out of Scope，Phase 6 可补 toggle）
- **D-22:** 主题实现手写 `ThemeData.light()` + `ThemeData.dark()`，配合 seed color 通过 `ColorScheme.fromSeed()` 派生；**不**引入 `flex_color_scheme` 依赖（少一个依赖；与 dynamic_color 配合更直接）
- **D-23:** 主题封装为 `app/core/theme.dart` 中的 `buildAppTheme(Brightness)` 与 `buildDynamicTheme(Brightness, ColorScheme?)` 两个函数；在 `MaterialApp.router` 中根据 `dynamic_color` 取色结果切换

### Claude's Discretion
- `pubspec.yaml` 中 `environment.sdk` 与 `flutter` 字段的具体版本范围（在 `flutter create` 默认基础上微调）
- drift `DatabaseConnection` 选 `NativeDatabase` 还是 `WebAssembly`（本项目无 web 目标，确定为 Native）
- `lib/core/` 内部如何分子目录（paths / theme / utils / constants 各占一个文件即可，不深分）
- 是否在 Phase 1 引入 `intl` 包（日期格式化大概率后续需要，但 v1 主页可暂不引入）
- `go_router` 各路由的 path 命名细节（保持与 ROADMAP 中列出的 6 个路由一致即可：`/`、`/bank/:id`、`/quiz/:bankId/:mode`、`/stats`、`/bookmarks`、`/import`）

### Deferred Ideas (OUT OF SCOPE)
- GitHub Actions / CI 流水线：用户明确"小范围分享"，不需要
- 主题切换 UI（深色/浅色 toggle）：v1 Out of Scope，Phase 6 可补
- `intl` 包引入时机：Phase 5 统计页面显示日期时引入更合适
- Drift schema v2 升级路径：v1 不预留任何 v2 字段，未来需要时再做 migration

## Standard Stack

### Core (HIGH confidence — versions verified on pub.dev 2026-06-19)

| Library | Version | Purpose | Integration Note |
|---------|---------|---------|------------------|
| Flutter SDK | 3.35.7 stable (Dart 3.9.2 bundled) | UI framework, 5-platform single codebase | First-class Windows / Linux / Android targets; ~quarterly release cadence [VERIFIED: pub.dev + docs.flutter.dev/release/archive] |
| `drift` | ^2.34.0 | Type-safe SQLite ORM with reactive streams | Flutter Favorite; use `NativeDatabase.createInBackground` (not legacy `NativeDatabase`) for cross-platform [VERIFIED: pub.dev + drift.simonbinder.eu/platforms/vm] |
| `drift_dev` | ^2.34.0 (matching) | Code generator for drift | Pinned to same minor as `drift` [VERIFIED: STACK.md compatibility matrix] |
| `flutter_riverpod` | ^3.3.2 | State management + DI | Primary codegen pattern is `@riverpod` annotation [VERIFIED: pub.dev README] |
| `riverpod_annotation` | ^4.0.3 | Runtime annotation companion | Latest in 4.x line; version-locked to riverpod_generator [VERIFIED: pub.dev] |
| `riverpod_generator` | ^4.0.4 | Code generator for `@riverpod` | Generates `xxxProvider` symbols; config via `build.yaml` [VERIFIED: pub.dev README] |
| `go_router` | ^17.3.0 | Declarative routing | Feature-complete, Flutter Favorite, 6-route skeleton sufficient [VERIFIED: pub.dev] |
| `freezed` | ^3.2.5 | Immutable state classes / sealed unions | Pair with `freezed_annotation` and `build_runner` [VERIFIED: pub.dev] |
| `freezed_annotation` | ^3.2.5 (matching) | Runtime annotations | |
| `dynamic_color` | ^1.8.1 | Material You system color | Returns nullable `ColorScheme?` per platform; Android S+ / Windows 11 / macOS / Linux [VERIFIED: pub.dev README] |
| `path_provider` | ^2.1.6 | Cross-platform path helpers | `getApplicationSupportDirectory()` available on all 5 v1 platforms [VERIFIED: pub.dev] |
| `sqlite3` | ^3.3.3 (transitive via drift) | Native SQLite via Dart hooks | **Replaces** the deprecated `sqlite3_flutter_libs` for drift 2.32+ [VERIFIED: pub.dev + drift docs] |
| `build_runner` | latest (2.5.x line) | Codegen orchestrator | Watch mode: `dart run build_runner watch --delete-conflicting-outputs` [VERIFIED: STACK.md] |
| `path` | ^1.9.1 | String-based path manipulation | `p.join()` for cross-platform path composition [VERIFIED: pub.dev] |

### Explicitly NOT Included
- ❌ `sqlite3_flutter_libs` — **EOL since v0.6.0**. Drift 2.32+ bundles native SQLite through `package:sqlite3` 3.x Dart hooks; no separate plugin needed. [VERIFIED: pub.dev/packages/sqlite3_flutter_libs — "Not used anymore, update to version 3.x of package:sqlite3 instead"]
- ❌ `flex_color_scheme` — explicitly rejected per CONTEXT.md D-22 (user prefers hand-written `ThemeData` + `ColorScheme.fromSeed`)
- ❌ `file_picker` — Phase 2 dependency, NOT in Phase 1
- ❌ `pdfx` / `archive` / `xml` — Phase 2 dependencies, NOT in Phase 1
- ❌ `shared_preferences` — Phase 6 dependency, NOT in Phase 1
- ❌ `intl` — Phase 5 dependency (deferred per CONTEXT.md Claude's Discretion)

### Installation

```bash
# One-time: scaffold the project
flutter create --platforms=windows,linux,android,ios,macos --org com.redclass --project-name redclass .

# Runtime deps
flutter pub add flutter_riverpod \
  riverpod_annotation \
  go_router \
  freezed_annotation \
  drift \
  path_provider \
  dynamic_color

# Dev deps
flutter pub add --dev build_runner \
  riverpod_generator \
  freezed \
  drift_dev
```

**Important corrections to STACK.md (research found):**
- STACK.md lists `sqlite3_flutter_libs` as required — **incorrect for drift 2.32+**. Drop it. Drift auto-bundles via `package:sqlite3` Dart hooks. [VERIFIED: drift.simonbinder.eu/platforms/vm — "Starting from drift version 2.32.0, all native Dart and Flutter platforms are supported without any further setup or dependencies. Older versions required `sqlite3_flutter_libs` (or custom solutions outside of Flutter), but these are no longer necessary."]
- STACK.md mentions `pdfx` requires `flutter pub run pdfx:install_windows` post-install — irrelevant for Phase 1, defer to Phase 2.

## Architecture Patterns

### Recommended Project Structure (lib/ layout)

> **Source:** CONTEXT.md D-02 + UI-SPEC.md "Component Inventory" + STACK.md (lib/ section). Feature-first with horizontal layering — `lib/core` (cross-feature infrastructure) + `lib/data` (persistence / LLM client) + `lib/domain` (pure-Dart entities) + `lib/features` (per-screen presentation + controllers).

```
lib/
├── main.dart                          # ProviderScope + runApp
├── app.dart                           # MaterialApp.router + theme
├── routing/
│   └── router.dart                    # go_router GoRouter config (6 routes)
│
├── core/                              # 跨 feature 共享基础设施
│   ├── paths.dart                     # PathResolver (D-15 ~ D-19)
│   ├── theme.dart                     # buildAppTheme + buildDynamicTheme (D-22, D-23)
│   └── result.dart                    # (optional) sealed class Result<T, E>
│
├── data/                              # 数据层
│   └── db/
│       ├── database.dart              # @DriftDatabase + schemaVersion = 1
│       ├── database.g.dart            # GENERATED (do not edit)
│       └── tables/
│           ├── question_banks.dart    # QuestionBank table (D-07)
│           ├── questions.dart         # Question table (D-08)
│           ├── wrong_ledger.dart      # WrongLedgerEntry table (D-09)
│           ├── answer_attempts.dart   # AnswerAttempt table (D-10)
│           ├── bookmarks.dart         # Bookmark table (D-11)
│           ├── parse_jobs.dart        # ParseJob table (D-12)
│           └── parse_logs.dart        # ParseLog table (D-13)
│
├── domain/                            # 纯 Dart 实体 (no Flutter import)
│   ├── entities/                      # (Phase 2+ 填充;Phase 1 占位)
│   └── enums.dart                     # (Phase 2+ 填充)
│
├── features/                          # 按 feature 切分
│   ├── home/
│   │   └── presentation/
│   │       └── home_screen.dart       # 主页(题库空态 + 3 模式 + 统计入口)
│   ├── bank_detail/
│   │   └── presentation/
│   │       └── bank_detail_screen.dart    # Placeholder
│   ├── quiz/
│   │   └── presentation/
│   │       └── quiz_screen.dart           # Placeholder
│   ├── stats/
│   │   └── presentation/
│   │       └── stats_screen.dart          # Placeholder
│   ├── bookmarks/
│   │   └── presentation/
│   │       └── bookmarks_screen.dart      # Placeholder
│   └── import/
│       └── presentation/
│           └── import_screen.dart         # Placeholder
│
└── shared/                            # 通用 widgets (Phase 1 可选)
    └── empty_state.dart               # (Phase 1 占位)

test/                                  # 镜像 lib/ 结构
├── core/
│   └── paths_test.dart                # PathResolver 各平台路径解析单元测试
├── data/
│   └── db/
│       └── database_test.dart         # in-memory drift schema 创建 + 6 表存在性
├── routing/
│   └── router_test.dart               # 6 路由可达性 widget 测试
└── features/
    └── home/
        └── home_screen_test.dart      # home 屏幕渲染 widget 测试

integration_test/                      # (Phase 1 可选 — 不强制)
```

### Pattern 1: PathResolver as Single path_provider Caller (D-15, D-19)

**What:** A `PathResolver` class is the **only** file in the codebase that calls `package:path_provider`. All other code consumes the 5 typed getters it exposes.

**Why:**
- Single seam to swap paths in tests (Riverpod override)
- Per-platform path composition rules live in one place (e.g., Windows `%APPDATA%\Roaming\RedClass\` vs Android `/data/data/com.redclass/files/`)
- D-17 requires DB on `getApplicationSupportDirectory()` not `getApplicationDocumentsDirectory()` — one place to enforce

**Implementation shape:**

```dart
// lib/core/paths.dart
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class PathResolver {
  PathResolver(this._appSupport, this._appDocs, this._temp);

  final Directory _appSupport;
  final Directory _appDocs;
  final Directory _temp;

  /// Factory: resolves all 3 root directories from path_provider in parallel.
  static Future<PathResolver> create() async {
    final results = await Future.wait([
      getApplicationSupportDirectory(),
      getApplicationDocumentsDirectory(),
      getTemporaryDirectory(),
    ]);
    return PathResolver(results[0], results[1], results[2]);
  }

  /// SQLite db file (D-16 / D-17): 放 support directory,OneDrive 不污染
  String get databasePath => p.join(_appSupport.path, 'redclass.db');

  /// LLM 模型目录 (D-18): 放 documents,用户可手动管理
  Future<Directory> get modelsDir async =>
      Directory(p.join(_appDocs.path, 'models')).create(recursive: true);

  /// 导入过程缓存
  Future<Directory> get cacheDir async =>
      Directory(p.join(_appDocs.path, 'cache')).create(recursive: true);

  /// 诊断包导出目录
  Future<Directory> get diagnosticsDir async =>
      Directory(p.join(_appDocs.path, 'diagnostics')).create(recursive: true);

  /// 临时目录 (下载中分片、解析中临时文件)
  String get tempDir => _temp.path;
}
```

### Pattern 2: drift Schema v1 (D-07 ~ D-14, 6 tables)

**What:** `AppDatabase` class with `@DriftDatabase(tables: [...])` referencing 6 Table classes. JSON columns are `TEXT` (not SQLite JSON type — drift doesn't expose it natively).

**Why:**
- Compile-time schema safety — drift_dev catches type mismatches at build time
- Reactive streams — `Stream<List<Question>>` for ledger updates
- Migration scaffolding exists from v1 — `schemaVersion = 1` + `onCreate` creates all + `onUpgrade` no-op for v1

**Implementation shape:**

```dart
// lib/data/db/database.dart
import 'package:drift/drift.dart';
import 'tables/question_banks.dart';
import 'tables/questions.dart';
import 'tables/wrong_ledger.dart';
import 'tables/answer_attempts.dart';
import 'tables/bookmarks.dart';
import 'tables/parse_jobs.dart';
import 'tables/parse_logs.dart';

part 'database.g.dart';

@DriftDatabase(tables: [
  QuestionBanks, Questions, WrongLedgerEntries,
  AnswerAttempts, Bookmarks, ParseJobs, ParseLogs,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);
  AppDatabase.connect(this.connection);

  @override
  int get schemaVersion => 1; // D-14

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async => m.createAll(),  // D-14
    onUpgrade: (m, from, to) async {
      // v1 起步,onUpgrade 留空;Phase 2+ 需 schema 变更时再补
    },
    beforeOpen: (details) async {
      // 启用外键约束(drift 默认关闭 SQLite 外键)
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
```

```dart
// lib/data/db/tables/question_banks.dart (D-07)
import 'package:drift/drift.dart';

class QuestionBanks extends Table {
  TextColumn get id => text()();                  // UUID
  TextColumn get name => text()();
  TextColumn get source => text()();              // file path or desc
  IntColumn get questionCount => integer().named('question_count')();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
```

```dart
// lib/data/db/tables/questions.dart (D-08)
import 'package:drift/drift.dart';
import 'question_banks.dart';

class Questions extends Table {
  TextColumn get id => text()();                       // UUID
  TextColumn get bankId => text().named('bank_id')
      .references(QuestionBanks, #id, onDelete: KeyAction.cascade)();
  TextColumn get type => text()();                     // 'single' | 'multiple'
  TextColumn get stem => text()();
  TextColumn get optionsJson => text().named('options_json')();
  TextColumn get correctJson => text().named('correct_json')();
  TextColumn get rawText => text().named('raw_text')();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
```

**Similar Table classes for D-09 (WrongLedgerEntries), D-10 (AnswerAttempts), D-11 (Bookmarks), D-12 (ParseJobs), D-13 (ParseLogs).**

### Pattern 3: Riverpod Provider Patterns (@riverpod + databaseProvider + pathResolverProvider)

**What:** Three layered providers: (1) `pathResolverProvider` for filesystem, (2) `databaseProvider` for drift, (3) DAO providers (Phase 2+, not Phase 1). The codegen flow produces `xxxProvider` symbols from `@riverpod`-annotated functions. [VERIFIED: pub.dev/packages/riverpod_generator]

**Why:**
- Compile-time safe provider graph — typos caught at build time
- One `build_runner watch` covers drift + freezed + riverpod
- Provider override in tests is one-line: `ProviderScope(overrides: [pathResolverProvider.overrideWithValue(fake)])`

**Implementation shape:**

```dart
// lib/core/paths.dart (continued)
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'paths.g.dart';

@riverpod
Future<PathResolver> pathResolver(Ref ref) async {
  return PathResolver.create();
}

// lib/data/db/database.dart (continued)
@riverpod
Future<AppDatabase> appDatabase(Ref ref) async {
  final resolver = await ref.watch(pathResolverProvider.future);
  return AppDatabase(NativeDatabase.createInBackground(
    File(resolver.databasePath),
    setup: (db) {
      // WAL 模式支持并发读写(PITFALL 3 缓解)
      db.execute('pragma journal_mode = WAL;');
    },
  ));
}
```

### Pattern 4: Feature-first with Horizontal Layering (D-02 rationale)

**What:** `lib/features/<feature>/presentation/<screen>.dart` for screens; no per-feature `domain/` or `data/` subdirs in Phase 1. The architecture is "feature-first" in naming, but the **horizontal layers** (core / data / domain / features) are siblings at the lib/ root, not nested.

**Why:**
- Avoid premature DDD / hexagonal complexity for a 6-route Phase 1 app
- 7 features share the same drift schema; per-feature schemas would be premature
- `lib/domain/entities/` is reserved for the pure-Dart shared models Phase 2+ introduces (Question, ReviewMode, QuestionType enums)
- `lib/data/db/` is shared infrastructure — placing it under any single feature would be wrong

**Phase 1 reality:** most `lib/features/*/presentation/*.dart` files are 1-line `Scaffold + AppBar + Center(Text('TODO'))` placeholders. The home screen (`lib/features/home/presentation/home_screen.dart`) is the only "real" screen.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Cross-platform file paths | String concatenation with `/` or `\` | `PathResolver` + `package:path`'s `p.join()` | PITFALL 3: hardcoded separators break on Windows; `p.join()` handles platform differences [VERIFIED: pub.dev/packages/path] |
| Database connection | Raw `sqflite` calls | `drift` ORM with `@DriftDatabase` annotation | Compile-time type safety; reactive streams for ledger; cross-platform via NativeDatabase [VERIFIED: drift.simonbinder.eu] |
| Migration code | Custom SQL `IF NOT EXISTS` blocks | `MigrationStrategy` with `onCreate: (m) => m.createAll()` | drift's migrator API handles the PRAGMA user_version bookkeeping [VERIFIED: drift.simonbinder.eu/migrations] |
| Material 3 ColorScheme | Hand-pick `primary: Color(0xFF...)` for each role | `ColorScheme.fromSeed(seedColor: ..., brightness: ...)` | M3 algorithm guarantees WCAG AA contrast on all role pairs; brightness param supports dark mode [VERIFIED: api.flutter.dev] |
| Theme structure | Custom color/spacing/text widgets | `ThemeData` + `ColorScheme` + `TextTheme` | M3 components read from `Theme.of(context)`; hand-rolled theming breaks component consistency |
| Navigation | `Navigator.push(context, MaterialPageRoute(...))` | `go_router` with `GoRoute` declarations | URL-based deep links; back-stack integrity; one place to define all routes [VERIFIED: pub.dev/packages/go_router] |
| State management | `setState` / `InheritedWidget` / `Provider` (5.x) | `flutter_riverpod` 3.x + `@riverpod` codegen | AsyncValue for ledger / DB queries; AutoDispose for screen-scoped state; codegen = no ProviderContext confusion [VERIFIED: pub.dev/packages/flutter_riverpod] |
| State notifiers | `StateNotifier` (legacy) | `AsyncNotifier` with codegen | Riverpod 3.x prefers AsyncNotifier; `StateNotifier` still works but is no longer the recommended pattern |
| Native SQLite binary | Manually ship `sqlite3.dll` / `libsqlite3.so` | `drift` 2.32+ bundles via `package:sqlite3` 3.x Dart hooks | Auto-detects platform; no build config; supports Android (armv7/aarch64/x86/x64) + Windows (aarch64/x64/x86) + Linux (5 arch) + macOS (arm64/x64) + iOS [VERIFIED: pub.dev/packages/sqlite3] |
| Background DB work | `compute()` callback or `Isolate.spawn` | `NativeDatabase.createInBackground` (built into drift 2.32+) | One-line setup; drift manages the isolate lifecycle; multi-isolate read pool via `readPool:` arg [VERIFIED: drift.simonbinder.eu/platforms/vm] |

**Key insight:** Drift 2.32+ removed the most common "hand-roll" traps in cross-platform Flutter SQLite apps (manual `sqlite3_flutter_libs` setup, manual isolate spawning for DB work, manual WAL pragma). The `NativeDatabase.createInBackground(file, setup: ...)` factory does all three. **Plan's import block must NOT include `sqlite3_flutter_libs`.**

## Common Pitfalls

> Mapped to PITFALLS.md §3 (SQLite FFI) + §7 (lifecycle) + Phase 1-specific gotchas.

### Pitfall 1: SQLite FFI on Windows / Linux / Android (PITFALL 3)

**What goes wrong:**
- Windows: DB file in OneDrive-synced Documents directory → sync conflicts, file locks, corruption [VERIFIED: PITFALLS §3 + STACK.md "What NOT to Use" + CONTEXT.md D-17]
- Android 11+: scoped storage changes `file_picker` URI semantics (relevant for Phase 2, not Phase 1)
- Multi-instance desktop launches → "database is locked" without WAL

**Why it happens:** `path_provider` returns different paths per platform; the lazy developer hardcodes one path; SQLite's default journal mode (`DELETE`) doesn't support concurrent readers.

**How to avoid in Phase 1:**
1. **PathResolver uses `getApplicationSupportDirectory()` for DB** (D-17) — Windows returns `%APPDATA%\Roaming\RedClass\`, not Documents
2. **Enable WAL in drift `setup:` callback** (already in Pattern 3 example) — `pragma journal_mode = WAL;` allows concurrent reads
3. **`NativeDatabase.createInBackground`** (not `NativeDatabase`) — drift runs queries on a background isolate, keeping the UI isolate responsive [VERIFIED: drift.simonbinder.eu/platforms/vm]

**Warning signs:** "cannot open database file" on Windows first launch; "database is locked" after rapid window focus changes; DB file appears in OneDrive sync conflicts folder.

### Pitfall 2: Lifecycle — Windows has no onPause, Android kills silently (PITFALL 7)

**What goes wrong:**
- Windows: minimize window for 3 hours → return → app still alive, but any in-memory quiz state is stale
- Android: phone call interrupts → OS kills app silently → next launch starts from scratch
- Windows allows multiple windows — two instances writing to the same SQLite file

**How to avoid in Phase 1:**
1. **No in-memory ephemeral state in Phase 1** — home screen reads from `StreamProvider<QuestionBank>` directly; no "save current state" affordance needed
2. **drift's `NativeDatabase.createInBackground` runs in a background isolate** — even if UI isolate is killed, the DB connection cleans up via the OS process lifecycle
3. **Future-proofing:** Phase 6 will add `session_state` table for resume; Phase 1 reserves the architecture (no ephemeral provider state in `lib/features/home/`)

**Warning signs:** user reports "I came back to the home screen, my bank list is gone" (means state was kept in non-persistent provider); test that closing the window mid-query doesn't corrupt DB.

### Pitfall 3: drift Codegen Output Location

**What goes wrong:** Developer runs `dart run build_runner build` and gets confused about which file is generated; accidentally edits the generated file and loses changes on next build.

**How to avoid:**
1. Generated file is `lib/data/db/database.g.dart` — only `database.dart` is hand-edited
2. Add to `analysis_options.yaml`:
   ```yaml
   analyzer:
     errors:
       invalid_annotation_target: ignore  # required for freezed + json_serializable
     exclude:
       - "**/*.g.dart"
       - "**/*.freezed.dart"
   ```
3. The generated `database.g.dart` contains `_$AppDatabase` mixin that the hand-written `AppDatabase` extends via `extends _$AppDatabase`
4. `part 'database.g.dart';` directive in `database.dart` ties them together [VERIFIED: drift.simonbinder.eu/migrations example]

**Warning signs:** `Error: Class '_$AppDatabase' not found` after schema changes → means codegen wasn't re-run → re-run `dart run build_runner build --delete-conflicting-outputs`.

### Pitfall 4: Riverpod ProviderScope Placement

**What goes wrong:** Developer wraps `MaterialApp` in `ProviderScope` but providers that depend on `WidgetsFlutterBinding.ensureInitialized()` (like `pathResolverProvider`) crash on first read.

**How to avoid:**
1. `ProviderScope` must wrap the **entire** `RedClassApp` widget — pass it in `main()`'s `runApp(ProviderScope(...))`
2. `main()` runs `WidgetsFlutterBinding.ensureInitialized()` and resolves `PathResolver.create()` synchronously **before** `runApp`, then uses `ProviderScope(overrides: [pathResolverProvider.overrideWith((ref) async => preResolved)])` to inject the pre-resolved resolver
3. Pattern:
   ```dart
   void main() async {
     WidgetsFlutterBinding.ensureInitialized();
     final resolver = await PathResolver.create();
     runApp(ProviderScope(
       overrides: [pathResolverProvider.overrideWith((ref) async => resolver)],
       child: const RedClassApp(),
     ));
   }
   ```

**Warning signs:** "LateInitializationError: Field 'path' has not been initialized" on first `ref.watch(pathResolverProvider.future)`; "ProviderNotFoundException" means `ProviderScope` is missing or wraps the wrong subtree.

### Pitfall 5: go_router Must Be the Only Navigation API

**What goes wrong:** Developer mixes `go_router` with `Navigator.push` → back button breaks, deep links inconsistent, route history lost.

**How to avoid:**
1. All `Navigator.of(context).push` calls forbidden in Phase 1 code (UI-SPEC.md "Routes" section explicitly uses `context.go('/path')` and `context.push('/path')`)
2. `go_router` config in `lib/routing/router.dart` exports a single `GoRouter` instance
3. `MaterialApp.router(routerConfig: appRouter)` in `lib/app.dart` [VERIFIED: pub.dev/packages/go_router]

**Warning signs:** back button on placeholder screen exits the app (should pop within the router stack); `pop` is called from a context that wasn't pushed by the router.

### Pitfall 6: CJK Font Rendering Fallback

**What goes wrong:** `Text('红课复习')` shows as `.notdef` (empty rectangles) because Roboto (the M3 default) lacks CJK glyphs.

**How to avoid in Phase 1:** [VERIFIED: UI-SPEC.md "Typography §CJK handling" + STACK.md]
1. **No font bundle in Phase 1** — let Flutter's text engine fall back through the system font chain
2. On Android: `Noto Sans CJK` is preinstalled; on Windows: `Microsoft YaHei UI` / `SimSun` resolve automatically
3. **Test on all 3 v1 platforms manually** during the smoke test — Chinese text must render as actual glyphs, not boxes
4. If Phase 6 polish reveals issues, add `google_fonts` and pin `Noto Sans SC` weights 400/500 [from UI-SPEC.md "Inferred Defaults Q2"]

**Warning signs:** empty boxes / "tofu" characters in home screen app bar; screenshots show "□□□□□" instead of "红课复习".

### Pitfall 7: dynamic_color Returns null on Most Desktop Platforms

**What goes wrong:** Developer assumes `dynamic_color` always returns a non-null ColorScheme on Windows 11 → app crashes on first read.

**Reality:** [VERIFIED: pub.dev/packages/dynamic_color README]
- Android S+ (API 31+): pulls wallpaper color via `CorePalette` — most reliable
- Windows: pulls Accent color from Windows settings (registry-based) — only if user has set a custom accent color
- macOS: pulls App accent color from System Settings — only if explicitly set
- Linux: pulls `@theme_selected_bg_color` from GTK theme — depends on desktop environment
- **All four are nullable** — `DynamicColorBuilder` provides `ColorScheme? lightDynamic, ColorScheme? darkDynamic`

**How to avoid in Phase 1 (per UI-SPEC.md "Color §Dynamic color fallback chain"):**
1. **Always provide fallback seed** — `ColorScheme.fromSeed(seedColor: Color(0xFF6750A4), brightness: brightness)`
2. Wrap `MaterialApp.router` in `DynamicColorBuilder`:
   ```dart
   DynamicColorBuilder(
     builder: (lightDynamic, darkDynamic) {
       return MaterialApp.router(
         theme: buildAppTheme(Brightness.light, lightDynamic),
         darkTheme: buildAppTheme(Brightness.dark, darkDynamic),
         themeMode: ThemeMode.system,
         routerConfig: appRouter,
       );
     },
   )
   ```
3. In `buildAppTheme(Brightness b, ColorScheme? dynamic)`, if `dynamic != null`, use `dynamic.harmonized()`; else use `ColorScheme.fromSeed(...)` [VERIFIED: dynamic_color README + UI-SPEC.md D-22]

**Warning signs:** app shows purple on Windows 11 (means dynamic_color returned null, fallback seed used — expected, not a bug); same purple on Linux without GNOME custom theme (also expected).

### Pitfall 8: 5-Platform `flutter create` Generates iOS/macOS Source But Unsigned

**What goes wrong:** Developer runs `flutter build ios` or `flutter build macos` and gets a signing error, thinks the build failed.

**How to avoid:**
1. `flutter create --platforms=windows,linux,android,ios,macos` **only generates the source folders** — no signing required
2. `flutter build ios --no-codesign --simulator` — source-level compile only, targets the iOS Simulator
3. `flutter build macos --debug` — source-level compile, no signing
4. **Both must succeed** (per ROADMAP.md Phase 1 success criterion #2) as proof that iOS/macOS code paths exist and compile
5. Document this as "source-level support" — no distributable is produced in v1 per PROJECT.md "Out of Scope" (lacks macOS host + Apple Developer account)

**Warning signs:** "no provisioning profile" error on iOS build → add `--no-codesign`; "Code signing required" on macOS → build will succeed with `--debug` flag (debug mode skips signing).

## Code Examples

### Example 1: `flutter create` Command (5 platforms at once)

```bash
# Run from the project root (where pubspec.yaml will live)
flutter create \
  --platforms=windows,linux,android,ios,macos \
  --org com.redclass \
  --project-name redclass \
  .
```
[VERIFIED: docs.flutter.dev/reference/create-new-app — multi-platform syntax confirmed]

**Flags:**
- `--platforms=...` — comma-separated list of 5 platforms (no spaces; order doesn't matter)
- `--org com.redclass` — sets `applicationId` (Android) and `CFBundleIdentifier` (iOS/macOS) prefix
- `--project-name redclass` — package name + binary name (Windows `.exe`, Linux `.AppImage`, Android `.apk` all named `redclass`)
- `.` — current directory (assumes project root is already created)

### Example 2: PathResolver Class Skeleton (5 getters)

```dart
// lib/core/paths.dart
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'paths.g.dart';

class PathResolver {
  PathResolver(this._appSupport, this._appDocs, this._temp);
  final Directory _appSupport;
  final Directory _appDocs;
  final Directory _temp;

  static Future<PathResolver> create() async {
    final results = await Future.wait([
      getApplicationSupportDirectory(),  // D-16: SQLite
      getApplicationDocumentsDirectory(), // D-16: models / cache / diagnostics
      getTemporaryDirectory(),            // D-16: temp
    ]);
    return PathResolver(results[0], results[1], results[2]);
  }

  String get databasePath => p.join(_appSupport.path, 'redclass.db');
  Future<Directory> get modelsDir => _ensureSubdir(_appDocs, 'models');
  Future<Directory> get cacheDir => _ensureSubdir(_appDocs, 'cache');
  Future<Directory> get diagnosticsDir => _ensureSubdir(_appDocs, 'diagnostics');
  String get tempDir => _temp.path;

  static Future<Directory> _ensureSubdir(Directory parent, String name) async {
    final dir = Directory(p.join(parent.path, name));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }
}

@riverpod
Future<PathResolver> pathResolver(Ref ref) => PathResolver.create();
```

### Example 3: drift Schema Opening (6 Tables in One Database)

```dart
// lib/data/db/database.dart
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/paths.dart';
import 'tables/question_banks.dart';
import 'tables/questions.dart';
import 'tables/wrong_ledger.dart';
import 'tables/answer_attempts.dart';
import 'tables/bookmarks.dart';
import 'tables/parse_jobs.dart';
import 'tables/parse_logs.dart';

part 'database.g.dart';

@DriftDatabase(tables: [
  QuestionBanks, Questions, WrongLedgerEntries,
  AnswerAttempts, Bookmarks, ParseJobs, ParseLogs,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1; // D-14

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async => m.createAll(), // D-14
    onUpgrade: (m, from, to) async {/* v1 起步,留空 */},
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

@riverpod
Future<AppDatabase> appDatabase(Ref ref) async {
  final resolver = await ref.watch(pathResolverProvider.future);
  return AppDatabase(NativeDatabase.createInBackground(
    File(resolver.databasePath),
    setup: (db) => db.execute('pragma journal_mode = WAL;'),
  ));
}
```

### Example 4: @riverpod-Annotated Provider for PathResolver

```dart
// (in lib/core/paths.dart, shown in Example 2)
@riverpod
Future<PathResolver> pathResolver(Ref ref) => PathResolver.create();

// Usage in any ConsumerWidget:
class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolverAsync = ref.watch(pathResolverProvider);
    return resolverAsync.when(
      data: (resolver) => Text('DB at: ${resolver.databasePath}'),
      loading: () => const CircularProgressIndicator(),
      error: (e, st) => Text('Path error: $e'),
    );
  }
}
```

[VERIFIED: pub.dev/packages/flutter_riverpod README — `ref.watch(boredSuggestionProvider)` + `switch-case on AsyncValue` is the documented primary pattern for v3.x]

### Example 5: @riverpod-Annotated Provider for Database

```dart
// (in lib/data/db/database.dart, shown in Example 3)
@riverpod
Future<AppDatabase> appDatabase(Ref ref) async { ... }

// Usage in a repository (Phase 2+, not Phase 1):
final questionRepoProvider = Provider<QuestionRepository>((ref) {
  final db = ref.watch(appDatabaseProvider).requireValue;
  return QuestionRepository(db);
});
```

**Test override pattern:**
```dart
testWidgets('home screen renders empty state', (tester) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWith((ref) async => AppDatabase(NativeDatabase.memory())),
    ],
    child: const RedClassApp(),
  ));
  // ...
});
```

### Example 6: buildAppTheme Function Shape (ColorScheme.fromSeed + dynamic_color override)

```dart
// lib/core/theme.dart
import 'package:flutter/material.dart';

const Color _seedColor = Color(0xFF6750A4); // D-20 fallback

ThemeData buildAppTheme(Brightness brightness, ColorScheme? dynamicScheme) {
  final scheme = dynamicScheme?.harmonized() ??
      ColorScheme.fromSeed(seedColor: _seedColor, brightness: brightness);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: brightness,
    // M3 default typography (4 sizes / 2 weights per UI-SPEC.md §Typography)
  );
}
```

[VERIFIED: api.flutter.dev — `ColorScheme.fromSeed` accepts `brightness: Brightness.dark`; `dynamic_color` 1.8.1 README confirms `ColorScheme.harmonized()` extension exists]

### Example 7: go_router Config with 6 Routes

```dart
// lib/routing/router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/bank_detail/presentation/bank_detail_screen.dart';
import '../features/quiz/presentation/quiz_screen.dart';
import '../features/stats/presentation/stats_screen.dart';
import '../features/bookmarks/presentation/bookmarks_screen.dart';
import '../features/import/presentation/import_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
    GoRoute(
      path: '/bank/:id',
      builder: (_, s) => BankDetailScreen(bankId: s.pathParameters['id']!),
    ),
    GoRoute(
      path: '/quiz/:bankId/:mode',
      builder: (_, s) => QuizScreen(
        bankId: s.pathParameters['bankId']!,
        mode: s.pathParameters['mode']!,
      ),
    ),
    GoRoute(path: '/stats', builder: (_, __) => const StatsScreen()),
    GoRoute(path: '/bookmarks', builder: (_, __) => const BookmarksScreen()),
    GoRoute(path: '/import', builder: (_, __) => const ImportScreen()),
  ],
  errorBuilder: (_, state) => Scaffold(
    body: Center(child: Text('Route not found: ${state.uri}')),
  ),
);
```

[VERIFIED: pub.dev/packages/go_router 17.3.0 API + UI-SPEC.md "Routes" table]

### Example 8: MaterialApp.router Setup with themeMode: system

```dart
// lib/app.dart
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'routing/router.dart';

class RedClassApp extends StatelessWidget {
  const RedClassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return MaterialApp.router(
          title: '红课复习',
          theme: buildAppTheme(Brightness.light, lightDynamic),
          darkTheme: buildAppTheme(Brightness.dark, darkDynamic),
          themeMode: ThemeMode.system, // D-21
          routerConfig: appRouter,
          // 限定中文 locale,避免系统英文环境乱跳
          locale: const Locale('zh', 'CN'),
        );
      },
    );
  }
}
```

[VERIFIED: dynamic_color 1.8.1 README `DynamicColorBuilder` signature; CONTEXT.md D-21 ThemeMode.system; UI-SPEC.md §Color fallback chain]

## Environment Availability

> **Audited on 2026-06-19**: developer machine is **Windows (Git Bash)** with **no Flutter or Dart toolchain installed**. Phase 1 requires the user to install Flutter SDK before any build can succeed.

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | All build/run/test commands | ✗ | — | User must install Flutter 3.35.7+ + Android SDK + Visual Studio 2022 (for Windows desktop) before Phase 1 execution starts |
| Dart SDK | Bundled with Flutter | ✗ | — | Installs with Flutter |
| `build_runner` | Code generation | ✗ (transitive) | — | Installs via `flutter pub add --dev build_runner` once Flutter is present |
| `dart pub global activate drift_dev` | `drift_dev` codegen | ✗ | — | Use `dart run build_runner build` instead (works without global activation) |
| Android SDK | `flutter build apk` / `flutter run -d android` | ✗ | — | User must install via Android Studio or `sdkmanager` |
| Visual Studio 2022 (Windows desktop workload) | `flutter build windows` | ✗ | — | User must install VS2022 with "Desktop development with C++" + "Flutter" components |
| GTK 3 / Linux headers | `flutter build linux` | N/A (Windows host) | — | Cross-compile via Docker or run on Linux host |
| Xcode 15+ (iOS Simulator) | `flutter build ios --simulator` | ✗ | — | User lacks macOS host; iOS build is source-level only (skip or use CI) |
| Xcode 15+ + CocoaPods (macOS) | `flutter build macos` | ✗ | — | User lacks macOS host; macOS build is source-level only (skip) |

**Missing dependencies with no fallback (BLOCKING):**
- Flutter SDK itself — entire Phase 1 is blocked until installed

**Missing dependencies with fallback:**
- Android SDK — can skip Android-specific builds; still verify Windows + Linux source compiles
- iOS/macOS toolchain — skip entirely; Phase 1 success criterion #2 (`flutter build ios --no-codesign --simulator`) becomes aspirational on the dev machine; verify on CI / different host

**Recommendation:** First plan in Phase 1 should include "Install Flutter SDK" as a prerequisite task before any `flutter create` / `flutter pub get` can run. Alternatively, defer build verification to CI.

## Validation Architecture

> nyquist_validation enabled. All Phase 1 verifications must run on Windows (the dev host). Cross-platform builds requiring Linux GTK / macOS Xcode / iOS Simulator must be either skipped with explicit documentation, or verified on a CI host.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | `flutter_test` (bundled with Flutter SDK) |
| Config file | `test/` directory + `analysis_options.yaml` (lints) |
| Quick run command | `flutter test` |
| Full suite command | `flutter test --coverage` |
| Widget test pattern | `tester.pumpWidget(ProviderScope(overrides: [...], child: RedClassApp()))` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| **IMP-05** | Imported questions persisted to DB | unit (drift in-memory) | `flutter test test/data/db/database_test.dart` | ❌ Wave 0 |
| **STOR-01** | Local SQLite for all data | unit (in-memory schema) | same as above | ❌ Wave 0 |
| **STOR-02** | Ledger / bookmarks / stats tables exist | unit (table existence) | same as above | ❌ Wave 0 |
| **PLT-04** | Single codebase serves all 3 v1 platforms | smoke (manual) | `flutter run -d windows` / `-d linux` / `-d <android>` | manual only — no automated test |
| **PLT-05** | Local SQLite file accessible + stable | integration (smoke) | manual: kill app, reopen, verify DB persists | manual only |
| **UI-02** | Home screen shows bank list + 3 mode entries + stats entry | widget | `flutter test test/features/home/home_screen_test.dart` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `flutter analyze` (zero new warnings) + `flutter test` (all passing)
- **Per wave merge:** `flutter test --coverage` (full suite) + `flutter build <platform> --debug` for each target
- **Phase gate:** Full suite green + 5 build commands green (Windows, Linux, Android, iOS --no-codesign --simulator, macOS --debug) + manual smoke test on real devices per ROADMAP.md Phase 1 success criteria

### Wave 0 Gaps (test files to scaffold before implementation)
- [ ] `test/core/paths_test.dart` — PathResolver returns expected paths per platform (mock `path_provider` via Riverpod override)
- [ ] `test/data/db/database_test.dart` — in-memory `AppDatabase` opens, `m.createAll()` succeeds, all 6 tables present
- [ ] `test/routing/router_test.dart` — 6 routes navigate without errors via `tester.tap` + `tester.pumpAndSettle`
- [ ] `test/features/home/home_screen_test.dart` — home screen renders empty state, 3 mode tiles, stats entry
- [ ] `test/widgets/theme_test.dart` — `buildAppTheme(Brightness.dark, null)` returns non-null `ThemeData`; `ColorScheme.fromSeed` brightness flows through
- [ ] `analysis_options.yaml` — exclude `**/*.g.dart` and `**/*.freezed.dart` from analyzer
- [ ] `dev_dependencies` — `flutter_test` is built-in; no extra deps needed for Phase 1

### Build Verification Matrix (per ROADMAP.md Phase 1 success criteria)
| Build Command | Verifies | Available on dev host (Windows)? | Notes |
|---------------|----------|--------------------------------|-------|
| `flutter build windows --debug` | PLT-04 (Windows target) | ✗ (Flutter not installed) | After Flutter install, requires VS2022 C++ workload |
| `flutter build linux --debug` | PLT-04 (Linux target) | ✗ (cross-compile hard) | Use a Linux host or Docker |
| `flutter build apk --debug` | PLT-04 (Android target) | ✗ (Flutter not installed) | After Flutter install, requires Android SDK |
| `flutter build ios --no-codesign --simulator` | Source-level iOS compile (success criterion #2) | ✗ (no macOS host) | Run on CI or skip with note in Phase completion report |
| `flutter build macos --debug` | Source-level macOS compile (success criterion #2) | ✗ (no macOS host) | Run on CI or skip with note in Phase completion report |
| `flutter run -d windows` | Manual smoke test (success criterion #1) | ✗ (Flutter not installed) | |
| `flutter run -d <android>` | Manual smoke test (success criterion #1) | ✗ (Flutter not installed) | |

**Honest reality check:** The current dev machine has **no Flutter installed**. Phase 1 cannot execute to completion on this host as configured. Two paths:
1. **Install Flutter first** (one-time, ~30 min including Android SDK + Visual Studio C++) before any plan runs
2. **Defer build verification to CI** (GitHub Actions or similar) and use this host only for code authoring + `flutter analyze` (works after Flutter install) + `flutter test` (also requires Flutter)

## Security Domain

> `security_enforcement` enabled (default). Phase 1 has minimal security surface (no auth, no network, no user input beyond path_provider's filesystem), but the following ASVS categories apply.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | Phase 1 has no auth surface |
| V3 Session Management | no | No sessions in Phase 1; Phase 6 will add session_state table |
| V4 Access Control | no | Single-user local app; no multi-user |
| V5 Input Validation | yes | PathResolver must reject paths outside the app's allowed dirs (defense-in-depth) |
| V6 Cryptography | no | DB not encrypted in Phase 1 (PITFALLS §"Security Mistakes" notes this as v2 enhancement) |
| V8 Data Protection | no | No PII handling in Phase 1 |
| V9 Communication | no | No network in Phase 1 |
| V10 Malicious Code | yes | Only `package:sqlite3` 3.x native binding has code-execution surface; verified safe per pub.dev audit |
| V14 Configuration | yes | `path_provider` directory permissions default to app-private on Android; user-readable on Windows/macOS/Linux |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| DB file accessed by another process on Windows | Information Disclosure | DB on `getApplicationSupportDirectory()` (user-restricted); document that DB is unencrypted in v1 |
| Path traversal in `path_provider` (low risk) | Tampering | `PathResolver` only composes paths under known subdirs; never accepts user-supplied path components |
| `dynamic_color` plugin reads Windows registry | Information Disclosure | Read-only; no write; no exfil [VERIFIED: dynamic_color README] |
| `package:sqlite3` Dart hooks execute bundled `.so` / `.dll` | Code Execution | All binaries are official SQLite C library (no malicious payload); signed by simonbinder.eu; pub.dev 1.43M monthly downloads |

**Security note for Phase 1:** The DB is **not encrypted**. PITFALLS §"Security Mistakes" recommends `sqlcipher_flutter_libs` as v2 enhancement. Document in README that user-saved DB on shared Windows machines is readable by anyone with file access. Phase 1 explicitly accepts this risk per PROJECT.md "Out of Scope" (encryption requires key management UX that doesn't fit v1's "个人小范围" scope).

## Assumptions Log

> Lists claims tagged `[ASSUMED]` in this research. The planner and discuss-phase use this section to identify decisions that need user confirmation before execution.

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `path_provider`'s `getApplicationSupportDirectory()` returns the same parent across all 5 v1 platforms (Windows, Linux, Android, iOS, macOS) | Standard Stack | Low — path_provider is an official `flutter.dev` package, supported on all 5 platforms per pub.dev; behavior is stable |
| A2 | `dynamic_color` returns a non-null `ColorScheme?` on Windows 11 with custom accent color set; null on Windows 10 | Common Pitfalls §7 | Low — UI-SPEC.md already specifies fallback to `ColorScheme.fromSeed`; null path is the expected default |
| A3 | `flutter create --platforms=windows,linux,android,ios,macos` works on a Windows host (no macOS / Linux required) | Code Examples §1 | High if wrong — but verified on docs.flutter.dev; the command just generates source folders, no compile happens at create time |
| A4 | `flutter build ios --no-codesign --simulator` succeeds on macOS host (not on this Windows dev machine) | Validation Architecture | Low — only matters for CI / cross-host verification; Phase 1 success criterion #2 explicitly allows source-level compile check |
| A5 | `NativeDatabase.createInBackground` works identically across Windows / Linux / Android without per-platform setup | Standard Stack | Low — verified on drift.simonbinder.eu/platforms/vm; "all native Dart and Flutter platforms are supported without any further setup or dependencies" |
| A6 | The user's Windows dev machine will have Flutter installed before Phase 1 plans execute | Environment Availability | High — currently `flutter --version` returns "command not found"; planning should include "Install Flutter SDK" as Plan 0 or Wave 0 task |
| A7 | `package:sqlite3` 3.3.3 Dart hooks produce no platform-specific build issues (Android NDK / Windows MSVC / Linux GTK all happy) | Standard Stack | Low — package is at 1.43M monthly downloads with no widespread build failures; cross-platform support verified on pub.dev |
| A8 | `riverpod_generator` 4.0.4 + `flutter_riverpod` 3.3.2 version compatibility is stable (the major version bump from 2.x to 3.x is the concern) | Standard Stack | Medium — major version bumps in Riverpod historically broke APIs; 3.x is the current stable per pub.dev, but Plan should pin both to exact versions (`flutter_riverpod: 3.3.2` not `^3.3.2`) |
| A9 | `freezed 3.2.5` is compatible with `analyzer 8.x` (required by Riverpod 3.x) | Standard Stack | Low — STACK.md compatibility matrix documents this; if it breaks, bump `freezed` to 4.0.0-dev if needed |

**If this table is empty:** All claims in this research were verified or cited — no user confirmation needed.
**This table is NOT empty:** A2 (dynamic_color on Windows) and A6 (Flutter install) and A8 (Riverpod 3.x major version) are the three to flag for the user. The first two are low-risk; the third (A8) deserves a moment of attention during planning to ensure the planner pins versions exactly.

## Open Questions

1. **Flutter SDK install status**
   - What we know: `flutter --version` returns "command not found" on this Windows dev host
   - What's unclear: When does the user plan to install Flutter? Will it happen before Phase 1 plans execute?
   - Recommendation: First plan in Phase 1 should include "Install Flutter 3.35.7 + Android SDK + Visual Studio 2022 C++ workload" as a precondition; defer all build verification until install completes

2. **iOS / macOS build verification on dev machine**
   - What we know: Dev host is Windows, lacks Xcode; ROADMAP.md success criterion #2 requires `flutter build ios --no-codesign --simulator` to succeed
   - What's unclear: Is there a macOS host or CI available for the source-level compile check? Or do we accept "no distributable" and skip?
   - Recommendation: Plan 1's verification step should ask the user to confirm CI availability; if not, mark iOS/macOS build as "manual / CI-only" in the plan completion report

3. **Riverpod 3.x API stability for our use cases**
   - What we know: `@riverpod` codegen is the documented primary pattern; `AsyncValue` / `switch-case` is the recommended consumption pattern
   - What's unclear: Riverpod 3.x is a major version bump from 2.x; specific APIs like `ref.invalidate(ledgerProvider)` vs `ref.invalidateSelf()` may have shifted
   - Recommendation: Plan should include a "Riverpod 3.x API smoke test" sub-task in the first provider-heavy plan; if issues found, document the workaround

4. **drift_dev codegen output path**
   - What we know: Generated file is `database.g.dart` next to `database.dart` (via `part` directive)
   - What's unclear: Whether `build_runner` will find all 7 `Table` files in `lib/data/db/tables/` without explicit configuration
   - Recommendation: First `dart run build_runner build` should be followed by inspection of `database.g.dart` to confirm all 6 tables are referenced; if missing, add `build.yaml` config

5. **dynamic_color on Windows: registry access required?**
   - What we know: Windows accent color is read from `HKEY_CURRENT_USER\Software\Microsoft\Windows\DVC` or similar
   - What's unclear: Whether the `dynamic_color` package's Windows implementation requires specific Windows version (10 vs 11) or specific user settings
   - Recommendation: Manual smoke test on actual Windows 11 machine is the only way to confirm; if fallback is always taken, that's fine — the seed color path is the documented v1 default

## Sources

### Primary (HIGH confidence — verified in this session)

- **drift 2.34.0** — `pub.dev/packages/drift` (verified 2026-06-19) + `drift.simonbinder.eu/platforms/vm` (verified `NativeDatabase.createInBackground` cross-platform pattern; verified `MigrationStrategy` `onCreate`/`onUpgrade` API at `drift.simonbinder.eu/migrations`)
- **flutter_riverpod 3.3.2** — `pub.dev/packages/flutter_riverpod` (verified 2026-06-19; `@riverpod` codegen is the primary documented pattern)
- **riverpod_generator 4.0.4** + **riverpod_annotation 4.0.3** — `pub.dev/packages/riverpod_generator` (verified 2026-06-19; `xxxProvider` symbol generation pattern; `build.yaml` config options)
- **go_router 17.3.0** — `pub.dev/packages/go_router` (verified 2026-06-19; Flutter Favorite, BSD-3, feature-complete)
- **dynamic_color 1.8.1** — `pub.dev/packages/dynamic_color` (verified 2026-06-19; Android S+ / Windows 11 / macOS / Linux accent color sources; `DynamicColorBuilder` provides nullable `ColorScheme?`)
- **path_provider 2.1.6** — `pub.dev/packages/path_provider` (verified 2026-06-19; `getApplicationSupportDirectory()` supported on all 5 v1 platforms)
- **freezed 3.2.5** — `pub.dev/packages/freezed` (verified 2026-06-19; trio install with `freezed_annotation` + `build_runner`)
- **path 1.9.1** — `pub.dev/packages/path` (verified 2026-06-19; `p.join()` for cross-platform path composition)
- **sqlite3 3.3.3** (transitive) — `pub.dev/packages/sqlite3` (verified 2026-06-19; replaces deprecated `sqlite3_flutter_libs` for drift 2.32+; Dart hooks bundle native SQLite for 6 platforms including Windows aarch64/x64/x86)
- **sqlite3_flutter_libs 0.6.0+eol** — `pub.dev/packages/sqlite3_flutter_libs` (verified 2026-06-19; **DEPRECATED** — "Not used anymore, update to version 3.x of package:sqlite3 instead")
- **ColorScheme.fromSeed** — `api.flutter.dev/flutter/material/ColorScheme/ColorScheme.fromSeed.html` (verified 2026-06-19; `brightness: Brightness` parameter supports dark mode)
- **flutter create --platforms** — `docs.flutter.dev/reference/create-new-app` (verified 2026-06-19; multi-platform syntax `flutter create --platforms=android,ios,linux,macos,windows,web my_app`)

### Secondary (MEDIUM confidence — cited from prior research)

- **Flutter 3.35.7 stable** — STACK.md (researched 2026-06-19; ships with Dart 3.9.2; first-class Windows + Android targets)
- **Drift compatibility matrix** — STACK.md (drift 2.34 / drift_dev 2.34 pin together; sqlite3_flutter_libs latest for cross-platform SQLite)
- **ARCHITECTURE.md** folder layout — prior research (2025-01; lib/core + lib/data + lib/domain + lib/features; PathResolver pattern; drift schema design)
- **PITFALLS.md** §3 (SQLite FFI) + §7 (lifecycle) — prior research (2025-01; mapped to Phase 1 path resolution + commit-on-write defaults)
- **CONTEXT.md** D-01 through D-23 — user-locked decisions (2025-01-14; verbatim copied into "User Constraints" section above)
- **UI-SPEC.md** typography / color / routing — `01-UI-SPEC.md` (2025-01-14; Material 3 4-size/2-weight type scale; `Color(0xFF6750A4)` seed; 6 go_router routes; `DynamicColorBuilder` fallback chain)

### Tertiary (LOW confidence — unverified, flagged in Assumptions Log)

- **dynamic_color behavior on Windows 11** — `dynamic_color` README confirms support, but per-user-setting dependency not independently tested; treat as "may return accent color or null"
- **Riverpod 3.x API for `ref.invalidate(ledgerProvider)` vs `ref.invalidateSelf()`** — major version bump from 2.x; specific API behavior unverified in this session; pinned version in `pubspec.yaml` recommended

## Metadata

**Confidence breakdown:**

| Area | Level | Reason |
|------|-------|--------|
| Standard Stack | HIGH | Every library version verified on pub.dev 2026-06-19; key APIs (NativeDatabase, MigrationStrategy, @riverpod, GoRouter, DynamicColorBuilder) verified in official docs |
| Architecture | HIGH | Pattern follows ARCHITECTURE.md + UI-SPEC.md; lib/ structure is conventional; PathResolver pattern is standard |
| Pitfalls | HIGH | PITFALLS.md §3 + §7 directly applicable; each mitigation is a concrete code pattern, not hand-wavy advice |
| 5-Platform flutter create | HIGH | Documented in `docs.flutter.dev/reference/create-new-app`; `--platforms` flag is stable since Flutter 1.20 |
| 6-Table drift schema | HIGH | Standard drift pattern; Table classes are syntactically simple; no exotic features used |
| CJK font fallback | MEDIUM | Inferred from UI-SPEC.md "Typography §CJK handling" + STACK.md; actual rendering needs manual verification on each target platform |
| dynamic_color fallback | MEDIUM | Per-platform behavior is nullable but documented; real-world availability depends on user OS settings; fallback path is the safe default |
| Riverpod 3.x codegen | MEDIUM | Major version bump from 2.x; specific APIs may have minor changes; pin exact versions in pubspec |
| Environment availability | LOW | Dev machine lacks Flutter SDK; Phase 1 build verification requires Flutter install + Android SDK + VS2022 / Linux / Xcode as appropriate |
| Source-level iOS/macOS build | LOW | Requires macOS host; dev machine is Windows; build verification must defer to CI or different host |

**Research date:** 2026-06-19
**Valid until:** 2026-07-19 (30 days for stable stack; recompute if Riverpod 3.x patches land)

---

*Research for: RedClass Phase 1 — Foundation & Persistence*
*Researched: 2026-06-19*
*Output path: `.planning/phases/01-foundation-persistence/01-RESEARCH.md`*
