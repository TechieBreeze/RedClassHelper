# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2025-01-14)

**Core value:** 把"老师发的题库文件"零摩擦地变成"可立刻投入复习的结构化题库",让本地刷题体验比任何在线刷题网站都更顺手——**离线可用、零配置、解析即用**。
**Current focus:** Phase 1 — Foundation & Persistence

## Current Position

Phase: 1 of 7 (Foundation & Persistence)
Plan: 0 of 5 in current phase
Status: Ready to plan
Last activity: 2025-01-14 — Roadmap created (7 phases, 27 v1 requirements, 100% coverage)

Progress: [░░░░░░░░░░] 0%

## Performance Metrics

**Velocity:**
- Total plans completed: 0
- Average duration: — min
- Total execution time: 0.0 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 1. Foundation & Persistence | 0/5 | — | — |
| 2. File Import Pipeline (Read-Only) | 0/7 | — | — |
| 3. LLM Integration & Parse Quality | 0/8 | — | — |
| 4. Quiz Core & Wrong-Question Ledger | 0/8 | — | — |
| 5. Multiple-Choice, Bookmarks & Statistics | 0/6 | — | — |
| 6. UX Polish & Diagnostics | 0/6 | — | — |
| 7. Packaging & Cross-Platform Verification | 0/5 | — | — |

**Recent Trend:**
- Last 5 plans: —
- Trend: —

*Updated after each plan completion*

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- **Phase 1 (this phase)**: Use `getApplicationSupportDirectory()` (not `Documents`) for SQLite to avoid OneDrive sync corruption on Windows and respect Android scoped storage.
- **Phase 1 (this phase)**: drift (not raw sqflite) for compile-time schema safety and reactive streams.
- **Phase 1 (this phase)**: Single `PathResolver` class as the only `path_provider` call site.
- **Phase 3 (planned)**: `LlmClient` abstraction with Stub + HTTP implementations; FFI binding gated on a 1-week spike.
- **Phase 3 (planned)**: GBNF grammar + temperature=0 + fixed seed to eliminate LLM JSON drift.
- **Cross-phase**: Three review modes share one `wrongQuestionsProvider` exposed as `Stream<List<WrongQuestionEntry>>`; ledger transitions go through a single `LedgerRepository` method in a DB transaction.

### Pending Todos

[From .planning/todos/pending/ — ideas captured during sessions]

None yet.

### Blockers/Concerns

[Issues that affect future work]

- **Phase 2 — docx parsing**: No mature pure-Dart `.docx` reader on pub.dev; `archive + xml` works but requires hand-rolled WordprocessingML traversal. Mitigation: pull 3-5 real Chinese university `.docx` files during planning and write unit tests against them. (PITFALL 6, MEDIUM confidence)
- **Phase 3 — LLM FFI**: No pub.dev wrapper covers both Windows + Android; ~1-2 weeks of FFI shim work expected. Mitigation: 1-week spike before locking plan; HTTP-only fallback documented. (PITFALL 4, MEDIUM confidence)
- **Phase 3 — Android OOM**: 1.5B Q4_K_M model needs ~2-2.5 GB peak RAM; 4 GB phones are at risk. Mitigation: capability probe + lazy model load + n_ctx=1024 + "Fast/Recommended/Experimental" tier UI. (PITFALL 4)
- **Phase 7 — Android real-device validation**: APK behaves differently in dev vs release; real low-end device smoke tests required before shipping. (PITFALL 4)

## Session Continuity

Last session: 2025-01-14 (roadmap initialization)
Stopped at: Roadmap and requirements defined; Phase 1 ready to plan
Resume file: None
