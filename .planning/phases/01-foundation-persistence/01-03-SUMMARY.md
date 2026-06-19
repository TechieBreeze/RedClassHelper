---
phase: 01-foundation-persistence
plan: 03
subsystem: paths + database
tags: [path_provider, riverpod, path_resolver, cross-platform, sqlite]

# Dependency graph
requires:
  - phase: 01-foundation-persistence
    plan: 02
    provides: "7 drift tables, AppDatabase with schemaVersion=1, static factory methods, database.g.dart"
provides:
  - "PathResolver class: sole path_provider caller (D-15), 5 typed getters (D-19)"
  - "pathResolverProvider: @Riverpod(keepAlive:true) Future<PathResolver>"
  - "appDatabaseProvider: @Riverpod(keepAlive:true) watches pathResolverProvider, WAL mode"
  - "main.dart: pre-resolved PathResolver + ProviderScope override (Pitfall 4 mitigation)"
  - "6 PathResolver unit tests with fake-directory pattern"
affects: ["01-04-PLAN (go_router uses PathResolver-independent MaterialApp)", "Phase 2-7 (all phases consume PathResolver for DB/models/cache/temp paths)"]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Pattern 1: PathResolver as sole path_provider caller — grep guard enforced (D-15)"
    - "Pattern 2: 5 typed getters (databasePath/modelsDir/cacheDir/diagnosticsDir/tempDir) — D-19"
    - "Pattern 3: @Riverpod(keepAlive:true) for long-lived providers (pathResolver, appDatabase)"
    - "Pattern 4: Pre-resolve PathResolver.create() in main() + ProviderScope override (Pitfall 4)"
    - "Pattern 5: Fake-directory test pattern — construct PathResolver with temp Directory objects"
    - "Pattern 6: _ensureSubdir helper — Directory.create(recursive:true) only if !exists"

key-files:
  created:
    - lib/core/paths.dart (PathResolver class + @Riverpod pathResolver provider)
    - lib/core/paths.g.dart (codegen output, 1310 bytes)
    - test/core/paths/path_resolver_test.dart (6 test cases)
  modified:
    - lib/data/db/database.dart (added appDatabase provider)
    - lib/data/db/database.g.dart (codegen updated with appDatabaseProvider)
    - lib/main.dart (pre-resolve + ProviderScope override + M3 theme)

key-decisions:
  - "@Riverpod(keepAlive:true) for both pathResolverProvider and appDatabaseProvider — prevents premature disposal during app lifetime"
  - "PathResolver pre-resolved in main() before runApp — avoids late-init error from path_provider in ref.watch chain (Pitfall 4)"
  - "Fake-directory test pattern (not riverpod override) for path_resolver_test — simpler, tests the class directly"
  - "appDatabaseProvider placed in database.dart alongside AppDatabase — keeps database concerns co-located"

patterns-established:
  - "Pattern 1: PathResolver as sole path_provider caller — grep guard enforced"
  - "Pattern 2: 5 typed getters for all filesystem paths"
  - "Pattern 3: @Riverpod(keepAlive:true) for infrastructure providers"
  - "Pattern 4: Pre-resolve in main() + ProviderScope override"
  - "Pattern 5: Fake-directory unit test pattern for PathResolver"

requirements-completed: [PLT-05]

# Metrics
duration: 8min
completed: 2026-06-19
---

# Phase 01 Plan 03: PathResolver + Database Provider 总结

**PathResolver 类实现（D-15~D-19），5 个 getter 覆盖所有文件系统路径，@Riverpod provider 链（pathResolver → appDatabase），main.dart Pitfall 4 防护，6 个单元测试全部通过**

## Performance

- **Duration:** ~8 min
- **Started:** 2026-06-19T09:50:00Z
- **Completed:** 2026-06-19T09:57:35Z
- **Tasks:** 3
- **Files created:** 3

## Accomplishments

- `PathResolver` 类作为 app 内唯一 `path_provider` 调用点（D-15），通过 grep guard 静默验证
- 5 个类型化 getter：`databasePath`（String）、`modelsDir`（Future\<Directory\>）、`cacheDir`、`diagnosticsDir`、`tempDir`（D-19）
- 3 层路径分层（D-16）：AppSupport → SQLite、AppDocs → models/cache/diagnostics、Temp → 临时文件
- `pathResolverProvider` + `appDatabaseProvider` —— `@Riverpod(keepAlive:true)` 链，WAL 模式数据库
- `main.dart` 预解析 `PathResolver.create()` 并通过 `ProviderScope` override 注入（Pitfall 4 防护）
- 6 个 PathResolver 单元测试全部通过（虚假目录模式，零 mock）

## Task Commits

Each task was committed atomically:

1. **Task 1: 创建 PathResolver 类** — `2be65ef` (feat)
2. **Task 2: 连接 appDatabaseProvider + main.dart override** — `56daa7b` (feat)
3. **Task 3: 编写 path_resolver_test.dart（6 个测试）** — `2f164ba` (test)

## Files Created/Modified

- `lib/core/paths.dart` — PathResolver 类 + @Riverpod pathResolver provider（D-15~D-19）
- `lib/core/paths.g.dart` — build_runner 生成（1310 字节）
- `lib/data/db/database.dart` — 添加 @Riverpod appDatabase provider，监听 pathResolverProvider
- `lib/data/db/database.g.dart` — 代码生成更新，新增 appDatabaseProvider 符号
- `lib/main.dart` — pre-resolve PathResolver + ProviderScope override + M3 light/dark 主题
- `test/core/paths/path_resolver_test.dart` — 6 个测试用例

## Decisions Made

- **两个 provider 均使用 `@Riverpod(keepAlive:true)`**：基础设施 provider 不应被自动销毁
- **在 `main()` 中预解析 PathResolver 并通过 override 注入**：避免 `ref.watch(pathResolverProvider.future)` 时的 late-init 错误（Pitfall 4）
- **虚假目录测试模式**：直接使用 `Directory.systemTemp.createTemp()` 构造 PathResolver，无需 mock `path_provider`
- **appDatabaseProvider 放在 database.dart 中**：与 AppDatabase 类保持在同一文件，关注点集中

## Deviations from Plan

无 — 计划完全按照书面内容执行。所有 `@Riverpod` 注解、所有 5 个 getter、所有 provider 连接均与计划完全一致。

## Issues Encountered

- `--delete-conflicting-outputs` 标志被 build_runner 标记为已移除但无影响——构建正常完成
- 计划中的 grep guard 模式 `grep -v "paths.dart\|paths.g.dart"` 将 `lib/main.dart` 中的注释提及误报为命中——验证后确认 main.dart 仅包含注释提及，无实际 `import 'package:path_provider'`

## Known Stubs

无 — 所有 getter 均为完整实现。`_ensureSubdir` 延迟创建在首次访问时正确处理。

## Threat Flags

无 — 此计划未引入超出计划 `<threat_model>` 的新安全边界。PathResolver 是唯一允许调用 `path_provider` 的类（已通过 grep guard 验证 T-03-01）。

## User Setup Required

无 — 不需要外部服务配置。

## Next Phase Readiness

- **Plan 01-04（go_router）就绪**：`main.dart` 当前使用 `MaterialApp`（非 `MaterialApp.router`）；Plan 01-04 将 `RedClassApp` 替换为 `MaterialApp.router`，不影响 PathResolver 覆盖模式
- **Phase 2-7 就绪**：所有未来 phases 通过 `ref.watch(pathResolverProvider.future)` 获取 PathResolver；无需直接处理路径解析

---

*Phase: 01-foundation-persistence*
*Completed: 2026-06-19*

## Self-Check: PASSED

- [x] lib/core/paths.dart exists
- [x] lib/core/paths.g.dart exists
- [x] test/core/paths/path_resolver_test.dart exists
- [x] Commit 2be65ef (Task 1) found
- [x] Commit 56daa7b (Task 2) found
- [x] Commit 2f164ba (Task 3) found
- [x] flutter analyze exits 0
- [x] flutter test (11/11) passes
- [x] grep guard: only paths.dart + paths.g.dart import path_provider
