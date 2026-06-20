# Roadmap: RedClass (红课复习)

## Overview

RedClass is built for **2 desktop platforms** (Windows / Linux) from a single Flutter codebase. The entire app runs on desktop — LLM parsing, quiz, JSON export/import, and all review modes are desktop-only.

> **Platform scope rationale**: v1 ships artifacts for Windows + Linux only. Mobile (Android) was dropped from v1 scope (see PROJECT.md decision). iOS and macOS source code compiles (Flutter handles both), but no distributable is produced — the developer currently lacks a macOS host and Apple Developer account.

Phases execute bottom-up: stable Flutter + SQLite foundation → read-only file import → desktop LLM integration → three-mode wrong-question ledger → JSON export/import → multiple-choice + bookmarks + stats → UX polish + diagnostics → desktop packaging + verification. By Phase 7 the user can install on Windows or Linux, drop a teacher's `.docx`, and study within minutes — all offline.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Foundation & Persistence** - Flutter project skeleton (3 v1 platforms + iOS/macOS source support), drift schema, go_router, Material 3 theme, PathResolver
- [x] **Phase 2: Desktop File Import Pipeline** - `.docx`/`.pdf` text extraction + heuristic parser + import preview screen (desktop-only entry points)
- [x] **Phase 3: Desktop LLM Integration** - `LlmClient` abstraction (Stub + HTTP), model picker, GBNF-constrained JSON parsing — **desktop-only**, gated on `Platform.isWindows || Platform.isLinux` (completed 2026-06-19)
- [x] **Phase 4: Quiz Core & Wrong-Question Ledger** - Quiz screen, single-choice grading, three review modes, shared ledger state machine (desktop) (completed 2026-06-20)
- [ ] **Phase 5: JSON Export/Import + Multiple-Choice + Statistics** - JSON export/import (desktop), multi-choice exact-match grading, per-bank statistics (bookmarks moved out)
- [ ] **Phase 6: UX Polish & Diagnostics** - UI alignment with ui-ux-pro-max, session state recovery, diagnostic-pack export (desktop)
- [ ] **Phase 7: Desktop Packaging & Verification** - Windows + Linux builds, on-device LLM validation on real desktop hardware

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
**Plans**: 4 plans (1 implementation + 3 gap closure)


### Phase 3: Desktop LLM Integration & Parse Quality
**Goal**: Replace the heuristic parser with an on-device LLM-driven parser via a swappable `LlmClient` abstraction. Desktop-only; Android's `LlmClient` provider is stubbed to throw `UnsupportedError`. Ship Stub + HTTP implementations first; FFI binding evaluated as a spike.
**Depends on**: Phase 2
**Requirements**: IMP-03, IMP-04
**Success Criteria** (what must be TRUE):
  1. `LlmClient` abstract interface exists with at least two implementations: `StubLlmClient` (canned fixture for dev/CI) and `HttpLlmClient` (POST to local llama.cpp server)
  2. `LlmClient` Riverpod provider is **gated on `Platform.isWindows || Platform.isLinux`** -- on Android the provider throws `UnsupportedError("LLM is desktop-only; use JSON import on Android")`
  3. Switching `llmModeProvider` in Riverpod overrides swaps the implementation on desktop without touching parse pipeline code
  4. Model picker UI shows "Recommended / Fast / Experimental" tiers with Qwen2.5-1.5B Q4_K_M as default
  5. GBNF grammar constrains LLM output to the question JSON schema; malformed JSON is rejected at parse layer
  6. Same raw text parsed 10 times produces byte-identical output (temperature=0 + fixed seed)
  7. Single-chunk LLM failures don't abort the whole import -- they're logged to `parse_log` and reported on the summary screen
**Plans**: 5 plans (in 4 waves) in 4 waves (plus 1 independent FFI spike)

**UI hint**: yes (model picker screen, settings entry for LLM mode -- desktop only)
**Research flag**: **HIGH** -- Phase 3 genuinely needs a 1-week FFI spike before detailed planning; plan with a fallback (HTTP-only) if the spike fails
**Pitfalls addressed**: PITFALL 1 (LLM JSON drift -- GBNF + canonicalization + multi-layer parser), PITFALL 4 (desktop OOM -- capability probe, lazy model load, n_ctx=1024)
**Dependencies**: Phase 2 (preview screen, parse pipeline already exists -- LLM slots in via `LlmClient`)

### Phase 4: Quiz Core & Wrong-Question Ledger
**Goal**: Ship a runnable quiz loop with single-choice questions, all three review modes wired to a shared wrong-question ledger via an atomic state machine. Desktop-only (Windows/Linux).
**Depends on**: Phase 3
**Requirements**: QST-01, REV-01, REV-02, REV-03, REV-04, REV-05, REV-06, STAT-01, UI-03
**Success Criteria** (what must be TRUE):
  1. User can enter 乱序抽题 on desktop (Windows/Linux), see a randomly drawn single-choice question, submit an answer, and get immediate correct/incorrect feedback
  2. Answering incorrectly in 乱序抽题 mode adds the question to the wrong-question ledger (visible in stats)
  3. 错题复习 mode shows only ledger entries; answering correctly marks the question 已掌握 and removes it from the ledger
  4. 错题抽查 mode draws N random questions from the ledger; a question that was just marked 已掌握 never appears in subsequent spot-checks
  5. Every ledger transition (markWrong / markMastered) is wrapped in a single SQLite transaction; killing the app mid-write leaves the DB consistent
  6. Each answer attempt writes to `answer_attempts` table with timestamp, elapsed time, mode, and correctness (STAT-01)
**Plans**: 5 plans (in 4 waves)
Plans:
- [x] 04-01-PLAN.md — LedgerRepository + Quiz models + Reactive providers + shared_preferences init (Wave 1)
- [x] 04-02-PLAN.md — QuizSessionController (AsyncNotifier parameterized by bankId+mode) (Wave 2)
- [x] 04-03-PLAN.md — Quiz widgets (OptionCard, ProgressBar, KeyboardHint, WrongQuestionChip) + QuizScreen (Wave 3)
- [x] 04-04-PLAN.md — BankPickerScreen + QuizSummaryScreen + GoRouter routes + redirect guards (Wave 3)
- [x] 04-05-PLAN.md — HomeScreen wrong-count badge + SettingsScreen quiz settings toggles (Wave 4)

**UI hint**: yes (quiz screen, results feedback, all three mode entry points)
**Research flag**: no (state machine pattern is standard; ledger design is straightforward given the data model from Phase 1)
**Pitfalls addressed**: PITFALL 2 (state machine non-atomic — single repo method per transition in DB transaction), PITFALL 5 (answer stringification — store as canonical sets from day 1), PITFALL 7 (lifecycle — commit on every answer)
**Dependencies**: Phase 3 (LLM-parsed questions already in DB), Phase 1 (ledger table + migrations)

### Phase 5: JSON Export/Import + Multiple-Choice + Statistics
**Goal**: Layer in JSON export and JSON import as the desktop-to-desktop transfer protocol. Add multiple-choice exact-match grading and per-bank statistics with per-mode breakdown. Fix home screen to show real bank list.
**Depends on**: Phase 4
**Requirements**: IMP-06, IMP-07, QST-02, STAT-02
**Success Criteria** (what must be TRUE):
  1. Desktop user can click "导出 JSON" in bank detail page and get a `.json` file matching the established format
  2. Desktop user can import a previously-exported `.json` and get a fully functional bank (questions + correct answers + metadata)
  3. JSON round-trip preserves all question data: stem, options, correct-answer keys, question type, bank name, version
  4. User sees multiple-choice questions rendered as checkboxes; submitting requires exact-match to score (all correct + no extras = correct)
  5. Stats screen shows per-bank aggregation: total questions, attempts, correct rate, and ledger size
  6. Per-mode breakdown is visible in stats (e.g., 乱序抽题: 78% / 错题复习: 92%)
  7. Home screen shows real bank list (not placeholder); tapping a bank card opens bank detail page
**Plans**: 6 plans
Plans:
- [ ] 05-01-PLAN.md -- JSON export service (DB <-> user format bidirectional converter) + unit tests
- [ ] 05-02-PLAN.md -- BankDetailScreen (bank info card + export button + review entry) + widget tests
- [ ] 05-03-PLAN.md -- JSON import fast-track (ImportNotifier.importJsonFile) + unit tests
- [ ] 05-04-PLAN.md -- Multi-choice grading test verification (extend quiz_session_controller_test)
- [ ] 05-05-PLAN.md -- Statistics provider + StatsScreen (expandable per-bank cards + per-mode breakdown) + tests
- [ ] 05-06-PLAN.md -- Home screen bank list (replace placeholder with real BankCard widgets) + widget tests

**Research flag**: no (JSON spec design is internal; round-trip test pattern is standard)
**Pitfalls addressed**: PITFALL 5 (answer stringification — multi-choice stored as canonical set from day 1)
**Dependencies**: Phase 4 (quiz loop exists, answer attempt logging exists)

### Phase 6: UX Polish & Diagnostics
**Goal**: Production-readiness layer — UI consistency with ui-ux-pro-max, session state recovery on launch, and bug-replay infrastructure for a closed-source + offline desktop app.
**Depends on**: Phase 5
**Requirements**: UI-01
**Success Criteria** (what must be TRUE):
  1. UI is visually consistent with `ui-ux-pro-max` reference (typography, color, spacing, focus mode) on Windows and Linux
  2. Killing the app mid-quiz and reopening restores the user to the same bank, mode, and question
  3. "Export diagnostic pack" action produces a zip containing parse log (last 50), app version, OS info, and DB (sanitized) for offline bug reports
  4. Every screen has explicit empty / loading / error states
  5. Settings screen exposes: theme, model picker, LLM mode, parse quality toggle
**Plans**: 5 plans

**Dependencies**: Phase 5 (all features exist; this is the polish + recovery layer)

### Phase 7: Desktop Packaging & Verification
**Goal**: Produce shippable Windows + Linux artifacts; validate on-device LLM behavior on real desktop hardware.
**Depends on**: Phase 6
**Requirements**: PLT-01, PLT-02
**Success Criteria** (what must be TRUE):
  1. `flutter build windows --release` produces a portable `.exe` that runs without Visual Studio installed
  2. `flutter build linux --release` produces a portable executable + `.AppImage`
  3. Desktop on-device LLM validation (Windows + Linux real machines, capability probe, model picker)
  4. JSON round-trip smoke test: export from Windows/Linux → import on Windows/Linux → quiz flow works
  5. README documents install steps for Windows / Linux, model download flow, JSON transfer workflow, and troubleshooting section
**Plans**: 5 plans

**Dependencies**: Phase 6 (production-ready app, all features complete)

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5 → 6 → 7

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation & Persistence | 7/7 | Complete | ✅ |
| 2. Desktop File Import Pipeline | 4/4 | Complete | ✅ R2 verified: 66/66 tests, 0e0w |
| 3. Desktop LLM Integration | 8/8 | Complete | 2026-06-19 |
| 4. Quiz Core & Wrong-Question Ledger | 5/5 | Complete | ✅ 2026-06-20 |
| 5. JSON Export/Import + Multiple-Choice + Statistics | 0/6 | Context gathered | - |
| 6. UX Polish & Diagnostics | 0/5 | Not started | - |
| 7. Desktop Packaging & Verification | 0/5 | Not started | - |

**Summary:**
- Total phases: 7
- Total estimated plans: 40 across all phases (was 53 before mobile scope cut; 1 dropped with bookmarks)
- v1 platforms (distributable artifacts): 2 (Windows / Linux)
- Platform scope cut: Android dropped from v1 (see PROJECT.md decision)
- Phases with research flag: 2 (Phase 2 — docx samples; Phase 3 — LLM FFI spike)
