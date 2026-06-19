---
phase: 03-desktop-llm-integration-parse-quality
plan: 02
subsystem: LLM client abstraction (stub implementation)
type: implementation
tags: [llm-client, stub, fixture, deterministic, tdd, ci]
depends_on: ["03-01"]
provides: StubLlmClient for all downstream LLM-dependent plans
affects: [03-03, 03-04, 03-05, 03-06, 03-07, 03-08]
requirement: IMP-03
tech-stack:
  added: []
  patterns: [LlmClient interface implementation, lazy-loading asset fixture, keyword-based routing]
key-files:
  created:
    - assets/fixtures/sample_llm_response.json
    - lib/data/llm_client/stub_llm_client.dart
    - test/data/llm_client/stub_llm_client_test.dart
  modified:
    - lib/data/llm_client/providers.dart
    - pubspec.yaml
decisions:
  - "StubLlmClient constructor accepts optional Map<String, dynamic>? fixtures for test injection, bypassing rootBundle — enables pure-Dart unit tests without asset channel mocking"
  - "Keyword detection uses word-alternative regex (以下哪些|属于|包括) rather than character class — more precise, fewer false positives"
  - "Confidence always 1.0 in stub output — represents 'perfect LLM' for deterministic CI"
metrics:
  duration: "~12 min"
  tasks: 2
  files: 5
  completed: "2026-06-20"
---

# Phase 03 Plan 02: StubLlmClient Summary

**Deterministic LlmClient returning pre-canned ParseCandidate fixtures from embedded JSON asset, enabling development and CI testing without a running llama.cpp server.**

## What Was Built

**StubLlmClient** — a zero-dependency `LlmClient` implementation that loads canned question fixtures from `assets/fixtures/sample_llm_response.json` via `rootBundle` (production) or from injected test data (tests). It uses keyword-based pattern matching to select the appropriate fixture entry and returns a `ParseCandidate` with `confidence=1.0` and `metadata['source']='stub'` on every call.

**Key behaviors:**
- Fixtures lazy-loaded from asset bundle on first `parse()` call (cached thereafter)
- Keyword detection: "以下哪些"/"属于"/"包括" maps to multi-choice; "正确"/"错误"/"判断"/"对错" maps to true/false; everything else gets single-choice default
- `confidence` always 1.0 (stub is "perfect" LLM)
- `metadata['source'] = 'stub'` for parse source tracking (D-09 compatibility)
- `bankName` parameter stored in `metadata['bankName']`
- Deterministic — same input always produces identical `ParseCandidate` (structural + JSON equality)
- Never throws — stub is the reliable testing baseline

**Provider wiring:**
- `lib/data/llm_client/providers.dart` `llmClientProvider` now returns `StubLlmClient()` for `LlmMode.stub` (was `UnimplementedError` throw)
- Platform gate unchanged — Android still throws `UnsupportedError`

**Fixture JSON:**
- 3 entries: "default" (single-choice), "multi" (multi-choice with answer "ABC"), "truefalse" (true/false)
- All fields present: title, type, options, answer, explanation

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed regex character class to word alternatives for multi-choice keyword detection**
- **Found during:** Task 1 implementation
- **Issue:** Plan template used `[属于包括]` character class which matches any single Unicode character from the set — semantically wrong
- **Fix:** Changed to `以下哪些|属于|包括` (pipe-separated word alternatives) for correct pattern matching
- **Files modified:** `lib/data/llm_client/stub_llm_client.dart`
- **Commit:** `be15018`

### Tooling Unavailability

**Flutter SDK not available in execution environment** — `flutter test`, `dart analyze`, and `dart run build_runner build` could not be executed. Test file was written and implementation was code-reviewed against the plan's acceptance criteria, but automated verification was skipped. The verifier agent or R2 process must confirm:
1. `flutter test test/data/llm_client/` exits 0 (all tests pass)
2. `dart analyze lib/data/llm_client/` exits 0
3. `dart run build_runner build --delete-conflicting-outputs` exits 0 and regenerates `providers.g.dart` with updated comments

## Acceptance Criteria Status

| Criterion | Status |
|-----------|--------|
| `class StubLlmClient implements LlmClient` | Implemented |
| `parse()` returns `Future<ParseCandidate>` with `confidence=1.0` | Implemented |
| Fixture JSON contains "default", "multi", "truefalse" keys | Confirmed |
| `metadata['source'] == 'stub'` on all return values | Implemented |
| Keyword detection: "以下哪些"->multi, "判断"->truefalse, default->single | Implemented (fixed regex) |
| `pubspec.yaml` includes `assets/fixtures/` | Confirmed |
| 7+ passing tests | Written (14 tests) — execution pending |
| `dart analyze` clean | Pending (tooling unavailable) |
| Provider wired: `LlmMode.stub => StubLlmClient()` | Implemented |
| `dart run build_runner build` exits 0 | Pending (tooling unavailable) |

## Threats

Per plan `<threat_model>`, both identified threats (T-03-02-01 tampering of fixture JSON, T-03-02-02 spoofing from stub confidence) are `accept` dispositions — no mitigations needed. Fixture is embedded at build time and StubLlmClient is a dev/CI tool only.

## Known Stubs

None introduced by this plan. The `LlmMode.http => throw UnimplementedError(...)` is an intentional stub awaiting plan 03-03 (HttpLlmClient).

## Commits

| Hash | Message |
|------|---------|
| `be15018` | feat(03-02): implement StubLlmClient with fixture JSON and tests |
| `37ab80e` | feat(03-02): wire StubLlmClient into llmClientProvider stub branch |

## Self-Check: PASSED

- `assets/fixtures/sample_llm_response.json` exists
- `lib/data/llm_client/stub_llm_client.dart` exists
- `test/data/llm_client/stub_llm_client_test.dart` exists
- `lib/data/llm_client/providers.dart` modified (import + wiring)
- `pubspec.yaml` modified (assets registration)
- Commit `be15018` confirmed
- Commit `37ab80e` confirmed
