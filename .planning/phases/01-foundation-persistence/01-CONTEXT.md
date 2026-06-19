# Phase 1: Foundation & Persistence - Context

**Gathered:** 2025-01-14
**Status:** Ready for planning

<domain>
## Phase Boundary

引导一个可运行的 Flutter 应用，覆盖三个 v1 分发平台（Windows / Linux / Android）外加 iOS/macOS 源码编译支持。带稳定的 drift schema、跨平台路径解析和导航骨架。后续所有 phase 都依赖此基础。

**本阶段不实现**：题库导入、LLM 解析、答题循环、统计——这些是 Phase 2-7 的事。本阶段只产出"可启动 + 可导航 + 数据可持久化"的骨架。

</domain>

<decisions>
## Implementation Decisions

### 项目初始化粒度
- **D-01:** Flutter 包名用 `com.redclass`（与项目名一致；Windows `.exe`、Linux `.AppImage`、Android `.apk` 三端产物名统一为 `redclass`）
- **D-02:** 代码组织采用按特性分层：`lib/core/`（paths / theme / utils）、`lib/data/`（db / repositories / llm_client）、`lib/domain/`（entities / value objects）、`lib/features/`（home / bank_detail / import / quiz / stats / bookmarks / settings）
- **D-03:** 启用 Riverpod 代码生成（`@riverpod` + `riverpod_generator` + `build_runner`）——与 drift/freezed 的 codegen 工具链统一
- **D-04:** `flutter create` 命令使用 `--platforms=windows,linux,android,ios,macos`（一次性创建 5 个源码目录；v1 只分发前 3 个，iOS/macOS 仅源码编译）
- **D-05:** Linux 桌面打包目标优先 AppImage（跨发行版，单文件可运行）
- **D-06:** 启用 `build_runner watch` 模式作为开发日常（自动重生成 drift/freezed/riverpod 产物）

### DB schema 表设计（drift v1 schema）
- **D-07:** `QuestionBank` 表字段：`id` (TEXT, PK, UUID) / `name` (TEXT) / `source` (TEXT, 文件路径或描述) / `question_count` (INTEGER) / `created_at` (DATETIME) / `updated_at` (DATETIME)。不预留 import_source_type / parse_job_id 字段——Phase 2/3 需要时再迁移
- **D-08:** `Question` 表字段：`id` (TEXT, PK, UUID) / `bank_id` (TEXT, FK→QuestionBank.id) / `type` (TEXT, 'single' | 'multiple') / `stem` (TEXT) / `options_json` (TEXT, JSON 数组 `[{key, text}]`) / `correct_json` (TEXT, JSON 数组 `["A","B"]`) / `raw_text` (TEXT, 原始文本供 LLM 重放和调试) / `created_at` (DATETIME)
- **D-09:** `WrongLedgerEntry` 表（错题本独立表）：`id` (INTEGER, PK, autoincrement) / `question_id` (TEXT, FK→Question.id, UNIQUE) / `times_wrong` (INTEGER) / `first_wrong_at` (DATETIME) / `last_wrong_at` (DATETIME) / `mastered_at` (DATETIME, nullable)。**不**在 Question 表加 bool 字段——状态机清晰
- **D-10:** `AnswerAttempt` 表字段：`id` (INTEGER, PK, autoincrement) / `question_id` (TEXT, FK) / `given_answer_json` (TEXT) / `is_correct` (BOOL) / `mode` (TEXT, 'random' | 'review' | 'spotcheck') / `elapsed_ms` (INTEGER) / `created_at` (DATETIME)。v1 不加 `session_id` / `bank_id` 冗余 / `confidence` 自评
- **D-11:** `Bookmark` 表（Phase 1 占位 + Phase 5 完整实现）：`id` (INTEGER, PK) / `question_id` (TEXT, FK, UNIQUE) / `created_at` (DATETIME)
- **D-12:** `ParseJob` 表（Phase 1 占位 + Phase 2 完整实现）：`id` (TEXT, PK) / `source_path` (TEXT) / `status` (TEXT, 'pending' | 'running' | 'succeeded' | 'failed' | 'cancelled') / `progress` (REAL, 0-1) / `result_count` (INTEGER) / `error_message` (TEXT, nullable) / `created_at` / `updated_at`
- **D-13:** `ParseLog` 表（Phase 1 占位 + Phase 6 完整实现）：`id` / `parse_job_id` / `level` ('info' | 'warn' | 'error') / `message` / `context_json` / `created_at`。LRU 200 行由 Phase 6 实现
- **D-14:** DB schema 版本号 `schemaVersion = 1`；`MigrationStrategy.onCreate` 创建所有表，`onUpgrade` 暂留空（v1 起步，未来 schema 变更再补）

### 路径分层（PathResolver 唯一来源）
- **D-15:** `PathResolver` 是整个 app 唯一调用 `path_provider` 的类。所有 DB / 模型 / 缓存 / 诊断路径都从它取。**禁止**业务代码直接调 `path_provider`
- **D-16:** 3 层路径分层：
  - **支持目录** (`getApplicationSupportDirectory()`)：`redclass.db` SQLite 文件
  - **文档目录** (`getApplicationDocumentsDirectory()`)：`models/*.gguf` (LLM 模型)、`cache/` (导入过程缓存)、`diagnostics/` (诊断包导出)
  - **临时目录** (`getTemporaryDirectory()`)：下载中分片、解析中临时文件
- **D-17:** `getApplicationSupportDirectory()` 而非 `getApplicationDocumentsDirectory()` 放 DB：Windows 下后者可能被 OneDrive 同步污染（详见 PITFALLS §3）
- **D-18:** 模型文件 `documents/models/*.gguf`：用户可在 Windows 资源管理器手动查看/备份/删除；Android 下位于 app-private external storage，卸载 app 会清除（用户接受此取舍）
- **D-19:** PathResolver 提供 `databasePath` / `modelsDir` / `cacheDir` / `diagnosticsDir` / `tempDir` 五个 getter；测试时可通过 Riverpod override 注入 fake paths

### Material 3 主题种子
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

</decisions>

<specifics>
## Specific Ideas

- 用户最初提到 `ui-ux-pro-max` skill (`C:\Users\Lenovo\.claude\plugins\cache\ui-ux-pro-max-skill\ui-ux-pro-max\2.5.0`) 作为 UI 设计参考。Phase 1 阶段尚未涉及具体 UI 设计，但 `core/theme.dart` 应当为后续 Phase 6 的 UI 打磨留好接入点（清晰的 light/dark theme、standard spacing、material 3 component themes）
- 用户在 `gsd-new-project` 阶段已确认"项目自用 + 小范围分享"——意味着不需要走完整测试覆盖率、不需要 CI、不需要发布流水线。Phase 1 不引入 GitHub Actions / fastlane / 自动化测试
- 用户确认 PC 端优先、移动端仅 JSON 导入——这一架构决策会从 Phase 2 开始影响 import 页 UI 分支，Phase 1 在 router 层就为后续分支预留空间（`/import` 路由在所有平台都存在，但 Phase 1 只放占位 screen）

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project context
- `.planning/PROJECT.md` — Core value, requirements, constraints, key decisions; what "RedClass" is and isn't
- `.planning/REQUIREMENTS.md` — 31 v1 requirements with traceability to phases; the 6 requirements owned by Phase 1 are IMP-05 / STOR-01 / STOR-02 / PLT-04 / PLT-05 / UI-02
- `.planning/ROADMAP.md` §"Phase 1: Foundation & Persistence" — Phase goal, success criteria, plans list

### Stack & architecture (research-backed decisions)
- `.planning/research/STACK.md` — Locked stack: Flutter 3.35.7, drift 2.34, flutter_riverpod 3.3.2, go_router 17.3, freezed 3.x, file_picker 11.0.2, path_provider 2.1.6, sqlite3_flutter_libs, Material 3. Includes install commands and version compatibility matrix
- `.planning/research/ARCHITECTURE.md` — Folder layout (lib/core, lib/data, lib/domain, lib/features), PathResolver pattern, drift schema design, Riverpod provider patterns. The proposed folder structure in this CONTEXT.md follows ARCHITECTURE.md's recommendation
- `.planning/research/PITFALLS.md` §PITFALL 3 (SQLite FFI platform quirks) + §PITFALL 7 (lifecycle) — the two pitfalls Phase 1 is responsible for preventing via PathResolver centralization and commit-on-write defaults

### Cross-device JSON protocol (preview)
- `doc/question-bank-json.md` — Stub of the public JSON format for cross-device transfer; not implemented in Phase 1, but the schema field `raw_text` in `Question` table anticipates it

### External (referenced but not yet relevant)
- None for Phase 1 — no third-party API specs, no ADRs, no design tokens yet

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- None — greenfield project; no existing code to reuse

### Established Patterns
- Research locked the architecture pattern: lib/core + lib/data + lib/domain + lib/features (Feature-first with horizontal layering). Phase 1 plan should follow this from day 1 — don't introduce any other structure that would force migration later
- Riverpod 3.3 + drift + freezed + build_runner form a single codegen toolchain. Use one `build_runner watch` session; do not split into separate runners
- `path_provider` MUST only be called inside `PathResolver`. The pattern is: PathResolver exposes typed `Future<String>` getters; Riverpod provides them; consumers await the future in their providers

### Integration Points
- DB connection (drift `DatabaseConnection`) is wired into a `databaseProvider` (Riverpod) — all repositories depend on this provider
- `go_router` config lives in `lib/routing/router.dart`; placeholder screens in `lib/features/<feature>/screen.dart` per feature
- `MaterialApp.router` in `lib/app.dart` consumes both `routerConfig` and the `appTheme` built from `core/theme.dart`

</code_context>

<deferred>
## Deferred Ideas

- GitHub Actions / CI 流水线：用户明确"小范围分享"，不需要
- 主题切换 UI（深色/浅色 toggle）：v1 Out of Scope，Phase 6 可补
- `intl` 包引入时机：Phase 5 统计页面显示日期时引入更合适
- Drift schema v2 升级路径：v1 不预留任何 v2 字段，未来需要时再做 migration

</deferred>

---

*Phase: 01-foundation-persistence*
*Context gathered: 2025-01-14*
