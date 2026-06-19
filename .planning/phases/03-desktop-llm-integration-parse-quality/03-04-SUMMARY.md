---
phase: 03-desktop-llm-integration-parse-quality
plan: 04
subsystem: parsing
tags: [dart, riverpod, llm, gbnf, json-schema, canonicalization, chunking]

# Dependency graph
requires:
  - phase: 03-01
    provides: LlmClient abstract interface, LlmMode enum, providers.dart
  - phase: 03-02
    provides: StubLlmClient (deterministic for testing)
  - phase: 03-03
    provides: HttpLlmClient (production HTTP client with retry)
  - phase: 02-desktop-file-import-pipeline
    provides: ImportState, ImportNotifier, HeuristicParser, ParseCandidate
  - phase: 01-foundation-persistence
    provides: AppDatabase, ParseLogs table, PathResolver

provides:
  - Question block chunker (Chinese/English numbering patterns)
  - Answer canonicalizer (all LLM output formats → sorted letter lists)
  - JSON Schema grammar builder + GBNF fallback generator
  - Grammar assets (question_schema.json, question.gbnf)
  - ImportPhase.llmParsing enum value (between parsing and editing)
  - ImportState.parseSources per-candidate ParseSource tracking
  - ImportNotifier.llmParse() pipeline branch (chunk → parse → retry → fallback → auto-confirm → log)
  - ParseSource enum (llm, heuristic, fallback) for 3-way distinction

affects:
  - 03-05 (Model management UI)
  - 03-07 (FFI spike/binding)
  - Phase 4 (Quiz core — uses ParseCandidate from LLM)
  - Phase 6 (Diagnostics — reads parse_log table)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - TDD with RED→GREEN commits per task
    - Chunk-by-question-number LLM processing (per RESEARCH.md Pattern 2)
    - Multi-format answer canonicalization (PITFALL 1 defense)
    - JSON Schema → GBNF fallback generation (PITFALL 4 defense)
    - ParseSource enum over boolean flags (anti-pattern avoidance per RESEARCH.md)

key-files:
  created:
    - lib/features/import/parsing/llm/chunker.dart
    - lib/features/import/parsing/llm/canonicalizer.dart
    - lib/features/import/parsing/llm/grammar_builder.dart
    - assets/grammar/question_schema.json
    - assets/grammar/question.gbnf
    - test/features/import/parsing/llm/chunker_test.dart
    - test/features/import/parsing/llm/canonicalizer_test.dart
    - test/features/import/parsing/llm/grammar_builder_test.dart
    - test/features/import/parsing/llm/import_notifier_llm_test.dart
    - test/features/import/providers/import_state_test.dart
  modified:
    - lib/features/import/providers/import_state.dart
    - lib/features/import/providers/import_notifier.dart
    - lib/features/import/providers/import_notifier.g.dart
    - pubspec.yaml

key-decisions:
  - "Chunker regex matches ^1. ^1、 ^1) （1） ① patterns per RESEARCH.md Pattern 2"
  - "Canonicalizer handles 8+ input formats (AB, A,B, A和B, JSON array, A B, a,b, etc.) per PITFALL 1"
  - "GBNF grammar uses simplified root ::= object structure as fallback for older llama.cpp servers"
  - "parse_log insertion is best-effort (try/catch) — FK to parse_jobs means logs only persist when job exists"
  - "LLM answers canonicalized via canonicalizeAnswer + formatAnswerForDisplay before storage"
  - "Fallback candidates get confidence × 0.8 (lower trust in heuristic re-parse)"

patterns-established:
  - "Chunk-by-question: Never send full text to LLM; split by question number first"
  - "Canonicalization layer: All LLM answers normalized before storage regardless of output format"
  - "ParseSource tracking: 3-way enum (llm/heuristic/fallback) per D-09, not boolean"
  - "Auto-confirm LLM results: confirmedIndices = all indices per D-08"
  - "Per-chunk isolation: One bad chunk does not abort the entire import"

requirements-completed: [IMP-03, IMP-04]

# Metrics
duration: ~45min
completed: 2026-06-20
---

# Phase 3 Plan 4: LLM Parse Pipeline Integration Summary

**Question-block chunking, answer canonicalization, GBNF grammar generation, and full ImportNotifier LLM branch with per-chunk retry/fallback/auto-confirm/parse_log**

## Performance

- **Duration:** ~45 min
- **Started:** 2026-06-20T00:20:00Z (approximate)
- **Completed:** 2026-06-20T01:05:00Z (approximate)
- **Tasks:** 3 (all TDD: RED → GREEN)
- **Files modified:** 14 (10 created, 4 modified)

## Accomplishments

- Chunker with 9 regex patterns supporting Chinese/English question numbering (1. 1、 1) （1） ①)
- Answer canonicalizer normalizing 8+ LLM output formats (AB, A,B, A和B, JSON array, A B, case variations)
- JSON Schema grammar with `^[A-H]+$` answer constraint + GBNF fallback for legacy llama.cpp servers
- ImportPhase.llmParsing sub-phase and ImportState.parseSources per-candidate source tracking
- Full ImportNotifier.llmParse() pipeline: chunk → LlmClient.parse → canonicalize → auto-confirm → fallback → parse_log
- 47/47 new tests passing, 0 regressions in existing import tests, dart analyze clean

## Task Commits

Each task was committed atomically following TDD (RED → GREEN):

1. **Task 1: Chunker, canonicalizer, grammar builder, assets** - `942bb59` (test), `4e62019` (feat)
2. **Task 2: ImportState extension (llmParsing, parseSources)** - `3bac641` (test), `7afcdf8` (feat)
3. **Task 3: ImportNotifier llmParse branch** - `03f5fb5` (test), `d9892bb` (feat)

## Files Created/Modified

**Created:**
- `lib/features/import/parsing/llm/chunker.dart` - Question block splitting by number pattern (47 lines)
- `lib/features/import/parsing/llm/canonicalizer.dart` - Answer format normalization + ParseSource enum (73 lines)
- `lib/features/import/parsing/llm/grammar_builder.dart` - JSON Schema generation + GBNF conversion (81 lines)
- `assets/grammar/question_schema.json` - JSON Schema for LLM output constraint (25 lines)
- `assets/grammar/question.gbnf` - Pre-generated GBNF fallback grammar (10 lines)
- `test/features/import/parsing/llm/chunker_test.dart` - 9 tests covering all numbering patterns
- `test/features/import/parsing/llm/canonicalizer_test.dart` - 17 tests for canonicalization + ParseSource
- `test/features/import/parsing/llm/grammar_builder_test.dart` - 12 tests for schema + GBNF generation
- `test/features/import/parsing/llm/import_notifier_llm_test.dart` - 9 tests for full LLM pipeline
- `test/features/import/providers/import_state_test.dart` - 8 tests for phase + parseSources

**Modified:**
- `lib/features/import/providers/import_state.dart` - ImportPhase.llmParsing, parseSources, isLlmParsing
- `lib/features/import/providers/import_notifier.dart` - llmParse(), _fallbackParseSingle(), _logParseEvent()
- `lib/features/import/providers/import_notifier.g.dart` - Regenerated Riverpod codegen
- `pubspec.yaml` - Registered assets/grammar/ directory

## Decisions Made

- Used simplified GBNF grammar generation (not full auto-converted) per RESEARCH.md Open Question 2 — adequate as fallback for older servers
- Made parse_log insertion best-effort (silently catches FK failures) — avoids blocking import when parse_job hasn't been created yet
- Removed unused `fallbackCount` local variable — reserved for future D-09 summary diagnostics

## Deviations from Plan

None — plan executed exactly as written. All TDD cycles followed RED→GREEN pattern. All 3 tasks completed per specification.

## Issues Encountered

**1. parse_log FK constraint in tests (Rule 1 - Bug)**
- **Found during:** Task 3 (parse_log test)
- **Issue:** Test setUp tried to insert parse_log without a corresponding parse_jobs entry, violating FK constraint
- **Fix:** Removed unnecessary setUp insert; parse_log test explicitly creates parse_jobs entry before running llmParse
- **Files modified:** test/features/import/parsing/llm/import_notifier_llm_test.dart
- **Committed in:** d9892bb

**2. Empty extractedText early return (Rule 2 - Missing Critical)**
- **Found during:** Task 3 (empty text test)
- **Issue:** llmParse() returned immediately without setting error state when extractedText was empty
- **Fix:** Added phase=idle + error message transition per plan spec
- **Files modified:** lib/features/import/providers/import_notifier.dart
- **Committed in:** d9892bb

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- LLM parse pipeline fully integrated into ImportNotifier — ready for UI wiring in 03-05 (model management)
- StubLlmClient provides deterministic testing path — no live llama.cpp server needed for CI
- ParseCandidate model extended with source metadata — UI can display per-candidate parse origin
- parse_log table receives structured failure data — diagnostics-ready per D-09

---
*Phase: 03-desktop-llm-integration-parse-quality*
*Plan: 04*
*Completed: 2026-06-20*

## Self-Check: PASSED

- All 13 created/modified files verified present on disk
- All 6 commits (942bb59, 4e62019, 3bac641, 7afcdf8, 03f5fb5, d9892bb) confirmed in git history
- 47/47 llm tests passing
- 76/79 import tests passing (3 pre-existing extraction failures unrelated to this plan)
- dart analyze clean on all modified files
