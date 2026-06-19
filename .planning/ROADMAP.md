# Roadmap: RedClass (红课复习)

## Overview

RedClass is built bottom-up across **3 platforms** (Windows / Linux / Android) from a single Flutter codebase. The architecture has one explicit platform branch: **LLM parsing is desktop-only** (Windows/Linux); **Android consumes JSON files exported from a desktop**. This is documented as an explicit decision in PROJECT.md and surfaced in the UI as a platform-conditional import page.

> **Platform scope rationale**: v1 ships artifacts for Windows + Linux + Android only. iOS and macOS source code compiles (Flutter handles both), but no distributable is produced — the developer currently lacks a macOS host and Apple Developer account. These targets can be added later by extending `flutter create --platforms` and adding build steps; no architectural changes required.

Phases execute bottom-up: stable Flutter + SQLite foundation → read-only file import → desktop-only LLM integration → three-mode wrong-question ledger → JSON export/import for cross-device transfer → multiple-choice + bookmarks + stats → UX polish + diagnostics → three-platform packaging + cross-platform verification. By Phase 7 the user can install on Windows, Linux, or Android, drop a teacher's `.docx` on a desktop, export JSON, sideload JSON to a phone, and study within minutes — all offline.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Foundation & Persistence** - Flutter project skeleton (3 v1 platforms + iOS/macOS source support), drift schema, go_router, Material 3 theme, PathResolver
- [ ] **Phase 2: Desktop File Import Pipeline** - `.docx`/`.pdf` text extraction + heuristic parser + import preview screen (desktop-only entry points)
- [ ] **Phase 3: Desktop LLM Integration** - `LlmClient` abstraction (Stub + HTTP), model picker, GBNF-constrained JSON parsing — **desktop-only**, gated on `Platform.isWindows || Platform.isLinux`
- [ ] **Phase 4: Quiz Core & Wrong-Question Ledger** - Quiz screen, single-choice grading, three review modes, shared ledger state machine
- [ ] **Phase 5: JSON Cross-Device Transfer + Multiple-Choice + Bookmarks + Statistics** - JSON export (desktop), JSON import (all 3 platforms), multi-choice, bookmarks, stats, **platform-conditional import UI**
- [ ] **Phase 6: UX Polish & Diagnostics** - UI alignment with ui-ux-pro-max, session state recovery, diagnostic-pack export
- [ ] **Phase 7: Three-Platform Packaging & Verification** - Windows + Linux + Android builds, real-device LLM tuning on desktop, real-device JSON import on Android

## Phase Details

### Phase 1: Foundation & Persistence
**Goal**: Bootstrap a runnable Flutter app on all 3 v1 platforms (+ iOS/macOS source support) with a stable drift schema, cross-platform path resolution, and a navigation skeleton.
**Depends on**: Nothing (first phase)
**Requirements**: IMP-05, STOR-01, STOR-02, PLT-04, PLT-05, UI-02
**Success Criteria** (what must be TRUE):
  1. `flutter run -d windows` and `flutter run -d linux` and `flutter run -d <android>` all launch a Material 3 home screen with placeholder bank list and three review-mode entries
  2. (Source-level) `flutter build ios --no-codesign --simulator` and `flutter build macos --debug` succeed without errors — code paths for iOS/macOS exist even though no distributable is produced
  3. drift database initializes at `getApplicationSupportDirectory()/redclass.db` on all 3 v1 platforms and survives app restart
  4. Schema migration scaffolding exists (version 1 baseline + `onUpgrade` chain) so future schema changes won't lose data
  5. `PathResolver` is the single source of truth for db, model, JSON-import, and JSON-export paths; no other file in the repo calls `path_provider` directly
  6. go_router routes exist for: `/` (home), `/bank/:id` (bank detail), `/quiz/:bankId/:mode` (quiz), `/stats`, `/bookmarks`, `/import`
**Plans**: 7 plans (1 toolchain + 6 implementation)

Plans:
- [x] 01-00: Toolchain bootstrap — Flutter 3.44.2 + Android SDK 35 + VS Build Tools 2026 installed; flutter doctor green for Flutter / Windows / Visual Studio / Connected device; Android toolchain recognized (SDK 35.0.0). End-to-end smoke test (flutter create --platforms=windows) passes.
- [x] 01-01: Create Flutter project (`flutter create --platforms=windows,linux,android,ios,macos`) + pubspec deps
- [x] 01-02: drift schema (QuestionBank / Question / AnswerAttempt / WrongLedger / Bookmark / ParseJob) + migrations
- [x] 01-03: PathResolver + database provider wiring + per-platform path tests
- [x] 01-04: go_router config + placeholder screens for all routes
- [x] 01-05: Material 3 theme baseline (per ui-ux-pro-max) + home screen layout
- [x] 01-06: Cross-platform smoke test (`flutter test` + manual run on each v1 platform)

**UI hint**: yes (Material 3 home screen, placeholder routes on all 3 v1 platforms)
**Research flag**: no (standard Flutter + drift setup)
**Pitfalls addressed**: PITFALL 3 (SQLite FFI platform quirks — get PathResolver right from day 1, includes Linux file permissions), PITFALL 7 (lifecycle — state commit on every write baked in)
**Dependencies**: none (first phase)

### Phase 2: Desktop File Import Pipeline
**Goal**: Desktop user can pick a `.docx` or `.pdf` from local filesystem, app extracts plain text and parses questions via a heuristic/regex parser, then shows a preview screen where the user can edit/delete before committing to the database. Android sees an import page stub but the `.docx`/`.pdf` entries are hidden.
**Depends on**: Phase 1
**Requirements**: IMP-01, IMP-02, IMP-04, QST-03, UI-04
**Success Criteria** (what must be TRUE):
  1. Desktop user clicks "导入题库" on home screen, picks a `.docx` or `.pdf`, and sees a progress screen within 1 second
  2. Heuristic parser extracts questions with ~70% accuracy on real Chinese university `.docx` samples; failures are listed on the import summary screen
  3. Import preview screen shows all extracted questions with edit/delete affordances before any DB commit
  4. Parse runs in a background isolate — UI never blocks for more than one frame during a 50k-character import
  5. Single-choice vs multiple-choice question type is correctly detected and labeled in the preview
  6. Android's import page renders the `.json`-only entry; `.docx`/`.pdf` buttons are not visible (gated on `Platform.isWindows || Platform.isLinux`)
**Plans**: 1 consolidated (02-00-PLAN.md) — 10 tasks covering all sub-areas below

Plans:
- [x] 02-00: Consolidated implementation plan — all 10 tasks (dependencies → extraction → parser → providers → 4 screens → FAB → routing → integration tests)
- [x] → 02-01: `file_picker` integration + PDFium/post-install steps for Windows
- [x] → 02-02: `archive` + `xml` docx walker with unit tests against real Chinese `.docx` samples
- [x] → 02-03: `pdfx` text extraction (text-layer PDFs only; explicit error for scanned PDFs)
- [x] → 02-04: Heuristic regex parser (numbered stems, `A./B./C./D.` options, `答案:` markers)
- [x] → 02-05: Isolate-based parse job with progress + cancel
- [x] → 02-06: Import preview/edit screen with bulk accept and per-row correction
- [x] → 02-07: Import summary screen (success count, skipped list, retry individual chunks)
- [x] → 02-08: Platform-conditional import page UI (desktop: `.docx`/`.pdf`/`.json`; Android: `.json` only)

**UI hint**: yes (import picker, progress, preview, summary screens; platform-branched entry)
**Research flag**: **HIGH** — needs validation against real Chinese university `.docx` files during planning; pull 3-5 sample files before locking plan
**Pitfalls addressed**: PITFALL 6 (stem fragmentation — chunking strategy baked in early), PITFALL 1 (LLM JSON drift — heuristic parser is a deterministic fallback), PITFALL 7 (lifecycle — DB commit only after user confirms in preview)
**Dependencies**: Phase 1 (drift schema, PathResolver, go_router routes)

### Phase 3: Desktop LLM Integration & Parse Quality
**Goal**: Replace the heuristic parser with an on-device LLM-driven parser via a swappable `LlmClient` abstraction. Desktop-only; Android's `LlmClient` provider is stubbed to throw `UnsupportedError`. Ship Stub + HTTP implementations first; FFI binding evaluated as a spike.
**Depends on**: Phase 2
**Requirements**: IMP-03
**Success Criteria** (what must be TRUE):
  1. `LlmClient` abstract interface exists with at least two implementations: `StubLlmClient` (canned fixture for dev/CI) and `HttpLlmClient` (POST to local llama.cpp server)
  2. `LlmClient` Riverpod provider is **gated on `Platform.isWindows || Platform.isLinux`** — on Android the provider throws `UnsupportedError("LLM is desktop-only; use JSON import on Android")`
  3. Switching `llmModeProvider` in Riverpod overrides swaps the implementation on desktop without touching parse pipeline code
  4. Model picker UI shows "Recommended / Fast / Experimental" tiers with Qwen2.5-1.5B Q4_K_M as default
  5. GBNF grammar constrains LLM output to the question JSON schema; malformed JSON is rejected at parse layer
  6. Same raw text parsed 10 times produces byte-identical output (temperature=0 + fixed seed)
  7. Single-chunk LLM failures don't abort the whole import — they're logged to `parse_log` and reported on the summary screen
**Plans**: TBD (estimated 6-8 plans for "standard" granularity)

Plans:
- [ ] 03-01: `LlmClient` abstract interface + platform-conditional Riverpod provider (desktop-only)
- [ ] 03-02: `StubLlmClient` reading from `assets/fixtures/sample.json` + fixture authoring
- [ ] 03-03: `HttpLlmClient` with retry + timeout + structured error mapping
- [ ] 03-04: GBNF grammar file for question JSON schema + parser-layer integration
- [ ] 03-05: Canonicalization layer (`"AB"` / `"A,B"` / `"A和B"` → `["A","B"]`)
- [ ] 03-06: Model picker UI + GGUF download flow with resume (desktop only)
- [ ] 03-07: **Research spike** (1 week): prototype llama.cpp FFI shim on Windows + Linux; go/no-go decision
- [ ] 03-08: `FfiLlmClient` (if spike succeeds) or document HTTP-only fallback (if it doesn't)

**UI hint**: yes (model picker screen, settings entry for LLM mode — desktop only)
**Research flag**: **HIGH** — Phase 3 genuinely needs a 1-week FFI spike before detailed planning; plan with a fallback (HTTP-only) if the spike fails
**Pitfalls addressed**: PITFALL 1 (LLM JSON drift — GBNF + canonicalization + multi-layer parser), PITFALL 4 (desktop OOM — capability probe, lazy model load, n_ctx=1024)
**Dependencies**: Phase 2 (preview screen, parse pipeline already exists — LLM slots in via `LlmClient`)

### Phase 4: Quiz Core & Wrong-Question Ledger
**Goal**: Ship a runnable quiz loop with single-choice questions, all three review modes wired to a shared wrong-question ledger via an atomic state machine. Platform-agnostic — works identically on all 3 v1 platforms once questions are loaded.
**Depends on**: Phase 3
**Requirements**: QST-01, REV-01, REV-02, REV-03, REV-04, REV-05, REV-06, STAT-01, UI-03
**Success Criteria** (what must be TRUE):
  1. User can enter 乱序抽题 on any of the 3 v1 platforms, see a randomly drawn single-choice question, submit an answer, and get immediate correct/incorrect feedback
  2. Answering incorrectly in 乱序抽题 mode adds the question to the wrong-question ledger (visible in stats)
  3. 错题复习 mode shows only ledger entries; answering correctly marks the question 已掌握 and removes it from the ledger
  4. 错题抽查 mode draws N random questions from the ledger; a question that was just marked 已掌握 never appears in subsequent spot-checks
  5. Every ledger transition (markWrong / markMastered) is wrapped in a single SQLite transaction; killing the app mid-write leaves the DB consistent
  6. Each answer attempt writes to `answer_attempts` table with timestamp, elapsed time, mode, and correctness (STAT-01)
**Plans**: TBD (estimated 6-9 plans for "standard" granularity)

Plans:
- [ ] 04-01: Quiz screen widget (reusable across 3 modes) with single-choice rendering, touch-friendly hit areas
- [ ] 04-02: `QuizSessionController` (`AsyncNotifier` parameterized by `ReviewMode`)
- [ ] 04-03: `LedgerRepository` with `upsertWrong` / `markMastered` wrapped in DB transactions
- [ ] 04-04: `wrongQuestionsProvider` (`StreamProvider`) + invalidation on ledger writes
- [ ] 04-05: 乱序抽题 mode wired end-to-end (random draw → submit → grade → ledger)
- [ ] 04-06: 错题复习 mode wired (ledger → answer correctly → markMastered → remove)
- [ ] 04-07: 错题抽查 mode wired (sample from unmastered ledger → no write to ledger)
- [ ] 04-08: Answer attempt logging + single-choice grading unit tests
- [ ] 04-09: Cross-platform smoke test of quiz loop on all 3 v1 platforms

**UI hint**: yes (quiz screen, results feedback, all three mode entry points)
**Research flag**: no (state machine pattern is standard; ledger design is straightforward given the data model from Phase 1)
**Pitfalls addressed**: PITFALL 2 (state machine non-atomic — single repo method per transition in DB transaction), PITFALL 5 (answer stringification — store as canonical sets from day 1), PITFALL 7 (lifecycle — commit on every answer)
**Dependencies**: Phase 3 (LLM-parsed questions already in DB), Phase 1 (ledger table + migrations)

### Phase 5: JSON Cross-Device Transfer + Multiple-Choice + Bookmarks + Statistics
**Goal**: Layer in JSON export (desktop) and JSON import (all 3 platforms) as the cross-device transfer protocol. Add remaining table-stakes features: multiple-choice rendering/grading, bookmarks, statistics with per-bank aggregation.
**Depends on**: Phase 4
**Requirements**: IMP-06, IMP-07, PLT-06, QST-02, BMK-01, BMK-02, STAT-02
**Success Criteria** (what must be TRUE):
  1. Desktop user can right-click (or menu-action) any question bank and export it as a single `.json` file matching the public format spec in `doc/question-bank-json.md`
  2. Any of the 3 v1 platforms can import a previously-exported `.json` and get a fully functional bank (questions + correct answers + metadata)
  3. JSON round-trip preserves all question data: stem, options, correct-answer sets, question type, source bank name, version
  4. User sees multiple-choice questions rendered as checkboxes; submitting requires exact-match to score (partial selection = wrong)
  5. User can tap a star icon on any question to bookmark it; bookmarked questions appear in a dedicated list screen
  6. Stats screen shows per-bank aggregation: total questions, attempts, correct rate, and ledger size
  7. Per-mode breakdown is visible in stats (e.g., 乱序抽题: 78% / 错题复习: 92%)
  8. Bookmark list can be re-entered as a study session (filter `乱序抽题` by bookmarked set)
**Plans**: TBD (estimated 6-9 plans for "standard" granularity)

Plans:
- [ ] 05-01: Define public JSON schema in `doc/question-bank-json.md` (versioned, with example + validation rules)
- [ ] 05-02: `JsonExporter` (desktop) — emits standard JSON from a `QuestionBank` + its `Question` set
- [ ] 05-03: `JsonImporter` (all 3 platforms) — parses JSON, validates against schema, creates new `QuestionBank` + `Question` rows
- [ ] 05-04: JSON round-trip integration test (export → import → compare)
- [ ] 05-05: Multiple-choice rendering (checkbox group) + exact-match grading
- [ ] 05-06: `BookmarkRepository` + bookmark toggle in quiz screen
- [ ] 05-07: Bookmark list screen + filter integration with 乱序抽题
- [ ] 05-08: Stats screen with per-bank + per-mode aggregation queries
- [ ] 05-09: Export action in bank detail screen (desktop) + platform-conditional UI affordance

**UI hint**: yes (JSON import/export actions, multiple-choice UI, bookmark list, stats screen)
**Research flag**: no (JSON spec design is internal; round-trip test pattern is standard)
**Pitfalls addressed**: PITFALL 5 (answer stringification — multi-choice stored as canonical set from day 1)
**Dependencies**: Phase 4 (quiz loop exists, answer attempt logging exists)

### Phase 6: UX Polish & Diagnostics
**Goal**: Production-readiness layer — UI consistency with ui-ux-pro-max, session state recovery on launch, and bug-replay infrastructure for a closed-source + offline app.
**Depends on**: Phase 5
**Requirements**: UI-01
**Success Criteria** (what must be TRUE):
  1. UI is visually consistent with `ui-ux-pro-max` reference (typography, color, spacing, focus mode) across all 3 v1 platforms
  2. Killing the app mid-quiz and reopening restores the user to the same bank, mode, and question (per-platform)
  3. "Export diagnostic pack" action produces a zip containing parse log (last 50), app version, OS info, and DB (sanitized) for offline bug reports
  4. Every screen has explicit empty / loading / error states
  5. Settings screen exposes: theme, model picker (desktop only), LLM mode (desktop only), parse quality toggle
**Plans**: TBD (estimated 4-6 plans for "standard" granularity)

Plans:
- [ ] 06-01: UI pass per ui-ux-pro-max (typography, color, spacing audit across all screens and platforms)
- [ ] 06-02: Empty / loading / error states for every screen (shared widgets)
- [ ] 06-03: Session state persistence (`shared_preferences` for last bank + mode + question)
- [ ] 06-04: `parse_log` table populated during imports; LRU retention at 200 rows
- [ ] 06-05: Diagnostic-pack export (zip with DB + log + version metadata)
- [ ] 06-06: Settings screen + first-run onboarding (model download prompt on desktop only)

**UI hint**: yes (UX polish touches every screen; new settings screen)
**Research flag**: no
**Pitfalls addressed**: PITFALL 7 (lifecycle — session recovery on launch), PITFALL 8 (unreproducible bugs — diagnostic pack + parse_log)
**Dependencies**: Phase 5 (all features exist; this is the polish + recovery layer)

### Phase 7: Three-Platform Packaging & Cross-Platform Verification
**Goal**: Produce shippable Windows + Linux + Android artifacts; validate on-device LLM behavior on real desktop hardware and JSON import flow on real Android hardware.
**Depends on**: Phase 6
**Requirements**: PLT-01, PLT-02, PLT-03
**Success Criteria** (what must be TRUE):
  1. `flutter build windows --release` produces a portable `.exe` that runs without Visual Studio installed
  2. `flutter build linux --release` produces a portable executable + `.AppImage`
  3. `flutter build apk --split-per-abi` produces `arm64-v8a` (mandatory) and `x86_64` (optional) APKs
  4. (Source-level) `flutter build ios --no-codesign --simulator` and `flutter build macos --debug` succeed without errors — confirming code paths compile for future v2 expansion
  5. JSON round-trip smoke test: export from Windows/Linux desktop → sideload to real Android device → import → quiz flow works
  6. Desktop on-device LLM validation (Windows + Linux real machines, capability probe, model picker)
  7. README documents install steps for Windows / Linux / Android, model download flow (desktop only), JSON transfer workflow, and troubleshooting section
**Plans**: TBD (estimated 5-7 plans for "standard" granularity)

Plans:
- [ ] 07-01: Windows release build + portable `.exe` packaging + SmartScreen notes
- [ ] 07-02: Linux release build + `.AppImage` + dependency notes (gtk-3, etc.)
- [ ] 07-03: Android APK build with split-per-abi + signing config
- [ ] 07-04: Source-level iOS / macOS build check (no codesign, simulator only)
- [ ] 07-05: Desktop on-device LLM validation (Windows + Linux, capability probe, model picker)
- [ ] 07-06: Android JSON-import validation (real device smoke tests)
- [ ] 07-07: README with install steps, JSON transfer workflow, model download (desktop), troubleshooting

**UI hint**: no (build/CI work; no new screens)
**Research flag**: no
**Pitfalls addressed**: PITFALL 4 (desktop OOM — real-device validation on Windows + Linux), cross-platform packaging gotchas
**Dependencies**: Phase 6 (production-ready app, all features complete)

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5 → 6 → 7

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation & Persistence | 7/7 | Complete | ✅ |
| 2. Desktop File Import Pipeline | 0/8 | Not started | - |
| 3. Desktop LLM Integration | 0/8 | Not started | - |
| 4. Quiz Core & Wrong-Question Ledger | 0/9 | Not started | - |
| 5. JSON Cross-Device Transfer + Multiple-Choice + Bookmarks + Statistics | 0/9 | Not started | - |
| 6. UX Polish & Diagnostics | 0/6 | Not started | - |
| 7. Three-Platform Packaging & Verification | 0/7 | Not started | - |

**Summary:**
- Total phases: 7
- Total v1 requirements: 31
- Coverage check: 31/31 mapped (100%) ✓
- Phases with research flag: 2 (Phase 2 — docx samples; Phase 3 — LLM FFI spike)
- Total estimated plans: 53 across all phases
- v1 platforms (distributable artifacts): 3 (Windows / Linux / Android)
- Source-level platforms: 5 (adds iOS / macOS compile-only support)
- Platform branches: 2 explicit (LLM desktop-only; JSON import all 3 platforms)
