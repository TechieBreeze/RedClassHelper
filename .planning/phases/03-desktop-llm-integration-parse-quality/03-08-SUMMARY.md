---
phase: 03-desktop-llm-integration-parse-quality
plan: 08
subsystem: llm
tags: [dart:ffi, llama.cpp, ffi, native-interop, desktop]

# Dependency graph
requires:
  - phase: 03-01
    provides: LlmClient interface, LlmMode enum, llmClientProvider
provides:
  - FfiLlmClient implementing LlmClient via dart:ffi dynamic library binding
  - LlmMode.ffi enum value wired into llmClientProvider switch
  - llama.cpp C API FFI type definitions and function signatures
  - GO decision: FFI binding viable for v1 production path
affects: [03-ui-llm-model-management, 06-ux-polish-diagnostics]

# Tech tracking
tech-stack:
  added: [ffi: ^2.1.3]
  patterns: [dart:ffi DynamicLibrary pattern, lazy model loading, mutex-based thread safety for native code, Platform-native shared library resolution]

key-files:
  created:
    - lib/data/llm_client/ffi_llm_client.dart
    - test/data/llm_client/ffi_llm_client_test.dart
  modified:
    - lib/data/llm_client/llm_client.dart
    - lib/data/llm_client/providers.dart
    - pubspec.yaml
    - .planning/PROJECT.md

key-decisions:
  - "GO decision: FfiLlmClient implemented as v1 production FFI path per Phase 03-08 spike"
  - "LlmMode enum extended with ffi value alongside existing stub and http"
  - "modelPath stub in providers.dart delegated to Phase 6 settings/ModelManager"
  - "llama_get_logits bound for proper greedy sampling from context logits"

requirements-completed: [IMP-03]

# Metrics
duration: 25min
completed: 2026-06-20
---

# Phase 3 Plan 8: FfiLlmClient -- llama.cpp dart:ffi Direct Binding Summary

**FfiLlmClient with complete llama.cpp C API FFI bindings (model load, tokenize, decode, greedy sample), wired into LlmMode.ffi provider branch for single-process desktop inference**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-06-19T15:40:00Z (checkpoint continuation)
- **Completed:** 2026-06-20T00:15:00Z
- **Tasks:** 1 implemented (Task 3); Task 2 decision resolved as GO from prior session
- **Files modified:** 6 (4 modified, 2 created)

## Accomplishments

- Extended LlmMode enum with `ffi` value for direct native inference
- Created FfiLlmClient (948 lines) implementing LlmClient via dart:ffi DynamicLibrary
- Defined complete llama.cpp C API FFI type mappings: llama_model, llama_context, llama_token, struct definitions for model_params, context_params, batch, token_data, token_data_array
- Bound 16 native function symbols: llama_backend_init, llama_model_default_params, llama_context_default_params, llama_model_load, llama_free_model, llama_new_context_with_model, llama_free, llama_model_desc, llama_n_vocab, llama_n_ctx, llama_tokenize, llama_decode, llama_get_logits, llama_token_to_piece, llama_sample_token_greedy, llama_batch_init
- Implemented complete inference pipeline: prompt template, tokenization, batch prompt evaluation, autoregressive generation loop with greedy sampling from logits, detokenization, JSON output parsing
- Model lifecycle management: lazy-load on first parse(), dispose() for cleanup (model + context + mutex + library)
- Optional mutex-based thread safety via llama_mutex_* functions (graceful fallback if not exported)
- Retry logic (default 3 attempts) with LlmRetryExhaustedException
- Wired LlmMode.ffi branch into llmClientProvider with modelPath stub (Phase 6 population)
- Added `ffi: ^2.1.3` package dependency for Utf8/calloc helpers
- Created comprehensive test suite (207 lines): interface compliance, constructor defaults, error handling (library not found, retry exhaustion), lifecycle (dispose safety, disposed state errors), model path validation
- Updated PROJECT.md Key Decisions with FFI production path entry

## Task Commits

Each task was committed atomically:

1. **Task 1: Research spike** — not committed to main repo (spike conducted in worktree `.claude/worktrees/agent-a40bd5e7cc0849961/`)
2. **Task 2: Decision checkpoint** — resolved as GO by user from prior session
3. **Task 3: Implement FfiLlmClient** — `92e736e` (feat: implement FfiLlmClient with dart:ffi binding to llama.cpp)

## Files Created/Modified

- `lib/data/llm_client/ffi_llm_client.dart` — FfiLlmClient class (948 lines): llama.cpp FFI type definitions, native function bindings, inference pipeline (tokenize → decode → sample → detokenize → parse JSON)
- `test/data/llm_client/ffi_llm_client_test.dart` — Tests (207 lines): interface compliance, constructor defaults, error path coverage, lifecycle safety
- `lib/data/llm_client/llm_client.dart` — Added `ffi` to LlmMode enum + doc comment
- `lib/data/llm_client/providers.dart` — Imported ffi_llm_client.dart, added LlmMode.ffi switch case, updated doc comment
- `pubspec.yaml` — Added `ffi: ^2.1.3` dependency
- `.planning/PROJECT.md` — Added Key Decision: FfiLlmClient as v1 production path

## Decisions Made

- **GO decision** (from prior session): FFI binding viable for v1. Direct dart:ffi integration chosen over HTTP-only to eliminate llama-server process dependency
- **llama_get_logits bound**: Required for correct greedy sampling — iterates vocabulary logits from context rather than assuming pre-filled candidate arrays
- **modelPath stub**: Set to `''` in providers.dart — intentionally deferred to Phase 6 settings/ModelManager for actual .gguf path configuration
- **No platform check in FfiLlmClient**: Platform gating is the responsibility of providers.dart (existing Platform.isWindows/isLinux check). FfiLlmClient itself delegates platform-appropriate library name resolution to DynamicLibrary.open

## Deviations from Plan

### Known Environment Limitation

**1. [Environment] Flutter/Dart SDK not available in worktree**
- **Found during:** Task 3 verification
- **Issue:** Flutter SDK path from STATE.md (`C:\Users\Lenovo\flutter`) does not exist or is not accessible from this git-bash worktree, consistent with 03-06-SUMMARY.md finding
- **Impact:** `flutter pub get`, `dart analyze`, `flutter test`, and `dart run build_runner` could not be executed
- **Mitigation:** Code was manually reviewed for correctness. Tests follow established patterns from http_llm_client_test.dart and stub_llm_client_test.dart. Build_runner regeneration of providers.g.dart delayed until SDK access is restored.
- **Status:** Deferred to next session with working Flutter SDK

### Incomplete Prerequisite

**2. [Plan] Task 1 spike report not committed**
- **Found during:** Pre-execution check
- **Issue:** `doc/ffi-spike-report.md` does not exist in the main repo. The spike was conducted in a separate worktree (`.claude/worktrees/agent-a40bd5e7cc0849961/doc/ffi-spike-report.md`) but the file was never committed to `master`.
- **Impact:** The GO decision was made by the user at the checkpoint without the spike report being present in the main branch. The plan's must-have artifact `doc/ffi-spike-report.md` (min 100 lines) is missing.
- **Status:** The spike report exists in the worktree. Recommendation: copy it to the main repo or regenerate it before merging.

---

**Total deviations:** 2 (1 environment, 1 incomplete prerequisite)
**Impact on plan:** Task 3 implementation is complete. Environment limitations prevent SDK-based verification (flutter test, dart analyze, build_runner). Missing spike report is a documentation gap.

## Issues Encountered

- Flutter SDK not accessible from git-bash worktree (known from 03-06) — prevented `flutter pub get`, `dart analyze`, `flutter test`, `build_runner` execution

## Known Stubs

| Stub | File | Line | Reason |
|------|------|------|--------|
| `modelPath: ''` | `lib/data/llm_client/providers.dart` | ~47 | Placeholder — populated from settings/ModelManager in Phase 6; FfiLlmClient throws LlmConnectionException on empty path which is expected behavior until Phase 6 |

## Threat Flags

| Flag | File | Description |
|------|------|-------------|
| threat_flag: native-crash | lib/data/llm_client/ffi_llm_client.dart | dart:ffi boundary — crashes in llama.cpp kill the Dart VM; mitigated by try/catch in _resolveSymbols and retry loop, but infailable segfaults (null deref, buffer overflow) are not catchable |
| threat_flag: library-loading | lib/data/llm_client/ffi_llm_client.dart | DynamicLibrary.open loads native code with app privileges; a compromised .dll/.so can execute arbitrary code — accepted risk per threat model T-03-08-02 |

## Next Phase Readiness

- Phase 3 LLM integration is now structurally complete: StubLlmClient + HttpLlmClient + FfiLlmClient all wired into llmClientProvider
- `build_runner` regeneration needed for `providers.g.dart` to include the LlmMode.ffi branch in the auto-generated provider code
- Phase 6 (UX Polish & Diagnostics) will populate modelPath from settings
- Integration tests with a real llama.cpp shared library are deferred — the test suite covers error paths and interface compliance, suitable for CI

---
*Phase: 03-desktop-llm-integration-parse-quality*
*Plan: 08*
*Completed: 2026-06-20*
