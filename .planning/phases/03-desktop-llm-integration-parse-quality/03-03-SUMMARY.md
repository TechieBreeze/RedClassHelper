---
phase: 03-desktop-llm-integration-parse-quality
plan: 03
subsystem: llm-client
tags: [llm, http, llama.cpp, retry, error-handling, json-schema]
requires: ["03-01"]
provides: ["HttpLlmClient", "LlmMode.http provider wiring"]
affects:
  - lib/data/llm_client/providers.dart
tech-stack:
  added: ["package:http"]
  patterns: ["Riverpod provider switch", "TDD (RED-GREEN)", "Retry with typed exception gating"]
key-files:
  created:
    - lib/data/llm_client/http_llm_client.dart
    - test/data/llm_client/http_llm_client_test.dart
  modified:
    - lib/data/llm_client/providers.dart
    - lib/data/llm_client/providers.g.dart
decisions:
  - "LLM output type field (single/multiple/truefalse) mapped to ParseCandidate candidateType (single_choice/multi_choice/true_false) in HttpLlmClient"
  - "JSON parse failures are NOT retried (retrying won't fix malformed LLM output); timeout and connection errors ARE retried up to 3 times"
  - "Test timeout/connection-refused scenarios use maxRetries=1, verifying LlmRetryExhaustedException wrapping"
metrics:
  duration: 8min
  tasks: 2
  files: 4
  completed_date: 2026-06-20
  plan_start: 2026-06-20T00:03:00Z
  plan_end: 2026-06-20T00:11:00Z
---

# Phase 03 Plan 03: HttpLlmClient with Retry, Error Handling, and Provider Wiring

**One-liner:** Production `LlmClient` that POSTs question blocks to a local llama.cpp HTTP `/completion` endpoint with JSON Schema grammar constraints, 3-attempt retry, and structured exception mapping.

## Tasks Executed

| # | Type | Name | Commit | Status |
|---|------|------|--------|--------|
| 1 | auto (TDD) | Create HttpLlmClient with retry and error handling | `59b0033` | PASS |
| 2 | auto | Wire HttpLlmClient into llmClientProvider | `ff2391b` | PASS |

### Task 1: HttpLlmClient Implementation (TDD)

**RED** (`163b6a2`): Created `test/data/llm_client/http_llm_client_test.dart` with 14 tests covering constructor, POST body, response parsing, timeout, connection refused, retry exhaustion, JSON parse errors, and metadata. Confirmed RED: 2 constructor stubs pass, 12 behavioral tests fail.

**GREEN** (`59b0033`): Implemented `lib/data/llm_client/http_llm_client.dart` (262 lines):
- `const` constructor with `serverUrl` (default `http://localhost:8080`), `timeout` (default 30s), `maxRetries` (default 3)
- `parse()` public method with retry loop: catches `LlmTimeoutException` and `LlmConnectionException` (retryable), rethrows `LlmJsonParseException` (non-retryable)
- `_attemptParse()` private method: builds POST body with `prompt` (Qwen2.5 chat template), `n_predict=512`, `temperature=0.0`, `seed=42`, `json_schema`, `stop=['<|im_end|>']`, `stream=false`, `cache_prompt=false`
- `_parseResponse()` handles the llama.cpp response wrapper (`{content: "...", stop: true}`), extracts and validates inner LLM JSON
- `_buildJsonSchema()` returns the question JSON Schema object (title, type, options, answer, explanation)
- LLM type mapping: `single`→`single_choice`, `multiple`→`multi_choice`, `truefalse`→`true_false`
- Error mapping: `TimeoutException`→`LlmTimeoutException`, `SocketException/HttpException/ClientException`→`LlmConnectionException`, `FormatException`→`LlmJsonParseException`
- Metadata: `source: 'llm'` + optional `bankName`

All 14 tests pass. `dart analyze` clean (1 info-level false-positive for null-aware elements in map with non-nullable value type).

### Task 2: Provider Wiring

**Commit** (`ff2391b`): Edited `lib/data/llm_client/providers.dart`:
- Added `import 'http_llm_client.dart'`
- Replaced `throw UnimplementedError('LlmMode.http not yet implemented')` with `HttpLlmClient(serverUrl: 'http://localhost:8080', timeout: const Duration(seconds: 30))`
- Regenerated `providers.g.dart` via `dart run build_runner build --delete-conflicting-outputs`

Full `test/data/llm_client/` suite: 37/38 pass. Full project suite: 125/131 pass (6 pre-existing failures unchanged).

## Verification Results

| Check | Result |
|-------|--------|
| `flutter test test/data/llm_client/http_llm_client_test.dart` | 14/14 PASS |
| `flutter test test/data/llm_client/` | 37/38 PASS (1 pre-existing) |
| `flutter test` (full suite) | 125/131 PASS (6 pre-existing) |
| `dart analyze lib/data/llm_client/` | 0 errors, 0 warnings, 3 info |

## Deviations from Plan

### Pre-existing Issues (Out of Scope)

**1. platform_gate_test.dart failure** — The test `llmClientProvider compiles and is accessible` expects an exception to be thrown, but since StubLlmClient was wired in Plan 03-02, `llmClientProvider` on Windows desktop now correctly returns a `StubLlmClient` without throwing. Logged to `deferred-items.md`.

**2. home_screen_test.dart and extraction_test.dart failures** — 5 additional pre-existing test failures unrelated to Plan 03-03 changes. No regressions introduced.

### Implementation Adjustments

**1. [Plan interpretation] Test 6/7 timeout/connection-refused expectations adjusted** — The plan's test descriptions mention `LlmTimeoutException` and `LlmConnectionException` directly, but the public `parse()` method's retry loop wraps these into `LlmRetryExhaustedException` on the last attempt. Tests use `maxRetries=1` and verify `LlmRetryExhaustedException` with appropriate `lastError` contents. This matches the plan's action section pseudocode which shows the wrapping behavior.

## Known Stubs

None. The HttpLlmClient is a complete, production-ready implementation (no TODO, FIXME, placeholder values, or hardcoded empty data). The stub path (`LlmMode.stub`) remains available via the existing `StubLlmClient` for CI/dev.

## Threat Flags

| Flag | File | Description |
|------|------|-------------|
| threat_flag: network-endpoint | lib/data/llm_client/http_llm_client.dart | POST to localhost:8080/completion — already in plan threat model (T-03-03-01 through T-03-03-05) |

## Self-Check: PASSED

- [x] `lib/data/llm_client/http_llm_client.dart` exists (262 lines)
- [x] `test/data/llm_client/http_llm_client_test.dart` exists (294 lines)
- [x] `lib/data/llm_client/providers.dart` updated with HttpLlmClient import and wiring
- [x] `lib/data/llm_client/providers.g.dart` regenerated
- [x] Commits `163b6a2`, `59b0033`, `ff2391b` verified in git log
- [x] 14/14 HttpLlmClient tests pass
- [x] No regressions in full test suite
- [x] `dart analyze lib/data/llm_client/` clean (0 errors, 0 warnings)
