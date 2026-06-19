# Project Research Summary

**Project:** RedClass (红课复习)
**Domain:** Local closed-source Flutter cross-platform (Windows + Android) university exam review tool with on-device LLM parsing
**Researched:** 2026-06-19
**Confidence:** MEDIUM-HIGH (HIGH on stack, MEDIUM on LLM-on-mobile + .docx parsing)

---

## Executive Summary

RedClass is a "bring your own question bank" tool — fundamentally different from apps like Anki, Quizlet, 小猿题库, 粉笔. Where competing tools either ship a built-in question library or require manual card creation, RedClass lets students drop in the `.docx`/`.pdf` file their teacher actually sent, and an on-device small LLM (Qwen2.5-1.5B-Instruct Q4_K_M) parses it into structured single/multiple-choice questions. From there, three review modes (乱序抽题 / 错题复习 / 错题抽查) share a wrong-question ledger that mirrors how students actually study: do random practice → hit a wall → review the mistakes → spot-check the ones still shaky.

The recommended stack is **Flutter 3.35.7 + drift + Riverpod + llama.cpp FFI + pdfx/archive**. The architecture has one critical seam — an abstract `LlmClient` interface that can swap between a stub (for tests/dev), an HTTP call to a local llama-server, and an in-process llama.cpp FFI binding. Three review modes share the wrong-question ledger through a single `AsyncNotifier` exposing reactive streams.

The biggest risks are: (a) Android RAM constraints making on-device LLM fragile on 4 GB phones, mitigated by a "Recommended / Fast / Experimental" model picker and downloadable GGUF (not bundled); (b) LLM JSON output drift on messy Chinese exam formatting, mitigated by GBNF grammar + canonicalization + a mandatory post-parse preview/edit screen; (c) no mature Dart `.docx` reader, mitigated by `archive` + `xml` walking WordprocessingML. The .docx parsing risk is genuine — there is no silver-bullet package as of mid-2026.

---

## Key Findings

### Recommended Stack

**Core technologies:**
- **Flutter 3.35.7 stable** (Dart 3.9.2) — single codebase to Windows + Android; quarterly release cadence; first-class desktop target
- **`flutter_riverpod` 3.3.2 + `freezed` 3.x + `go_router` 17.3.0** — Riverpod's `AsyncNotifier` + `StreamProvider` are perfect for the wrong-question ledger; `freezed` gives discriminated unions for `QuestionType` / `ReviewMode` / `WrongQuestionState`
- **`drift` 2.34.0 + `sqlite3_flutter_libs`** — Flutter Favorite reactive SQLite ORM; cross-platform (Android + Windows); generated types catch schema mistakes at build time
- **`pdfx` 2.9.2** — PDF text extraction on Windows (PDFium) and Android (PdfRenderer); needs `flutter pub run pdfx:install_windows` after first install
- **`archive` 4.0.9 + `xml` 6.x** — the only realistic pure-Dart path for `.docx` (no mature dedicated package exists)
- **`llama.cpp` (b9717) via custom `dart:ffi` shim** — the only engine with prebuilt Windows + Android GGUF loaders; `flutter_llama` 1.1.2 doesn't support Windows so we write a thin FFI wrapper
- **Default model: Qwen2.5-1.5B-Instruct Q4_K_M** (~1.1 GB) for Android low-end; Q5_K_M or 3B Q4 on desktop

**The LLM story is the hardest part.** No maintained pub.dev wrapper covers both Windows + Android simultaneously. We accept ~1–2 weeks of FFI shim work, OR we fall back to `onnxruntime` 1.4.1 with a Qwen2.5-1.5B ONNX export (loses model-zoo flexibility but ~80% less custom code). Recommend a 1-week spike on the FFI shim before committing to architecture.

**Android is genuinely constrained.** A 4 GB phone cannot reliably run a 7B model even at Q4. Default to 1.5B; surface a model picker with "Recommended / Fast / Experimental" tiers. Download GGUF on first launch into `getApplicationDocumentsDirectory()/models/` rather than bundling (APK bloat).

**Honest caveats:**
- **`.docx` parsing confidence is MEDIUM** — `archive + xml` works but requires hand-rolling WordprocessingML traversal. Budget time for unit tests against real Chinese university `.docx` files.
- **LLM-on-Android confidence is MEDIUM** — feasible but no shortcut; budget the FFI spike.
- **Everything else is HIGH confidence** — Flutter, drift, Riverpod, go_router, file_picker, Material 3 are all well-documented Flutter Favorites or bundled.

### Expected Features

**Must have (table stakes — without these the app is unusable):**
- `.docx` + `.pdf` import via `file_picker`
- LLM parse with progress reporting + failure reasons (retry-able)
- SQLite persistence (`drift`)
- Single-choice + multiple-choice rendering and grading
- The three review modes with shared wrong-question ledger:
  - 乱序抽题 (random quiz) → wrong answers auto-enter ledger
  - 错题复习 (wrong-question review) → answering correctly marks MASTERED, removes from ledger
  - 错题抽查 (wrong-question spot-check) → samples from `state != MASTERED` only
- Bookmark + bookmark-list
- Answer statistics: total/right/wrong, per-bank aggregation
- Cross-platform persistence: same `.sqlite` file accessible on Windows and Android
- Windows `.exe` + Android `.apk` packaging

**Should have (competitive differentiators):**
- **Parse-preview-and-edit screen** — after parse, show all extracted questions, let user fix any that the LLM got wrong (LLM is never 100% on messy Chinese formatting)
- **Answer time tracking** — Stopwatch per question; surfaces "slow answers = weak areas"
- **Per-bank statistics** — multiple courses in one app, never mix stats across banks
- **State recovery** — last-active bank + mode + question restored on relaunch
- **Cancellable background parsing** — a 50k-character bank can take 10+ minutes; must be interruptible

**Defer (v2+):**
- Fill-in-blank / true-false / short-answer question types (parse complexity + scoring)
- Image / formula extraction from PDFs (OCR + asset management)
- Spaced repetition / SRS (Anki owns this lane; don't compete on it)
- Streak / gamification (noise in a study tool)
- Cloud sync / multi-user accounts (explicitly out of scope per user)
- Theme switching, font size controls (v1 stock Material 3)

**Anti-features (intentionally not building):**
- Rich-text question editor — would directly eat the "LLM imports for you" differentiator
- Cloud-sharing community — conflicts with "BYO question bank" positioning
- In-app quiz marketplace — same reason
- 计时考试 (timed exam) mode — wrong product; this is review, not test-taking
- 闪卡 (flashcards) — Anki is the answer; don't compete
- Social features — closed-source single-user tool

### Architecture Approach

**Major components:**
1. **Presentation layer** — Material 3 screens + widgets; go_router for navigation
2. **Application layer** — Riverpod `AsyncNotifier` providers; each feature has its own controller (QuizSessionController, ImportController, StatsController)
3. **Domain layer** — entities (`Question`, `QuestionBank`, `AnswerAttempt`, `WrongQuestionEntry`, `Bookmark`), use cases, value objects (`QuestionType`, `ReviewMode`, `WrongQuestionState`)
4. **Data layer** — `drift` DAOs + repositories; `LlmClient` abstract interface with three implementations (Stub / HTTP-to-local-server / FFI)
5. **Cross-cutting** — `PathResolver` (single source of truth for app data dirs), `ParseJobTracker` (stream-based progress), `SchemaMigrator`

**Critical design seams:**
- **`LlmClient` is the most important abstraction** — lets us ship a `StubLlmClient` returning canned JSON for dev/CI, an `HttpLlmClient` pointing at a local llama-server (for early development without FFI work), and a `FfiLlmClient` calling our llama.cpp shim (production). Swapping is a single Riverpod override.
- **Wrong-question ledger is a single source of truth** — one `wrongQuestionsProvider` exposing `Stream<List<WrongQuestionEntry>>`; all three review modes read from it; state transitions (`NEW → IN_LEDGER → MASTERED`) happen in one repository method inside a DB transaction.
- **Parse pipeline runs in an Isolate** — `compute()` for short jobs, dedicated `Isolate.spawn` for long jobs; progress streams back via `SendPort`; cancellable.
- **SQLite lives in `getApplicationSupportDirectory()`** — NOT `getApplicationDocumentsDirectory()`. On Windows, the latter can be synced to OneDrive which corrupts the DB. Support dir is local-only.
- **`mastered_at` is a soft-delete timestamp** — keeps "已掌握 N 道" stat meaningful; lets users "un-master" if needed.
- **Wrong-question spot-check is read-only** — never mutates the ledger (avoids polluting stats from spot-check attempts).

**Project structure:**
```
lib/
  app.dart                  # MaterialApp.router + ProviderScope
  main.dart
  core/
    paths.dart              # PathResolver
    theme.dart
  data/
    db/
      database.dart         # drift @DriftDatabase
      schema.dart
      migrations.dart
    llm/
      llm_client.dart       # abstract
      stub_llm_client.dart
      http_llm_client.dart
      ffi_llm_client.dart   # llama.cpp shim
    repositories/
      question_bank_repository.dart
      question_repository.dart
      attempt_repository.dart
      wrong_ledger_repository.dart
      bookmark_repository.dart
  domain/
    entities/
    value_objects/          # QuestionType, ReviewMode, WrongQuestionState
    usecases/
  features/
    home/                   # bank list + 3 mode entries + stats
    bank_detail/
    import/                 # file_picker → text extract → chunk → LLM → preview/edit → DB
    quiz/                   # shared widget for all 3 modes
    stats/
    bookmarks/
  routing/
    router.dart             # go_router config
```

### Critical Pitfalls

1. **LLM JSON drift** — small models (1–3B) reliably return *plausible-looking* but malformed JSON for gnarly Chinese exam formatting. Mitigation: GBNF grammar constraining output to schema; multi-layer fallback parser (strict → lenient → manual prompt retry); canonicalize answer keys ("AB" → ["A","B"]); always show preview/edit before commit.
2. **Wrong-question ledger state machine non-atomic** — bool-field combinations (`in_ledger` + `mastered`) get out of sync; spot-check forgets to filter `mastered_at IS NULL`. Mitigation: explicit `WrongQuestionState` enum, single repository method per transition wrapped in a DB transaction, idempotency keys on transitions.
3. **SQLite FFI platform quirks** — Windows Chinese paths in argv cause encoding failures; Android scoped-storage URIs need to be copied to app sandbox before opening; multi-instance locks (two app launches). Mitigation: PathResolver centralizes encoding; always copy picked files to support dir first; single-instance lock on startup.
4. **Android LLM OOM** — 1–3 GB model + KV cache on 4–6 GB devices will crash. Mitigation: lazy model load (don't load until first import), tight `n_ctx` (1024), Isolate isolation, capability probe before load, "Fast / Recommended / Experimental" tier UI.
5. **Answer field stringification** — multiple-choice stored as "AB" string instead of normalized `Set<String>` causes grading to always fail. Mitigation: store as canonical set in DB; validate on write; never store user input raw.
6. **Question stem fragmentation** — long stems split across `.docx` paragraphs (line breaks in middle of sentence). Mitigation: pre-chunk by question number regex, pass whole chunk to LLM with explicit "preserve full stem" prompt, keep `raw_text` alongside parsed.
7. **Desktop vs Android lifecycle mismatch** — desktop app expects window-resize-safe state; Android expects background/foreground; quitting desktop mid-quiz and reopening Android doesn't restore. Mitigation: real-time DB commit on every answer, session snapshot to shared_preferences, single-instance lock on desktop.
8. **Closed-source + offline = unreproducible bugs** — no telemetry to know what failed. Mitigation: in-app "diagnostic pack" export (parse_log table + last 50 attempts + app version), `raw_text` stored alongside parsed questions so user-reported bugs can be replayed.

---

## Implications for Roadmap

Based on the research, the following phase structure is proposed. Each phase is grounded in concrete dependencies discovered during research and addresses specific pitfalls.

### Phase 1: Project Skeleton + Persistence Foundation
**Rationale:** Everything depends on a running app + a stable DB schema. Get the boring infrastructure right first.
**Delivers:** Flutter project created (`flutter create --platforms=windows,android`), drift schema for Question/QuestionBank/Attempt/WrongQuestionEntry/Bookmark with v1 schema and a migrator, go_router with placeholder routes, Material 3 theme baseline, PathResolver, dev tooling (`build_runner`, lint config).
**Addresses:** Requirements — bootstrap of all features; sets up schema migrations that every later phase will rely on.
**Avoids:** PITFALL 3 (SQLite FFI platform quirks), PITFALL 7 (lifecycle) by getting path resolution + state commit right from day 1.

### Phase 2: File Import Pipeline (Read-Only, No LLM Yet)
**Rationale:** Prove out `.docx` and `.pdf` text extraction before introducing LLM complexity. Use a regex/heuristic parser as v0 placeholder so the UI can be tested end-to-end. LLM is layered in next phase.
**Delivers:** `file_picker` integration, `archive + xml` docx walker, `pdfx` pdf text extractor, heuristic parser extracting ~70% of questions correctly, import preview screen showing what was parsed, Isolate-based job with progress + cancel.
**Addresses:** Requirements — file import (.docx/.pdf), parse with progress, persistence.
**Avoids:** PITFALL 6 (stem fragmentation) by chunking strategy baked in early; tests against real .docx samples start here.

### Phase 3: LLM Integration + Parse Quality
**Rationale:** The core differentiator. Build the `LlmClient` abstraction with a Stub + HTTP implementations first; ship FFI binding in a spike before committing. The preview/edit UI from Phase 2 makes this safe to ship incrementally.
**Delivers:** `LlmClient` interface, `StubLlmClient` for dev/CI, `HttpLlmClient` pointing at a local llama.cpp server, model picker UI ("Recommended / Fast / Experimental"), model download flow with resume, GBNF grammar for question JSON output, canonicalization layer for answer keys.
**Addresses:** Requirements — LLM-powered parsing with proper JSON, retryable failures, quality improvement over heuristic parser.
**Avoids:** PITFALL 1 (JSON drift), PITFALL 4 (Android OOM) by gating model load on capability probe.
**Research flag:** **HIGH** — this phase genuinely needs a 1-week FFI spike before planning. Plan with a fallback (HTTP-only) if the spike fails.

### Phase 4: Quiz Core + Wrong-Question Ledger
**Rationale:** The state machine is the heart of the product. Get it right with the simplest single-choice question type before adding multiple-choice edge cases and the third mode.
**Delivers:** Quiz screen widget (reusable across 3 modes), single-choice grading, `WrongQuestionState` enum + repository transitions in DB transactions, 乱序抽题 mode end-to-end, 错题复习 mode (correct → MASTERED, leaves ledger), 错题抽查 mode (filters MASTERED).
**Addresses:** Requirements — three review modes, mode linkage via ledger, single-choice support.
**Avoids:** PITFALL 2 (state machine non-atomic), PITFALL 5 (answer field stringification) by making the repository the only entry point.

### Phase 5: Multiple-Choice + Bookmark + Statistics
**Rationale:** After core loop works, add the remaining table-stakes features. Multiple-choice is the second most common type; bookmarks are trivial; stats are pure reads.
**Delivers:** Multiple-choice rendering (checkbox) + grading (exact-match scoring), bookmark add/remove, bookmark list screen, stats screen with per-bank aggregation (totals / correct rate / by mode), answer time tracking.
**Addresses:** Requirements — multiple-choice, bookmarks, answer statistics.
**Avoids:** PITFALL 5 (answer field stringification) by storing normalized sets from day 1.

### Phase 6: Polish + UX + Diagnostics
**Rationale:** Production-readiness layer — UX consistency, bug diagnostics, recovery flows. Without this, users hit edge cases and have nowhere to report them (closed-source + offline).
**Delivers:** UI/UX pass aligned with ui-ux-pro-max reference (visual polish, focus mode), state recovery on launch (last bank + mode + question), diagnostic-pack export for bug reports, parse_log table populated during imports, empty/loading/error states for every screen, settings screen (theme, model picker, parse quality toggle).
**Addresses:** Requirements — UI/UX polish, session state recovery.
**Avoids:** PITFALL 7 (lifecycle), PITFALL 8 (unreproducible bugs).

### Phase 7: Packaging + Cross-Platform Verification
**Rationale:** The whole point is producing `.exe` and `.apk`. This is where Windows + Android packaging quirks get resolved and the on-device LLM gets tuned for real hardware.
**Delivers:** `flutter build windows --release` producing portable `.exe`, `flutter build apk` with split-per-abi (arm64 mandatory, x86_64 optional), GGUF download flow verified on Android 6/8/12 GB phones, model size guidance surfaced in UI, install + first-run smoke tests on real devices, README with install steps.
**Addresses:** Requirements — Windows `.exe` + Android `.apk` packaging.
**Avoids:** PITFALL 4 (Android OOM) by validating model picker on real low-end devices.

### Phase Ordering Rationale

- **Database before parsing before LLM** — schema evolves; adding a field to `WrongQuestionEntry` is cheap on day 1, expensive after parsing logic has been written against an old shape.
- **Heuristic parser before LLM** — proves the import pipeline end-to-end without LLM complexity; gives a fallback path if LLM FFI fails.
- **Stub LLM before HTTP before FFI** — the abstraction is cheap to build incrementally; shipping the Stub first lets every developer run the app without a model download.
- **Single-choice before multiple-choice** — wrong-question state machine is identical, but grading logic differs; isolate the state machine from the grading details.
- **Two review modes (random + wrong-review) before spot-check** — spot-check is the simplest mode but builds on the same ledger; harder to test in isolation.
- **Polish + diagnostics before packaging** — a packaged build that's full of bugs is harder to debug than a `flutter run` session.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 3 (LLM Integration):** the on-device LLM on Android is the hardest problem in this project. Needs a 1-week spike before detailed planning.
- **Phase 2 (File Import):** the `.docx` parsing reality needs validation against real Chinese university `.docx` files — pull a few samples during planning.

Phases with standard patterns (can skip research-phase):
- **Phase 1 (Skeleton):** standard Flutter + drift setup; well-documented.
- **Phase 4 (Quiz Core):** state machine pattern is standard; the wrong-question design is straightforward.
- **Phase 5 (Multiple-choice + stats):** straightforward extensions of Phase 4.

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack (Flutter, drift, Riverpod, go_router, file_picker, Material 3) | HIGH | All are Flutter Favorites or bundled; widely used; pub.dev verified versions |
| Stack (.docx parsing via archive + xml) | MEDIUM | Feasible but no silver-bullet package; needs hand-rolled WordprocessingML traversal and real-world testing |
| Stack (llama.cpp FFI on Windows + Android) | MEDIUM | Realistic and well-trodden, but no pub.dev wrapper covers both platforms; ~1–2 weeks of shim work |
| Stack (Qwen2.5-1.5B Q4_K_M model choice) | MEDIUM-HIGH | Best-in-class at its size for Chinese + JSON; alternative models are equivalent |
| Features (table stakes identification) | HIGH | Standard pattern for quiz/review apps; well-understood |
| Features (anti-features opinionation) | MEDIUM-HIGH | Opinionated; user can override per their preferences |
| Architecture (Riverpod + drift + LlmClient seam) | HIGH | Standard pattern; well-exemplified |
| Architecture (parse pipeline in Isolate) | HIGH | `compute()` + `Isolate.spawn` are standard Flutter idioms |
| Pitfalls (LLM JSON drift, state machine, OOM, answer stringification) | HIGH | Real and well-known; each has tested mitigations |
| Pitfalls (closed-source + offline = unreproducible bugs) | MEDIUM | Real risk but mitigations (diagnostic pack) are untested in this exact domain |

**Overall confidence: MEDIUM-HIGH** — the stack, architecture, and feature list are sound. The single biggest risk is Phase 3 (LLM FFI on Android); a 1-week spike there will convert MEDIUM to HIGH.

### Gaps to Address

- **Real `.docx` samples for testing** — pull a few real Chinese university `.docx` files during planning for Phase 2 unit tests
- **LLM FFI spike** — prototype the llama.cpp shim on Windows + a low-end Android device before locking Phase 3 plan
- **WordprocessingML scope** — confirm with a sample docx whether the formats we need to handle include tables, images, multi-column layouts (these add significant parser complexity); if rare, defer to v2
- **Scanned PDF** — if teacher-sent PDFs include scanned images (not text-extractable), the v1 LLM-on-text path won't work; need a fallback message and possibly OCR (out of scope for v1 per user)

---

## Sources

### Primary (HIGH confidence)
- `pub.dev` verified versions for: `flutter_riverpod` 3.3.2, `drift` 2.34.0, `go_router` 17.3.0, `file_picker` 11.0.2, `pdfx` 2.9.2, `archive` 4.0.9, `xml` 6.x, `flutter_llama` 1.1.2, `onnxruntime` 1.4.1, `path_provider` 2.1.6, `shared_preferences` 2.5.5, `intl` 0.20.2
- `docs.flutter.dev/release/archive` — Flutter 3.35.7 stable (2025-12-04)
- `github.com/ggml-org/llama.cpp/releases` — b9717 with prebuilt Windows + Android binaries
- `.planning/PROJECT.md` — project context, core value, requirements
- `.planning/research/STACK.md` — full stack research
- `.planning/research/FEATURES.md` — full feature research
- `.planning/research/ARCHITECTURE.md` — full architecture research
- `.planning/research/PITFALLS.md` — full pitfalls research

### Secondary (MEDIUM confidence)
- Qwen2.5-1.5B-Instruct as recommended default — based on Chinese-language benchmark results at this size tier
- WordprocessingML hand-rolling — based on the absence of mature pure-Dart alternatives on pub.dev

### Tertiary (LOW confidence — needs validation)
- Actual on-device LLM inference latency on real low-end Android devices — needs Phase 3 spike
- `.docx` parsing accuracy on real Chinese university exam files — needs Phase 2 testing

---

*Research completed: 2026-06-19*
*Ready for roadmap: yes*
