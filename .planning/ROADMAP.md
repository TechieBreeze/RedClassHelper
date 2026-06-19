# Roadmap: RedClass (红课复习)

## Overview

RedClass is built bottom-up: a stable Flutter + SQLite foundation first, then read-only file import (proves the pipeline end-to-end before LLM complexity), then local LLM integration (the core differentiator), then the three-mode wrong-question ledger (the heart of the product), then bookmarks and statistics, then UX polish + diagnostics, finally Windows + Android packaging. The order is deliberate — every phase produces a runnable app, and every phase mitigates a specific pitfall documented in PITFALLS.md. By Phase 7 the user can install a `.exe` and `.apk`, drop a teacher's `.docx` in, and start studying within minutes.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Foundation & Persistence** - Flutter project skeleton, drift schema, go_router, Material 3 theme, PathResolver
- [ ] **Phase 2: File Import Pipeline (Read-Only)** - `.docx`/`.pdf` text extraction + heuristic parser + import preview screen
- [ ] **Phase 3: LLM Integration** - `LlmClient` abstraction (Stub + HTTP), model picker, GBNF-constrained JSON parsing
- [ ] **Phase 4: Quiz Core & Wrong-Question Ledger** - Quiz screen, single-choice grading, three review modes, shared ledger state machine
- [ ] **Phase 5: Multiple-Choice, Bookmarks & Statistics** - Multi-choice rendering, bookmark list, stats screen with per-bank aggregation
- [ ] **Phase 6: UX Polish & Diagnostics** - UI alignment with ui-ux-pro-max, state recovery, diagnostic-pack export
- [ ] **Phase 7: Packaging & Cross-Platform Verification** - Windows `.exe` + Android `.apk` builds, real-device LLM tuning

## Phase Details

### Phase 1: Foundation & Persistence
**Goal**: Bootstrap a runnable Flutter desktop+Android app with a stable drift schema, cross-platform path resolution, and a navigation skeleton that the rest of the project will build on.
**Depends on**: Nothing (first phase)
**Requirements**: IMP-05, STOR-01, STOR-02, PLT-03, PLT-04, UI-02
**Success Criteria** (what must be TRUE):
  1. `flutter run -d windows` and `flutter run -d <android>` both launch a Material 3 home screen with placeholder bank list and three review-mode entries
  2. drift database initializes at `getApplicationSupportDirectory()/redclass.db` on both platforms and survives app restart
  3. Schema migration scaffolding exists (version 1 baseline + `onUpgrade` chain) so future schema changes won't lose data
  4. `PathResolver` is the single source of truth for db, model, and import paths; no other file in the repo calls `path_provider` directly
  5. go_router routes exist for: `/` (home), `/bank/:id` (bank detail), `/quiz/:bankId/:mode` (quiz), `/stats`, `/bookmarks`, `/import`
**Plans**: TBD (estimated 4-6 plans for "standard" granularity)

Plans:
- [ ] 01-01: Create Flutter project (`flutter create --platforms=windows,android`) + pubspec deps
- [ ] 01-02: drift schema (QuestionBank / Question / AnswerAttempt / WrongLedger / Bookmark / ParseJob) + migrations
- [ ] 01-03: PathResolver + database provider wiring + PathResolver unit tests
- [ ] 01-04: go_router config + placeholder screens for all routes
- [ ] 01-05: Material 3 theme baseline (per ui-ux-pro-max) + home screen layout

**UI hint**: yes (Material 3 home screen, placeholder routes)
**Research flag**: no (standard Flutter + drift setup)
**Pitfalls addressed**: PITFALL 3 (SQLite FFI platform quirks — get PathResolver right from day 1), PITFALL 7 (lifecycle — state commit on every write baked in)
**Dependencies**: none (first phase)

### Phase 2: File Import Pipeline (Read-Only)
**Goal**: User can pick a `.docx` or `.pdf` from local filesystem, app extracts plain text and parses questions via a heuristic/regex parser, then shows a preview screen where the user can edit/delete before committing to the database.
**Depends on**: Phase 1
**Requirements**: IMP-01, IMP-02, IMP-04, QST-03
**Success Criteria** (what must be TRUE):
  1. User clicks "导入题库" on home screen, picks a `.docx` or `.pdf`, and sees a progress screen within 1 second
  2. Heuristic parser extracts questions with ~70% accuracy on real Chinese university `.docx` samples; failures are listed on the import summary screen
  3. Import preview screen shows all extracted questions with edit/delete affordances before any DB commit
  4. Parse runs in a background isolate — UI never blocks for more than one frame during a 50k-character import
  5. Single-choice vs multiple-choice question type is correctly detected and labeled in the preview
**Plans**: TBD (estimated 5-7 plans for "standard" granularity)

Plans:
- [ ] 02-01: `file_picker` integration + PDFium/post-install steps for Windows
- [ ] 02-02: `archive` + `xml` docx walker with unit tests against real Chinese `.docx` samples
- [ ] 02-03: `pdfx` text extraction (text-layer PDFs only; explicit error for scanned PDFs)
- [ ] 02-04: Heuristic regex parser (numbered stems, `A./B./C./D.` options, `答案:` markers)
- [ ] 02-05: Isolate-based parse job with progress + cancel + `parse_job` row in DB
- [ ] 02-06: Import preview/edit screen with bulk accept and per-row correction
- [ ] 02-07: Import summary screen (success count, skipped list, retry individual chunks)

**UI hint**: yes (import picker, progress, preview, summary screens)
**Research flag**: **HIGH** — needs validation against real Chinese university `.docx` files during planning; pull 3-5 sample files before locking plan
**Pitfalls addressed**: PITFALL 6 (stem fragmentation — chunking strategy baked in early), PITFALL 1 (LLM JSON drift — heuristic parser is a deterministic fallback), PITFALL 7 (lifecycle — DB commit only after user confirms in preview)
**Dependencies**: Phase 1 (drift schema, PathResolver, go_router routes)

### Phase 3: LLM Integration & Parse Quality
**Goal**: Replace the heuristic parser with an on-device LLM-driven parser via a swappable `LlmClient` abstraction. Ship Stub + HTTP implementations first; FFI binding evaluated as a spike.
**Depends on**: Phase 2
**Requirements**: IMP-03
**Success Criteria** (what must be TRUE):
  1. `LlmClient` abstract interface exists with at least two implementations: `StubLlmClient` (canned fixture for dev/CI) and `HttpLlmClient` (POST to local llama.cpp server)
  2. Switching `llmModeProvider` in Riverpod overrides swaps the implementation without touching parse pipeline code
  3. Model picker UI shows "Recommended / Fast / Experimental" tiers with Qwen2.5-1.5B Q4_K_M as default
  4. GBNF grammar constrains LLM output to the question JSON schema; malformed JSON is rejected at parse layer
  5. Same raw text parsed 10 times produces byte-identical output (temperature=0 + fixed seed)
  6. Single-chunk LLM failures don't abort the whole import — they're logged to `parse_log` and reported on the summary screen
**Plans**: TBD (estimated 5-7 plans for "standard" granularity)

Plans:
- [ ] 03-01: `LlmClient` abstract interface + Riverpod provider + mode switcher
- [ ] 03-02: `StubLlmClient` reading from `assets/fixtures/sample.json` + fixture authoring
- [ ] 03-03: `HttpLlmClient` with retry + timeout + structured error mapping
- [ ] 03-04: GBNF grammar file for question JSON schema + parser-layer integration
- [ ] 03-05: Canonicalization layer (`"AB"` / `"A,B"` / `"A和B"` → `["A","B"]`)
- [ ] 03-06: Model picker UI + GGUF download flow with resume
- [ ] 03-07: **Research spike** (1 week): prototype llama.cpp FFI shim on Windows + low-end Android; go/no-go decision
- [ ] 03-08: `FfiLlmClient` (if spike succeeds) or document HTTP-only fallback (if it doesn't)

**UI hint**: yes (model picker screen, settings entry for LLM mode)
**Research flag**: **HIGH** — Phase 3 genuinely needs a 1-week FFI spike before detailed planning; plan with a fallback (HTTP-only) if the spike fails
**Pitfalls addressed**: PITFALL 1 (LLM JSON drift — GBNF + canonicalization + multi-layer parser), PITFALL 4 (Android OOM — capability probe, lazy model load, n_ctx=1024)
**Dependencies**: Phase 2 (preview screen, parse pipeline already exists — LLM slots in via `LlmClient`)

### Phase 4: Quiz Core & Wrong-Question Ledger
**Goal**: Ship a runnable quiz loop with single-choice questions, all three review modes wired to a shared wrong-question ledger via an atomic state machine.
**Depends on**: Phase 3
**Requirements**: QST-01, REV-01, REV-02, REV-03, REV-04, REV-05, REV-06, STAT-01, UI-03
**Success Criteria** (what must be TRUE):
  1. User can enter 乱序抽题, see a randomly drawn single-choice question, submit an answer, and get immediate correct/incorrect feedback
  2. Answering incorrectly in 乱序抽题 mode adds the question to the wrong-question ledger (visible in stats)
  3. 错题复习 mode shows only ledger entries; answering correctly marks the question 已掌握 and removes it from the ledger
  4. 错题抽查 mode draws N random questions from the ledger; a question that was just marked 已掌握 never appears in subsequent spot-checks
  5. Every ledger transition (markWrong / markMastered) is wrapped in a single SQLite transaction; killing the app mid-write leaves the DB consistent
  6. Each answer attempt writes to `answer_attempts` table with timestamp, elapsed time, mode, and correctness (STAT-01)
**Plans**: TBD (estimated 6-8 plans for "standard" granularity)

Plans:
- [ ] 04-01: Quiz screen widget (reusable across 3 modes) with single-choice rendering
- [ ] 04-02: `QuizSessionController` (`AsyncNotifier` parameterized by `ReviewMode`)
- [ ] 04-03: `LedgerRepository` with `upsertWrong` / `markMastered` wrapped in DB transactions
- [ ] 04-04: `wrongQuestionsProvider` (`StreamProvider`) + invalidation on ledger writes
- [ ] 04-05: 乱序抽题 mode wired end-to-end (random draw → submit → grade → ledger)
- [ ] 04-06: 错题复习 mode wired (ledger → answer correctly → markMastered → remove)
- [ ] 04-07: 错题抽查 mode wired (sample from unmastered ledger → no write to ledger)
- [ ] 04-08: Answer attempt logging + single-choice grading unit tests

**UI hint**: yes (quiz screen, results feedback, all three mode entry points)
**Research flag**: no (state machine pattern is standard; ledger design is straightforward given the data model from Phase 1)
**Pitfalls addressed**: PITFALL 2 (state machine non-atomic — single repo method per transition in DB transaction), PITFALL 5 (answer stringification — store as canonical sets from day 1), PITFALL 7 (lifecycle — commit on every answer)
**Dependencies**: Phase 3 (LLM-parsed questions already in DB), Phase 1 (ledger table + migrations)

### Phase 5: Multiple-Choice, Bookmarks & Statistics
**Goal**: Layer in the remaining table-stakes features: multiple-choice rendering/grading, bookmark add/remove + list screen, and a stats screen with per-bank aggregation.
**Depends on**: Phase 4
**Requirements**: QST-02, BMK-01, BMK-02, STAT-02
**Success Criteria** (what must be TRUE):
  1. User sees multiple-choice questions rendered as checkboxes; submitting requires exact-match to score (partial selection = wrong)
  2. User can tap a star icon on any question to bookmark it; bookmarked questions appear in a dedicated list screen
  3. Stats screen shows per-bank aggregation: total questions, attempts, correct rate, and ledger size
  4. Per-mode breakdown is visible in stats (e.g., 乱序抽题: 78% / 错题复习: 92%)
  5. Bookmark list can be re-entered as a study session (filter `乱序抽题` by bookmarked set)
**Plans**: TBD (estimated 4-6 plans for "standard" granularity)

Plans:
- [ ] 05-01: Multiple-choice rendering (checkbox group) + exact-match grading
- [ ] 05-02: `BookmarkRepository` + bookmark toggle in quiz screen
- [ ] 05-03: Bookmark list screen + filter integration with 乱序抽题
- [ ] 05-04: Stats screen with per-bank + per-mode aggregation queries
- [ ] 05-05: Answer-time tracking (Stopwatch per question) surfacing in stats
- [ ] 05-06: Ledger screen showing current wrong-question set (read-only view of `wrongQuestionsProvider`)

**UI hint**: yes (multiple-choice UI, bookmark list, stats screen, ledger screen)
**Research flag**: no (straightforward extensions of Phase 4 patterns)
**Pitfalls addressed**: PITFALL 5 (answer stringification — multi-choice stored as canonical set from day 1)
**Dependencies**: Phase 4 (quiz loop exists, answer attempt logging exists)

### Phase 6: UX Polish & Diagnostics
**Goal**: Production-readiness layer — UI consistency with ui-ux-pro-max, session state recovery on launch, and bug-replay infrastructure for a closed-source + offline app.
**Depends on**: Phase 5
**Requirements**: UI-01
**Success Criteria** (what must be TRUE):
  1. UI is visually consistent with `ui-ux-pro-max` reference (typography, color, spacing, focus mode)
  2. Killing the app mid-quiz and reopening restores the user to the same bank, mode, and question
  3. "Export diagnostic pack" action produces a zip containing parse log (last 50), app version, OS info, and DB (sanitized) for offline bug reports
  4. Every screen has explicit empty / loading / error states
  5. Settings screen exposes: theme, model picker, LLM mode, parse quality toggle
**Plans**: TBD (estimated 4-6 plans for "standard" granularity)

Plans:
- [ ] 06-01: UI pass per ui-ux-pro-max (typography, color, spacing audit across all screens)
- [ ] 06-02: Empty / loading / error states for every screen (shared widgets)
- [ ] 06-03: Session state persistence (`shared_preferences` for last bank + mode + question)
- [ ] 06-04: `parse_log` table populated during imports; LRU retention at 200 rows
- [ ] 06-05: Diagnostic-pack export (zip with DB + log + version metadata)
- [ ] 06-06: Settings screen + first-run onboarding (model download prompt)

**UI hint**: yes (UX polish touches every screen; new settings screen)
**Research flag**: no
**Pitfalls addressed**: PITFALL 7 (lifecycle — session recovery on launch), PITFALL 8 (unreproducible bugs — diagnostic pack + parse_log)
**Dependencies**: Phase 5 (all features exist; this is the polish + recovery layer)

### Phase 7: Packaging & Cross-Platform Verification
**Goal**: Produce shippable Windows `.exe` and Android `.apk` artifacts; validate on-device LLM behavior on real low-end and high-end Android devices.
**Depends on**: Phase 6
**Requirements**: PLT-01, PLT-02
**Success Criteria** (what must be TRUE):
  1. `flutter build windows --release` produces a portable `.exe` that runs without Visual Studio installed
  2. `flutter build apk --split-per-abi` produces `arm64-v8a` (mandatory) and `x86_64` (optional) APKs
  3. APK install + first-run smoke test succeeds on a real 4 GB-RAM Android device without OOM
  4. APK install + first-run smoke test succeeds on a real 6–8 GB-RAM Android device
  5. README documents install steps for both platforms, model download flow, and a troubleshooting section for common issues (Windows SmartScreen, Android scoped storage)
**Plans**: TBD (estimated 3-5 plans for "standard" granularity)

Plans:
- [ ] 07-01: Windows release build + portable `.exe` packaging + SmartScreen notes
- [ ] 07-02: Android APK build with split-per-abi + signing config
- [ ] 07-03: On-device LLM validation on 4 GB device (capability probe, model picker)
- [ ] 07-04: On-device LLM validation on 6–8 GB device (higher-quant model option)
- [ ] 07-05: README with install steps, model download, troubleshooting

**UI hint**: no (build/CI work; no new screens)
**Research flag**: no
**Pitfalls addressed**: PITFALL 4 (Android OOM — real-device validation)
**Dependencies**: Phase 6 (production-ready app, all features complete)

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5 → 6 → 7

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation & Persistence | 0/5 | Not started | - |
| 2. File Import Pipeline (Read-Only) | 0/7 | Not started | - |
| 3. LLM Integration & Parse Quality | 0/8 | Not started | - |
| 4. Quiz Core & Wrong-Question Ledger | 0/8 | Not started | - |
| 5. Multiple-Choice, Bookmarks & Statistics | 0/6 | Not started | - |
| 6. UX Polish & Diagnostics | 0/6 | Not started | - |
| 7. Packaging & Cross-Platform Verification | 0/5 | Not started | - |

**Summary:**
- Total phases: 7
- Total v1 requirements: 27
- Coverage check: 27/27 mapped (100%) ✓
- Phases with research flag: 2 (Phase 2 — docx samples; Phase 3 — LLM FFI spike)
- Total estimated plans: 45 across all phases
