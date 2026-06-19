# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2025-01-14 after platform-scope + mobile-LLM-disabled update)

**Core value:** 把"老师发的题库文件"零摩擦地变成"可立刻投入复习的结构化题库"，让本地刷题体验比任何在线刷题网站都更顺手——**离线可用、零配置、解析即用、桌面解析、移动轻量**。
**Current focus:** Phase 1 — Foundation & Persistence (5-platform Flutter skeleton + drift + go_router + PathResolver)

## Current Position

Phase: 1 of 7 (Foundation & Persistence)
Plan: 0 of 6 in current phase
Status: Ready to plan
Last activity: 2025-01-14 — Platform scope expanded to 5 platforms (Windows/macOS/Linux/Android/iOS); mobile LLM disabled; JSON file transfer is the cross-device protocol

Progress: [░░░░░░░░░░] 0%

## Performance Metrics

**Velocity:**
- Total plans completed: 0
- Average duration: — min
- Total execution time: 0.0 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 1. Foundation & Persistence | 0/6 | — | — |
| 2. Desktop File Import Pipeline | 0/8 | — | — |
| 3. Desktop LLM Integration | 0/8 | — | — |
| 4. Quiz Core & Wrong-Question Ledger | 0/9 | — | — |
| 5. JSON Cross-Device Transfer + Multiple-Choice + Bookmarks + Statistics | 0/9 | — | — |
| 6. UX Polish & Diagnostics | 0/6 | — | — |
| 7. Five-Platform Packaging & Verification | 0/8 | — | — |

**Recent Trend:**
- Last 5 plans: —
- Trend: —

*Updated after each plan completion*

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- **Phase 1 (this phase)**: Use `getApplicationSupportDirectory()` (not `Documents`) for SQLite to avoid OneDrive sync corruption on Windows and respect Android/iOS sandboxed storage.
- **Phase 1 (this phase)**: drift (not raw sqflite) for compile-time schema safety and reactive streams.
- **Phase 1 (this phase)**: Single `PathResolver` class as the only `path_provider` call site.
- **Phase 1 (this phase, updated)**: Project initialized with `flutter create --platforms=windows,macos,linux,android,ios` — 5 platform targets from day 1.
- **Phase 2 (planned)**: `file_picker` integration scoped to desktop only; mobile import page will branch via `Platform.isDesktop`.
- **Phase 3 (planned)**: `LlmClient` abstraction with Stub + HTTP implementations; FFI binding gated on a 1-week spike. Provider gated on `Platform.isDesktop` — mobile throws `UnsupportedError`.
- **Phase 3 (planned)**: GBNF grammar + temperature=0 + fixed seed to eliminate LLM JSON drift.
- **Phase 5 (planned)**: Public JSON question-bank format documented in `doc/question-bank-json.md`; desktop exports, all platforms import.
- **Cross-phase**: Three review modes share one `wrongQuestionsProvider` exposed as `Stream<List<WrongQuestionEntry>>`; ledger transitions go through a single `LedgerRepository` method in a DB transaction.
- **Cross-phase (NEW)**: Platform-conditional UI is the explicit architectural choice. The home page and import page branch on `Platform.isDesktop` / `Platform.isAndroid` / `Platform.isIOS`.

### Pending Todos

[From .planning/todos/pending/ — ideas captured during sessions]

None yet.

### Blockers/Concerns

[Issues that affect future work]

- **Phase 2 — docx parsing**: No mature pure-Dart `.docx` reader on pub.dev; `archive + xml` works but requires hand-rolled WordprocessingML traversal. Mitigation: pull 3-5 real Chinese university `.docx` files during planning and write unit tests against them. (PITFALL 6, MEDIUM confidence)
- **Phase 3 — LLM FFI**: No pub.dev wrapper covers all desktop platforms; ~1-2 weeks of FFI shim work expected. Mitigation: 1-week spike before locking plan; HTTP-only fallback documented. iOS FFI deferred unless spike validates approach. (PITFALL 4, MEDIUM confidence)
- **Phase 3 — desktop OOM**: 1.5B Q4_K_M model needs ~2-2.5 GB peak RAM; low-end laptops and macOS sandbox may complicate. Mitigation: capability probe + lazy model load + n_ctx=1024 + "Fast/Recommended/Experimental" tier UI. (PITFALL 4)
- **Phase 7 — Five-platform real-device validation**: Builds behave differently per platform; real device smoke tests required before shipping. macOS notarization, Linux distro compatibility, iOS code signing are all non-trivial.
- **Phase 5 — JSON format design**: The public JSON schema must be stable across the app's lifetime; get it right in plan-phase or commit to a versioning strategy (semver inside the JSON, e.g., `{"version": "1.0.0", ...}`).

## Session Continuity

Last session: 2025-01-14 (platform-scope expansion)
Stopped at: Roadmap and requirements updated to 5 platforms + mobile-LLM-disabled; Phase 1 ready to plan
Resume file: None
