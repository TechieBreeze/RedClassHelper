---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: executing
stopped_at: Phase 4 context gathered — 17 implementation decisions captured. Ready for `/gsd-plan-phase 4` or `/gsd-ui-phase 4`.
last_updated: "2026-06-20T01:49:50.334Z"
last_activity: 2026-06-20 -- Phase 04 planning complete
progress:
  total_phases: 7
  completed_phases: 3
  total_plans: 24
  completed_plans: 19
  percent: 79
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-06-20 after Android scope cut)

**Core value:** 把"老师发的题库文件"零摩擦地变成"可立刻投入复习的结构化题库"，让本地刷题体验比任何在线刷题网站都更顺手——**离线可用、零配置、解析即用、桌面本地推理**。
**Current focus:** Phase 4 — quiz-core-wrong-question-ledger (next phase)

## Current Position

Phase: 3 of 7 complete — transitioning to Phase 4
Plans: 19 of 19 executed (Phases 1-3: 100%)
Status: Ready to execute
Last activity: 2026-06-20 -- Phase 04 planning complete
Progress: [████░░░░░░] 43% (3/7 phases completed)

## Performance Metrics

**Velocity:**

- Total plans completed: 19
- Total execution time: ~7 hours

**By Phase:**

| Phase | Plans | Status |
|-------|-------|--------|
| 1. Foundation & Persistence | 7/7 | Complete |
| 2. Desktop File Import Pipeline | 4/4 | Complete |
| 3. Desktop LLM Integration | 8/8 | Complete |
| 4. Quiz Core & Wrong-Question Ledger | 0/5 | Ready to execute |
| 5. JSON Export/Import + Multiple-Choice + Bookmarks + Statistics | 0/7 | Not started |
| 6. UX Polish & Diagnostics | 0/5 | Not started |
| 7. Desktop Packaging & Verification | 0/5 | Not started |

**Recent Trend:**

- Last 5 plans: —
- Trend: —

*Updated after each plan completion*
| Phase 01-foundation-persistence P02 | 13min | 4 tasks | 11 files |
| Phase 01-foundation-persistence P03 | 8min | 3 tasks | 6 files |
| Phase 01-foundation-persistence P04 | 4min 12s | 4 tasks | 9 files |
| Phase 01-foundation-persistence P05 | 45min | 4 tasks | 6 files |
| Phase 02-desktop-file-import-pipeline P02-00 | 30min | 12 tasks | 25 files |
| Phase 02-desktop-file-import-pipeline P02-01 | 3min | 1 task | 2 files | — gap closure (codegen fix)
| Phase 02-desktop-file-import-pipeline P02-02 | 3min | 2 tasks | 2 files | — gap closure (navigation + drag)
| Phase 02-desktop-file-import-pipeline P02-03 | 5min | 3 tasks | 5 files | — gap closure (CJK + skipped + guards)
| Phase 02 R2 verification | 15min | 2 test fixes | 3 docs | — 66/66 tests, 0e0w analyze
| Phase 03-desktop-llm-integration-parse-quality P08 | 25min | 1 tasks | 6 files |

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
- [Phase 03-desktop-llm-integration-parse-quality]: FfiLlmClient implemented as v1 production FFI path — dart:ffi DynamicLibrary binding to llama.cpp shared library, eliminating llama-server process dependency

### Pending Todos

[From .planning/todos/pending/ — ideas captured during sessions]

None yet.

### Blockers/Concerns

[Issues that affect future work]

- **Phase 2 — docx/doc parsing**: No mature pure-Dart `.docx` reader on pub.dev; `archive + xml` works but requires hand-rolled WordprocessingML traversal. `.doc` (Word 97-2003 OLE2 binary) is now in scope — no known pure Dart OLE2 reader; may need pandoc/LibreOffice CLI fallback. Mitigation: pull 3-5 real Chinese university `.docx` files during planning; `doc/example/` has 4 real samples (2 `.doc`, 1 `.docx`, 1 `.pdf`). (PITFALL 6, MEDIUM confidence)
- **Phase 3 — LLM FFI**: No pub.dev wrapper covers Windows + Linux; ~1-2 weeks of FFI shim work expected. Mitigation: 1-week spike before locking plan; HTTP-only fallback documented. (PITFALL 4, MEDIUM confidence)
- **Phase 3 — desktop OOM**: 1.5B Q4_K_M model needs ~2-2.5 GB peak RAM; low-end laptops are at risk. Mitigation: capability probe + lazy model load + n_ctx=1024 + "Fast/Recommended/Experimental" tier UI. (PITFALL 4)
- **Phase 7 — Desktop packaging**: Builds behave differently per platform; real device smoke tests required before shipping. Windows SmartScreen, Linux distro compatibility are non-trivial.
- **Phase 5 — JSON format design**: The public JSON schema must be stable across the app's lifetime; get it right in plan-phase or commit to a versioning strategy (semver inside the JSON, e.g., `{"version": "1.0.0", ...}`).

## Session Continuity

Last session: 2026-06-20
Stopped at: Phase 4 context gathered — 17 implementation decisions captured. Ready for `/gsd-plan-phase 4` or `/gsd-ui-phase 4`.
Resume file: None

### Recent decisions

- **2026-06-20**: Android dropped from v1 scope. v1 ships Windows + Linux only. Decision recorded in PROJECT.md Key Decisions.
