---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: executing
stopped_at: Completed 02-00-PLAN.md — Desktop File Import Pipeline
last_updated: "2026-06-19T14:24:24.141Z"
last_activity: 2026-06-19 -- Phase 02 planning complete
progress:
  total_phases: 7
  completed_phases: 1
  total_plans: 11
  completed_plans: 8
  percent: 73
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2025-01-14 after platform-scope contraction)

**Core value:** 把"老师发的题库文件"零摩擦地变成"可立刻投入复习的结构化题库"，让本地刷题体验比任何在线刷题网站都更顺手——**离线可用、零配置、解析即用、桌面解析、移动轻量**。
**Current focus:** Phase 02 — desktop-file-import-pipeline

## Current Position

Phase: 02 (desktop-file-import-pipeline) — EXECUTING
Plan: 1 of 1
Status: Ready to execute
Last activity: 2026-06-19 -- Phase 02 planning complete
Progress: [█░░░░░░░░░] 14% (1/7 phases, 1 planned / 7 executed)

## Performance Metrics

**Velocity:**

- Total plans completed: 7
- Average duration: 25 min
- Total execution time: ~5 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 1. Foundation & Persistence | 7/7 | ~5 hrs | 25 min |
| 2. Desktop File Import Pipeline | 1 planned / 10 tasks | — | — |
| 3. Desktop LLM Integration | 0/8 | — | — |
| 4. Quiz Core & Wrong-Question Ledger | 0/9 | — | — |
| 5. JSON Cross-Device Transfer + Multiple-Choice + Bookmarks + Statistics | 0/9 | — | — |
| 6. UX Polish & Diagnostics | 0/6 | — | — |
| 7. Three-Platform Packaging & Verification | 0/7 | — | — |

**Recent Trend:**

- Last 5 plans: —
- Trend: —

*Updated after each plan completion*
| Phase 01-foundation-persistence P02 | 13min | 4 tasks | 11 files |
| Phase 01-foundation-persistence P03 | 8min | 3 tasks | 6 files |
| Phase 01-foundation-persistence P04 | 4min 12s | 4 tasks | 9 files |
| Phase 01-foundation-persistence P05 | 45min | 4 tasks | 6 files |
| Phase 02-desktop-file-import-pipeline P02-00 | 1800 | 8 tasks | 25 files |

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- **Phase 1 (this phase)**: Use `getApplicationSupportDirectory()` (not `Documents`) for SQLite to avoid OneDrive sync corruption on Windows and respect Android sandboxed storage.
- **Phase 1 (this phase)**: drift (not raw sqflite) for compile-time schema safety and reactive streams.
- **Phase 1 (this phase)**: Single `PathResolver` class as the only `path_provider` call site.
- **Phase 1 (this phase, latest)**: Project initialized with `flutter create --platforms=windows,linux,android,ios,macos` — 3 distributable targets + 2 source-only targets from day 1.
- **Phase 2 (planned)**: `file_picker` integration scoped to desktop only; Android import page will branch via `Platform.isWindows || Platform.isLinux`.
- **Phase 3 (planned)**: `LlmClient` abstraction with Stub + HTTP implementations; FFI binding gated on a 1-week spike. Provider gated on desktop — Android throws `UnsupportedError`.
- **Phase 3 (planned)**: GBNF grammar + temperature=0 + fixed seed to eliminate LLM JSON drift.
- **Phase 5 (planned)**: Public JSON question-bank format documented in `doc/question-bank-json.md`; desktop exports, all 3 v1 platforms import.
- **Cross-phase**: Three review modes share one `wrongQuestionsProvider` exposed as `Stream<List<WrongQuestionEntry>>`; ledger transitions go through a single `LedgerRepository` method in a DB transaction.
- **Cross-phase (latest)**: Platform-conditional UI is the explicit architectural choice. The home page and import page branch on `Platform.isWindows || Platform.isLinux` (desktop) vs Android. iOS / macOS compile paths exist but are not exercised by v1 logic.
- [Phase 01-foundation-persistence]: UNIQUE 约束放在表级 customConstraints 而非列级 customConstraint——当列同时有 references() FK 时，列级 customConstraint 会覆盖 FK
- [Phase 01-foundation-persistence]: autoIncrement() 列自动设为主键，不需要再 override primaryKey
- [Phase 01-foundation-persistence]: databaseProvider 延后到 Plan 01-03，当前 AppDatabase 提供静态工厂方法 openAppDatabase/openInMemoryDatabase
- [Phase 01-foundation-persistence]: @Riverpod(keepAlive:true) for both pathResolverProvider and appDatabaseProvider — prevents premature disposal during app lifetime
- [Phase 01-foundation-persistence]: PathResolver pre-resolved in main() before runApp — avoids late-init error from path_provider in ref.watch chain (Pitfall 4)
- [Phase 01-foundation-persistence]: Fake-directory test pattern for PathResolver — construct with temp Directory objects, no path_provider mock needed
- [Phase 01-foundation-persistence]: GoRouter 配置使用 6 条 GoRoute,无 ShellRoute (StatefulShellRoute 推迟到 Phase 5)
- [Phase 01-foundation-persistence]: go_router 是唯一导航 API — 静态 grep 确认 lib/ 中无 Navigator.push 调用
- [Phase 01-foundation-persistence]: kSeedColor = Color(0xFF6750A4) as M3 baseline fallback seed (D-20)
- [Phase 01-foundation-persistence]: DynamicColorBuilder wraps MaterialApp.router; buildAppTheme(Brightness, ColorScheme?) uses harmonized() with fromSeed fallback (D-23/Pitfall 7)
- [Phase 01-foundation-persistence]: GoRouter state leak between tests: setUp { appRouter.go('/') } pattern documented
- [Phase 02-desktop-file-import-pipeline]: Feature-first directory structure (lib/features/import/) over data-centric (lib/data/providers/) to follow existing project convention from Phase 01

### Pending Todos

[From .planning/todos/pending/ — ideas captured during sessions]

None yet.

### Blockers/Concerns

[Issues that affect future work]

- **Phase 2 — docx/doc parsing**: No mature pure-Dart `.docx` reader on pub.dev; `archive + xml` works but requires hand-rolled WordprocessingML traversal. `.doc` (Word 97-2003 OLE2 binary) is now in scope — no known pure Dart OLE2 reader; may need pandoc/LibreOffice CLI fallback. Mitigation: pull 3-5 real Chinese university `.docx` files during planning; `doc/example/` has 4 real samples (2 `.doc`, 1 `.docx`, 1 `.pdf`). (PITFALL 6, MEDIUM confidence)
- **Phase 3 — LLM FFI**: No pub.dev wrapper covers Windows + Linux; ~1-2 weeks of FFI shim work expected. Mitigation: 1-week spike before locking plan; HTTP-only fallback documented. (PITFALL 4, MEDIUM confidence)
- **Phase 3 — desktop OOM**: 1.5B Q4_K_M model needs ~2-2.5 GB peak RAM; low-end laptops are at risk. Mitigation: capability probe + lazy model load + n_ctx=1024 + "Fast/Recommended/Experimental" tier UI. (PITFALL 4)
- **Phase 7 — Cross-platform real-device validation**: Builds behave differently per platform; real device smoke tests required before shipping. Windows SmartScreen, Linux distro compatibility, Android signing key management are all non-trivial.
- **Phase 5 — JSON format design**: The public JSON schema must be stable across the app's lifetime; get it right in plan-phase or commit to a versioning strategy (semver inside the JSON, e.g., `{"version": "1.0.0", ...}`).

## Session Continuity

Last session: 2026-06-19T14:08:39.912Z
Stopped at: Completed 02-00-PLAN.md — Desktop File Import Pipeline
Resume file: None

### Recent plan-completion decisions

- **Plan 01-00 (this plan, latest)**: Flutter SDK installed via direct git clone (not FVM) at `C:\Users\Lenovo\flutter`. Version 3.44.2 stable (newer than plan's 3.35.7; satisfies "3.35.7+" must-have).
- **Plan 01-00 (this plan)**: Android SDK installed via cmdline-tools CLI (not Android Studio GUI) at `C:\Users\Lenovo\AppData\Local\Android\Sdk`. Platform 35 + Build-Tools 35.0.0 + platform-tools 37.0.0; all 17 licenses accepted. Java 21 from `D:\Java\jdk-21` used as JAVA_HOME.
- **Plan 01-00 (this plan)**: Visual Studio Build Tools 2026 18.1.1 was pre-existing (not VS 2022 Community); flutter doctor confirms green for VS toolchain. No install needed.
- **Plan 01-00 (this plan)**: `flutter create --template=app --platforms=windows` end-to-end smoke test passed (27 files, pub deps resolved). Toolchain ready for Plan 01-01's `flutter create --platforms=windows,linux,android,ios,macos`.
