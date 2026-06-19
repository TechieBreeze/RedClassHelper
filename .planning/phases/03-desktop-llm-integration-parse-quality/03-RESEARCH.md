# Phase 3: Desktop LLM Integration & Parse Quality - Research

**Researched:** 2026-06-19
**Domain:** On-device LLM parsing via llama.cpp HTTP server; GGUF model management; GBNF grammar-constrained generation; Dart HTTP download with resume
**Confidence:** HIGH

## Summary

Phase 3 replaces the existing `HeuristicParser` with a swappable `LlmClient` abstraction backed by a local llama.cpp HTTP server. The `LlmClient` sends raw question-block text to `POST /completion` on `localhost:8080`, constrained by a GBNF grammar (auto-converted from JSON Schema) that forces the model to output valid question JSON. Three Qwen2.5-Instruct GGUF models (0.5B Fast, 1.5B Recommended, 3B Experimental) are downloaded on-demand from HuggingFace with resume support via HTTP Range requests. The parse pipeline is extended with an `llmParsing` sub-phase that supports per-question retry (3 attempts) and automatic fallback to the heuristic parser. All LLM UI surfaces are gated on `Platform.isWindows || Platform.isLinux`.

**Primary recommendation:** Use the llama.cpp native `/completion` endpoint with `json_schema` (not raw GBNF) for grammar-constrained parsing, the `range_request` package for model download with resume, and temperature=0 + fixed seed + single slot for deterministic output. Do NOT bundle models -- download on-demand only.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Per-import parser choice dialog -- user selects "快速解析（启发式）" or "高精度解析（LLM）" on every import. Choice is NOT persisted.
- **D-02:** Both parser engines share ImportPreviewScreen. Mark parse source on candidate cards (`LLM` / `启发式` / `兜底`).
- **D-03:** Independent model management page (`/settings/models`) in Settings.
- **D-04:** Three preset model tiers: Recommended (Qwen2.5-1.5B Q4_K_M, ~1.0 GB), Fast (Qwen2.5-0.5B Q4_K_M, ~0.5 GB), Experimental (Qwen2.5-3B Q4_K_M, ~2.0 GB). Download on demand only -- no auto-download.
- **D-05:** In-app HTTP download with progress bar, speed display, and resume (HTTP Range). Sha256 integrity check post-download. Models stored in `PathResolver.modelsDir`.
- **D-06:** User can add custom models via URL paste or local file picker. Format validation: .gguf extension + magic number (`0x47 0x47 0x55 0x46` = "GGUF").
- **D-07:** Extend ImportNotifier pipeline with `llmParsing` sub-phase in `ImportPhase` enum.
- **D-08:** LLM results auto-confirmed (all candidates marked confirmed, skip per-question review).
- **D-09:** Per-question failure: 3 retries -> heuristic fallback -> parse_log recorded -> summary screen shows parse source per question.

### Claude's Discretion
- `LlmClient` abstract interface signature (parse method, return type, error types)
- GBNF grammar file format and schema validation logic
- Chunking strategy implementation (how to split raw text by question number)
- Model download implementation details (download directory, concurrency, Sha256 verification)
- FFI spike go/no-go criteria and evaluation report format
- Model management page UI layout and interaction
- Import mode selection dialog UI design

### Deferred Ideas (OUT OF SCOPE)
- macOS/iOS LLM support -- v1 does not target these platforms
- FFI binding as default implementation -- depends on Plan 03-07 spike outcome
- Model auto-update checking -- v1 users manage model versions manually
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| IMP-03 | Desktop app invokes local on-device small LLM to parse raw text into structured questions | Sections 3, 4, 5, 6 -- llama.cpp HTTP API + GBNF grammar + Qwen2.5 models |
| IMP-04 | Parse progress shown with failure reasons; retry on failure | Sections 11, 12 -- HttpLlmClient retry + fallback + parse_log integration |
</phase_requirements>

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| llama.cpp server | latest stable (b5000+) | Local LLM HTTP server; hosts Qwen2.5 GGUF model on `localhost:8080` | Only production-grade C++ inference engine for GGUF; widely deployed; supports grammar-constrained decoding natively |
| Qwen2.5-1.5B-Instruct Q4_K_M | GGUF v3 | Default parsing model; ~0.99 GB file, ~2-3 GB RAM at runtime | Best quality/speed balance for Chinese exam text; Qwen family is state of art for Chinese NLP; Q4_K_M quantization preserves ~96% quality at 1/4 size [VERIFIED: HuggingFace Qwen org, multiple community repos] |
| Qwen2.5-0.5B-Instruct Q4_K_M | GGUF v3 | Fast tier model; ~0.5 GB file, ~1-2 GB RAM | For low-memory machines; usable but lower parse accuracy [VERIFIED: HuggingFace Qwen org] |
| Qwen2.5-3B-Instruct Q4_K_M | GGUF v3 | Experimental tier model; ~1.93 GB file, ~4 GB+ RAM | Highest quality; for complex question banks [VERIFIED: HuggingFace Qwen org] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `http` (dart-lang) | ^1.2.0+ | HTTP client for POST to llama.cpp `/completion` and GET model download | All `HttpLlmClient` calls; model download requests (Range header support) |
| `crypto` (dart-lang) | ^3.0.7 | SHA-256 hash computation for model integrity verification | Post-download model validation; compute hash of downloaded .gguf file |
| `range_request` | ^0.2.0 | Parallel chunked download with auto-resume, progress callbacks, SHA256 verification | Model download (1-2 GB files); provides resume after interruption [VERIFIED: pub.dev] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| llama.cpp HTTP server | Ollama | Ollama adds an extra daemon layer; llama.cpp server is the direct upstream and gives us full control over API parameters (grammar, seed, samplers). Ollama's API wrapper adds abstraction overhead and potential version lag. |
| `range_request` for download | Manual `http` Range header | `range_request` handles chunk concurrency, resume state persistence, progress streaming, and fallback-to-serial transparently. Manual implementation would be 200+ lines of error-prone code. |
| Qwen2.5-1.5B | Phi-3-mini / Gemma 2 2B | Qwen family trains extensively on Chinese text; Phi and Gemma are English-primary. For Chinese exam question parsing, Qwen's tokenizer and training data are significantly better. |

**Installation:**
```bash
flutter pub add http crypto range_request
```

**Version verification:** The `crypto` package is at 3.0.7 (Nov 2025) [VERIFIED: pub.dev feed]. `http` is maintained under `dart-lang/http` and is compatible with the project's Dart SDK ^3.12.2. `range_request` 0.2.0 requires Dart ^3.8.0 which is satisfied by the project's Flutter 3.44.2 (bundled Dart 3.12.2) [CITED: pub.dev/range_request].

## Architecture Patterns

### Recommended Project Structure

```
lib/
├── data/
│   └── llm_client/              # LlmClient interface + implementations
│       ├── llm_client.dart       # Abstract interface (parse method)
│       ├── stub_llm_client.dart  # Canned fixture for dev/CI
│       ├── http_llm_client.dart  # POST to localhost:8080/completion
│       ├── llm_error.dart        # Structured error types
│       └── providers.dart        # Riverpod llmClientProvider + llmModeProvider
├── features/
│   └── import/
│       ├── parsing/
│       │   ├── llm/              # LLM parsing sub-module
│       │   │   ├── chunker.dart          # Split raw text by question number
│       │   │   ├── canonicalizer.dart    # "AB"/"A,B"/"A和B" -> ["A","B"]
│       │   │   └── grammar_builder.dart  # Generate JSON Schema for GBNF converter
│       │   ├── heuristic_parser.dart     # Existing -- used as fallback
│       │   └── parse_candidate.dart      # Existing -- output format for both parsers
│       └── providers/
│           ├── import_state.dart         # Extended: ImportPhase.llmParsing
│           └── import_notifier.dart      # Extended: llmParse branch
├── features/
│   └── models/                   # Model management feature
│       ├── screens/
│       │   └── model_management_screen.dart  # /settings/models
│       ├── widgets/
│       │   ├── model_card.dart            # Tier badge + metadata + download btn
│       │   ├── download_progress.dart     # LinearProgressIndicator + speed
│       │   └── add_model_dialog.dart      # URL or local file input
│       ├── providers/
│       │   ├── model_catalog_provider.dart # 3-tier catalog data
│       │   ├── model_download_provider.dart # Download state + progress + resume
│       │   └── installed_models_provider.dart # Installed model list
│       └── services/
│           ├── model_downloader.dart      # HTTP Range download + SHA256 verify
│           └── gguf_validator.dart        # Magic number + extension check
└── assets/
    ├── grammar/
    │   └── question_schema.json   # JSON Schema for LLM output constraint
    └── fixtures/
        └── sample_llm_response.json  # StubLlmClient canned data
```

### Pattern 1: Swappable LlmClient via Riverpod Override

**What:** `LlmClient` is an abstract interface. Riverpod provides the concrete implementation: `StubLlmClient` (dev/CI), `HttpLlmClient` (production), or future `FfiLlmClient`. The `llmModeProvider` selects which implementation is active. The parse pipeline calls `ref.read(llmClientProvider)` and never knows which implementation is behind it.

**When to use:** All parse pipeline code. The `ImportNotifier` should only depend on `LlmClient`, never a concrete class.

**Example:**
```dart
// Source: Established Riverpod pattern from Phase 1/2 codebase
// lib/data/llm_client/llm_client.dart
abstract interface class LlmClient {
  /// Parse raw question text into a structured candidate.
  /// Throws [LlmTimeoutException] on timeout.
  /// Throws [LlmJsonParseException] when GBNF output is still malformed.
  Future<ParseCandidate> parse(String rawText, {String? bankName});
}

// lib/data/llm_client/providers.dart
@riverpod
LlmClient llmClient(Ref ref) {
  throw UnsupportedError('LLM is desktop-only; use JSON import on Android');
}

// Desktop override (lib/desktop/providers.dart or platform-gated)
@riverpod
LlmClient desktopLlmClient(Ref ref) {
  final mode = ref.watch(llmModeProvider);
  return switch (mode) {
    LlmMode.stub => StubLlmClient(),
    LlmMode.http => HttpLlmClient(serverUrl: 'http://localhost:8080'),
    LlmMode.ffi => throw UnimplementedError('FFI not available in Phase 3'),
  };
}
```

### Pattern 2: Question-By-Question Chunking + Per-Chunk LLM Call

**What:** Before sending to LLM, the raw text is split by question number pattern (`^\d+[.、]`) into individual question blocks. Each block is sent independently to `llmClient.parse()`. This prevents the LLM from truncating a 500-question bank and isolates failures to individual questions.

**When to use:** Always. Never send the entire extracted text to the LLM in one call.

**Example:**
```dart
// lib/features/import/parsing/llm/chunker.dart
final _questionBreakRE = RegExp(r'^\d+[.、)）]', multiLine: true);

List<String> splitIntoQuestionBlocks(String rawText) {
  final lines = rawText.split('\n');
  final blocks = <List<String>>[];
  var current = <String>[];

  for (final line in lines) {
    if (_questionBreakRE.hasMatch(line.trimLeft()) && current.isNotEmpty) {
      blocks.add(List.from(current));
      current = [line];
    } else {
      current.add(line);
    }
  }
  if (current.isNotEmpty) blocks.add(List.from(current));

  return blocks.map((b) => b.join('\n').trim()).toList();
}
```

### Pattern 3: Platform-Gated Provider (Desktop-Only LLM)

**What:** LLM-related Riverpod providers are gated at the provider level. On desktop (`Platform.isWindows || Platform.isLinux`), the provider resolves to an active `LlmClient`. On Android, accessing the provider throws `UnsupportedError`.

**When to use:** All LLM-related providers (`llmClientProvider`, `installedModelsProvider`, `modelDownloadProvider`, `modelCatalogProvider`).

**Example:**
```dart
// Pattern inherited from Phase 1/2 platform branching
// lib/data/llm_client/providers.dart
import 'dart:io' show Platform;

@riverpod
LlmClient llmClient(Ref ref) {
  if (!(Platform.isWindows || Platform.isLinux)) {
    throw UnsupportedError('LLM is desktop-only; use JSON import on Android');
  }
  final mode = ref.watch(llmModeProvider);
  return switch (mode) {
    LlmMode.stub => StubLlmClient(),
    LlmMode.http => HttpLlmClient(
      serverUrl: 'http://localhost:8080',
      timeout: const Duration(seconds: 30),
    ),
  };
}
```

### Anti-Patterns to Avoid

- **Batching questions into a single prompt:** The LLM will truncate at its context window (even with 32K). Always chunk by question number first.
- **Skipping the canonicalization layer:** LLM output for multi-choice answers may be `"AB"`, `"A,B"`, `"A和B"`, or `["A","B"]`. All must be normalized to a canonical `["A","B"]` before storage. Per PITFALL 5, this is a non-negotiable anti-pattern to skip.
- **Using `bool` for parse source:** Use an enum (`ParseSource.llm`, `.heuristic`, `.fallback`), not a boolean flag. A boolean cannot represent the 3-way distinction required by D-09.
- **Storing model files in assets:** GGUF files are 0.5-2.0 GB each. Bundling them would balloon APK size. Download on-demand to `PathResolver.modelsDir`.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| HTTP Range download with resume | Manual `Range` header + file append + state tracking | `range_request` ^0.2.0 | `range_request` handles chunk concurrency, resume state persistence, progress streaming, server Range support detection, and graceful fallback. Manual implementation is error-prone across 1-2 GB downloads over unstable connections. |
| SHA-256 file hash | Manual SHA-256 implementation | `crypto` ^3.0.7 (dart-lang official) | Industry-standard implementation with streaming support for large files via `startChunkedConversion()`. |
| GBNF grammar generation | Hand-writing GBNF rules | llama.cpp server auto-conversion from `json_schema` parameter | The server's `json_schema` parameter auto-converts JSON Schema to GBNF on every request. GBNF is complex to hand-write correctly (token-level constraints, property ordering, quantifier optimization). Let the server handle it. |
| JSON parsing from LLM output | Custom regex extraction | `dart:convert` `jsonDecode` + schema validation | GBNF guarantees valid JSON. If still malformed (edge case), `jsonDecode` is the standard path. Fall through to regex extraction only as last resort. |
| Answer canonicalization | Custom string splitting per input pattern | Single canonicalization function handling all known formats | The LLM outputs answer in varied formats. Writing per-format handlers creates maintenance burden. Build one function that maps all inputs to a sorted canonical list. |
| GGUF format validation | Manual binary parsing | Read first 4 bytes, compare to `[0x47, 0x47, 0x55, 0x46]` | This is actually trivial -- 4-byte magic number check. But do NOT build a full GGUF parser; we only need the magic number check for import validation. |

**Key insight:** The llama.cpp server already handles the hardest problem (grammar-constrained decoding). Do not try to validate LLM JSON output with regex or fuzzy matching -- GBNF grammar at the sampling level is the correct approach. The `json_schema` parameter on `/completion` makes this a one-liner.

## Runtime State Inventory

> Phase 3 introduces new state categories for model management -- files on disk and server processes -- that go beyond code changes. This inventory is required because Phase 3 involves system-level runtime state.

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| Stored data | None -- ParseLogs table already exists (Phase 1). Phase 3 writes to it but does not create new DB tables. `ParseCandidate.metadata` map may receive new keys (`source`, `fallbackReason`) -- data migration not needed since only new writes use them. | None |
| Live service config | llama.cpp server process (`llama-server`) must be running on `localhost:8080` for `HttpLlmClient` to work. This is NOT a service the app starts automatically in v1; user starts it manually or it's launched via a helper script. | Document in user-facing README. Future Phase (FFI spike) would eliminate this dependency. |
| OS-registered state | None | None |
| Secrets/env vars | None required. llama.cpp server runs unauthenticated on localhost by default. No API keys needed. | None |
| Build artifacts | None | None |

**Nothing found in category:** All categories verified by codebase audit (grep for existing state files, DB tables, OS registrations).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | All code | Check needed | 3.44.2 (per STATE.md) | -- |
| Dart SDK | All code | Check needed | 3.12.2 (bundled with Flutter) | -- |
| Dart `http` package | HttpLlmClient, model download | Not yet in pubspec | ^1.2.0+ (latest) | -- |
| Dart `crypto` package | SHA-256 model verification | Not yet in pubspec | ^3.0.7 (latest) | -- |
| Dart `range_request` package | Model download with resume | Not yet in pubspec | ^0.2.0 (latest) | Manual `http` Range header |
| llama.cpp server (`llama-server`) | HttpLlmClient (production) | NOT installed | -- | StubLlmClient for dev/CI; user installs for production |
| curl | Manual testing of llama.cpp API | Available | Present | -- |

**Missing dependencies with no fallback:**
- `llama-server` binary -- required for production LLM parsing. Not an application dependency; it's a user-installed tool. The application should detect its absence and show a helpful message directing users to download from [llama.cpp releases](https://github.com/ggml-org/llama.cpp/releases).

**Missing dependencies with fallback:**
- `range_request` -- falls back to manual `http` Range header implementation if incompatible with project SDK.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | flutter_test (built-in) |
| Config file | none -- default flutter_test config |
| Quick run command | `flutter test` |
| Full suite command | `flutter test --coverage` |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| IMP-03 | `HttpLlmClient` sends correct POST body to `/completion` with `json_schema`, `temperature: 0`, fixed seed | unit | `flutter test test/data/llm_client/http_llm_client_test.dart` | No (Wave 0) |
| IMP-03 | `StubLlmClient` returns pre-canned ParseCandidate from fixture JSON | unit | `flutter test test/data/llm_client/stub_llm_client_test.dart` | No (Wave 0) |
| IMP-03 | Chunker correctly splits multi-question text by `^\d+[.、]` | unit | `flutter test test/features/import/parsing/llm/chunker_test.dart` | No (Wave 0) |
| IMP-03 | Canonicalizer normalizes `"AB"`, `"A,B"`, `"A和B"`, `["A","B"]` to `["A","B"]` | unit | `flutter test test/features/import/parsing/llm/canonicalizer_test.dart` | No (Wave 0) |
| IMP-03 | Platform gating: Android `llmClientProvider` throws `UnsupportedError` | widget | `flutter test test/data/llm_client/platform_gate_test.dart` | No (Wave 0) |
| IMP-04 | HttpLlmClient retries 3 times on timeout, then throws `LlmRetryExhaustedException` | unit | `flutter test test/data/llm_client/http_llm_client_test.dart` | No (Wave 0) |
| IMP-04 | ImportNotifier.llmParsing phase: per-chunk failure -> heuristic fallback -> parse_log written | integration | `flutter test test/features/import/pipeline_integration_test.dart` | Yes (extend existing) |
| IMP-03 | Model downloader computes correct SHA-256 and verifies download integrity | unit | `flutter test test/features/models/model_downloader_test.dart` | No (Wave 0) |
| IMP-03 | GGUF validator accepts valid magic number `.gguf`, rejects `.exe` and wrong-magic files | unit | `flutter test test/features/models/gguf_validator_test.dart` | No (Wave 0) |

### Sampling Rate
- **Per task commit:** `flutter test test/data/llm_client/ test/features/import/parsing/llm/`
- **Per wave merge:** `flutter test`
- **Phase gate:** Full suite green + coverage >= 80% before `/gsd-verify-work`

### Wave 0 Gaps
- `test/data/llm_client/http_llm_client_test.dart` -- covers IMP-03 HttpLlmClient contract, IMP-04 retry
- `test/data/llm_client/stub_llm_client_test.dart` -- covers IMP-03 StubLlmClient
- `test/features/import/parsing/llm/chunker_test.dart` -- covers question block splitting
- `test/features/import/parsing/llm/canonicalizer_test.dart` -- covers answer normalization
- `test/data/llm_client/platform_gate_test.dart` -- covers Android UnsupportedError
- `test/features/models/model_downloader_test.dart` -- covers download + SHA-256
- `test/features/models/gguf_validator_test.dart` -- covers magic number validation
- `test/features/models/grammar_builder_test.dart` -- covers JSON Schema generation
- Test dependency setup: `test/features/models/` needs `crypto` and `http` packages available (add to dev_dependencies if needed; they are already in dependencies)

## Common Pitfalls

### Pitfall 1: LLM JSON Output Format Drift Under GBNF

**What goes wrong:** Even with GBNF grammar, the LLM may produce structurally valid JSON with semantically wrong field contents (e.g., `"answer": "因为A选项正确"` instead of `"answer": "A"`). The GBNF ensures valid JSON structure but NOT semantic correctness.

**Why it happens:** GBNF constrains token sampling to valid JSON syntax. It cannot enforce that the `answer` field contains only letter options or that `options` array contains exactly the choices from the text. The 1.5B model has limited instruction-following capability.

**How to avoid:**
1. **Post-parse validation layer:** After `jsonDecode`, validate: `answer` matches `^[A-H]+$`, `options` count >= 2, `title` is non-empty, `type` is not `unknown`
2. **Fail closed:** Reject candidates that fail validation; trigger retry or fallback
3. **Prompt engineering:** End prompt with "Answer MUST be one or more letters from A-H with no other text."
4. **Canonicalization:** Strip all non-letter characters from the answer field

**Warning signs:** Parse success count matches question count but some answers are full sentences. Multi-choice answers like `"A和B都正确"`.

### Pitfall 2: Temperature=0 Not Truly Deterministic Across Setups

**What goes wrong:** The same raw text parsed 10 times on the same machine with `temperature=0` + `seed=42` should produce identical output. But across different CPU architectures, operating systems, or llama.cpp versions, the output may diverge slightly due to floating-point differences.

**Why it happens:** CPU-only llama.cpp with `temperature=0`, fixed seed, single slot, and `cache_prompt: false` is the most deterministic path. However, floating-point math differences across CPU microarchitectures (AVX2 vs AVX-512 vs NEON) introduce subtle variations that can change token selection at decision boundaries. [VERIFIED: llama.cpp issue #7052]

**How to avoid:**
1. For the success criterion "byte-identical output 10 times on same machine" -- this IS achievable with CPU-only + single slot + no cache.
2. Store `parse_seed` in metadata for reproducibility within a user's session.
3. Do not claim byte-identical output across different user machines.
4. For CI testing: use `StubLlmClient` (deterministic by design) rather than requiring a live llama.cpp server.

**Warning signs:** CI tests that start a llama.cpp server and expect exact output strings will be flaky across CI runners with different CPUs.

### Pitfall 3: llama.cpp Server Not Running

**What goes wrong:** User selects "高精度解析（LLM）", but `llama-server` is not started. `HttpLlmClient` tries to POST to `localhost:8080` and gets a connection refused error.

**Why it happens:** llama.cpp server is a separate process the user must start. In v1, the app does not manage the server lifecycle (FFI spike in Plan 03-07 would change this).

**How to avoid:**
1. **Health check:** Before showing the parser choice dialog, probe `GET http://localhost:8080/health` (if available) or `GET http://localhost:8080/` to see if the server is running.
2. **Clear error message:** "尚未连接LLM服务。请先启动 llama-server 并加载模型。" with a link to documentation.
3. **Detection in parser choice dialog:** Disable the LLM option with a helpful message if the server is unreachable (distinct from "no model installed").
4. **Documentation:** Ship a `LLM_SETUP.md` or include setup instructions in README.

**Warning signs:** Users report "LLM parsing never starts" or "stuck at 0%". No error in app logs because `HttpLlmClient` connection timeout is the only symptom.

### Pitfall 4: GBNF json_schema Parameter Requires Correct Llamacpp Version

**What goes wrong:** Older llama.cpp builds (pre-2024) do not support the `json_schema` parameter. Only the raw `grammar` string was supported. If the user has an old llama-server, the `json_schema` parameter is silently ignored and the LLM output is unconstrained.

**Why it happens:** `json_schema` auto-conversion was added in PR #5978 (mid-2024). Users who installed llama.cpp earlier may not have this feature.

**How to avoid:**
1. **Document minimum version:** Require llama.cpp b4000+ (or specific release after June 2024).
2. **Version check:** Probe the server (e.g., check response headers or `/props` endpoint) to detect whether `json_schema` is supported.
3. **Fallback to raw GBNF:** Generate GBNF grammar string offline (check in `assets/grammar/question.gbnf`) as a fallback for older servers.
4. **Recommend current release:** Link to latest llama.cpp release in setup docs.

**Warning signs:** LLM returns prose text instead of JSON despite `json_schema` being set. Output matches prompt instructions but not JSON format.

### Pitfall 5: Multiple Simultaneous Downloads

**What goes wrong:** User clicks "下载" on two model cards simultaneously. Both downloads saturate bandwidth, compete for disk I/O, and may cause memory pressure.

**Why it happens:** Each download button is independent; without global download state management, concurrent downloads occur.

**How to avoid:**
1. **Global download queue:** A single `modelDownloadProvider` that enforces at most one active download.
2. **Disable other download buttons:** While one download is active, other cards show "等待中" (disabled state).
3. **Cancel current download:** User can cancel the active download before starting a new one.

**Warning signs:** Two progress bars moving simultaneously. Disk space calculation becomes unreliable. Network errors interleave.

## Code Examples

Verified patterns from official sources:

### llama.cpp /completion Request (Question Parsing)

```dart
// Source: llama.cpp server README (verified via web search 2026-06)
// POST http://localhost:8080/completion
final response = await http.post(
  Uri.parse('http://localhost:8080/completion'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'prompt': '''
Extract the following Chinese exam question into JSON.
Question text:
$questionBlock

Output ONLY valid JSON matching the schema. No prose. End with }.
''',
    'n_predict': 512,
    'temperature': 0.0,
    'seed': 42,
    'json_schema': {
      'type': 'object',
      'properties': {
        'title': {'type': 'string', 'minLength': 1},
        'type': {'type': 'string', 'enum': ['single', 'multiple', 'truefalse', 'unknown']},
        'options': {
          'type': 'array',
          'items': {'type': 'string'},
          'minItems': 2, 'maxItems': 8
        },
        'answer': {'type': 'string', 'minLength': 1},
        'explanation': {'type': 'string'}
      },
      'required': ['title', 'type', 'options', 'answer'],
      'additionalProperties': false
    },
    'stop': ['\n\n'],
    'stream': false,
    'cache_prompt': false,
  }),
).timeout(const Duration(seconds: 30));
```

### llmClientProvider with Platform Gate

```dart
// Source: Phase 1/2 existing pattern + CONTEXT.md D-02
import 'dart:io' show Platform;

enum LlmMode { stub, http }

@riverpod
LlmMode llmMode(Ref ref) => LlmMode.stub; // default; overridden in settings

@Riverpod(keepAlive: true)
LlmClient llmClient(Ref ref) {
  if (!(Platform.isWindows || Platform.isLinux)) {
    throw UnsupportedError('LLM is desktop-only; use JSON import on Android');
  }
  final mode = ref.watch(llmModeProvider);
  return switch (mode) {
    LlmMode.stub => StubLlmClient(),
    LlmMode.http => HttpLlmClient(serverUrl: 'http://localhost:8080'),
  };
}
```

### GGUF Magic Number Validation

```dart
// Source: GGUF specification (verified via Wikipedia + ggml docs)
// The GGUF magic number is 0x47 0x47 0x55 0x46 = "GGUF" in ASCII
static const _ggufMagic = [0x47, 0x47, 0x55, 0x46]; // "GGUF"

Future<bool> isGgufFile(String filePath) async {
  final file = File(filePath);
  if (!file.path.endsWith('.gguf')) return false;
  try {
    final bytes = await file.openRead(0, 4).first;
    return bytes.length == 4 &&
           bytes[0] == _ggufMagic[0] &&
           bytes[1] == _ggufMagic[1] &&
           bytes[2] == _ggufMagic[2] &&
           bytes[3] == _ggufMagic[3];
  } catch (_) {
    return false;
  }
}
```

### SHA-256 Verification for Downloaded Model

```dart
// Source: dart-lang crypto package documentation
// Use streaming hash for large files (1-2 GB)
import 'dart:io';
import 'package:crypto/crypto.dart';

Future<String> sha256OfFile(String filePath) async {
  final file = File(filePath);
  final digest = await sha256.bind(file.openRead()).first;
  return digest.toString();
}
```

### Canonicalization of LLM Answer Output

```dart
// Source: PITFALL 5 research -- canonicalize all answer formats to sorted list
/// Normalizes LLM answer output to a canonical sorted list of uppercase letters.
/// Handles: "AB", "A,B", "A、B", "A和B", "A B", '["A","B"]', "A, B"
List<String> canonicalizeAnswer(String rawAnswer) {
  // Try to decode as JSON array first: ["A","B"]
  try {
    final decoded = jsonDecode(rawAnswer);
    if (decoded is List) {
      return decoded.map((e) => e.toString().toUpperCase().trim())
          .where((e) => RegExp(r'^[A-H]$').hasMatch(e))
          .toList()..sort();
    }
  } catch (_) {}

  // Extract all single capital letters A-H
  final letters = RegExp(r'[A-Ha-h]')
      .allMatches(rawAnswer)
      .map((m) => m.group(0)!.toUpperCase())
      .toSet()
      .toList()
    ..sort();

  return letters;
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| llama.cpp `/v1/completions` (OpenAI-compat) | llama.cpp `/completion` (native) with `json_schema` | Mid-2024 (PR #5978) | Native endpoint has richer features: `json_schema` at top level, `cache_prompt`, `response_fields`, `id_slot`. For grammar-constrained parsing, native endpoint is preferred. |
| Raw GBNF grammar string | `json_schema` auto-conversion | Mid-2024 (PR #5978) | No need to hand-write GBNF. Server converts JSON Schema to GBNF on every request. This is our recommended approach. |
| GGML format | GGUF v3 format | Aug 2023 (llama.cpp community) | GGUF is the standard. All models on HuggingFace use GGUF. GGML is obsolete. |
| Ollama as model server | Direct llama.cpp server | Ongoing trend | llama.cpp server now supports OpenAI-compatible endpoints, tool calling, and grammar constraints -- reducing the need for Ollama's wrapper layer. |

**Deprecated/outdated:**
- **GGML format:** All references to `.ggml` files are obsolete. Use GGUF exclusively.
- **`/v1/chat/completions` for structured extraction:** The chat endpoint wraps the grammar in `response_format` nesting. The native `/completion` endpoint with top-level `json_schema` is simpler and less error-prone for our extraction use case.
- **Ollama as a dependency:** Phase 3 targets llama.cpp server directly. Ollama adds unnecessary daemon management complexity for a desktop app that already needs to manage its own model files.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | llama.cpp server `/completion` endpoint `json_schema` parameter is available in builds from mid-2024 forward (b4000+) [CITED: PR #5978, web search] | Code Examples | If user has an older llama.cpp build, `json_schema` is silently ignored. Mitigation: version detection + fallback to raw GBNF. |
| A2 | `range_request` ^0.2.0 is compatible with Dart SDK ^3.12.2 (project's SDK) [CITED: pub.dev shows ^3.8.0 minimum] | Standard Stack | If incompatible, fall back to manual `http` Range header implementation (~200 LoC). |
| A3 | Qwen2.5 models remain available on HuggingFace under `Qwen/Qwen2.5-{size}-Instruct-GGUF` [VERIFIED: HuggingFace Qwen org] | Standard Stack | If Qwen organization removes or reorganizes repos, update download URLs. Community mirrors exist (tensorblock, mradermacher). |
| A4 | Qwen2.5-1.5B Q4_K_M produces acceptable parse quality on Chinese exam text without fine-tuning [CITED: Qwen bench evaluations, PITFALL 1] | Standard Stack | If quality is insufficient on real Chinese university exam text, may need prompt engineering iterations or a different model. Plan 03-04 grammar/validation layer provides defense-in-depth. |
| A5 | CPU-only llama.cpp with temperature=0, fixed seed, single slot, no cache produces reproducible output on the same machine [CITED: llama.cpp issues #7052, #4902] | Common Pitfalls | Non-reproducible output across different CPU architectures. Mitigated by the success criterion specifically scoped to "same machine 10 times." |

**If this table has Assumptions A1 and A2:** These are the highest-risk items because they depend on external software versions. The planner should add a Wave 0 verification step for each.

## Open Questions

1. **Qwen2.5 vs Qwen3 for Chinese exam text parsing**
   - What we know: Qwen2.5-1.5B-Instruct is the CONTEXT.md specified model. Qwen3 has been released since then. Qwen3-1.7B may offer better instruction following at similar size.
   - What's unclear: Whether Qwen3 GGUF models are available on HuggingFace and whether they represent a drop-in improvement for our use case.
   - Recommendation: Build the model catalog as configurable -- store model metadata (size, tier, download URL, model name) in a catalog data structure, not hardcoded. This allows adding Qwen3 models without code changes. Start with Qwen2.5 as specified, add Qwen3 as a "faster recommended" option if investigation shows it works well.

2. **llama.cpp server minimum version for `json_schema` support**
   - What we know: PR #5978 added `json_schema` support. This was merged in mid-2024.
   - What's unclear: The exact minimum build number (`b4300? b4500?`). The `/props` endpoint can be queried for server capabilities.
   - Recommendation: Generate a raw GBNF grammar string from the JSON Schema at build time (check into `assets/grammar/question.gbnf`) as a fallback. Use the GBNF string via the `grammar` parameter if `json_schema` is not supported. This eliminates the version dependency entirely.

3. **Actual parse quality of Qwen2.5-1.5B on real Chinese university exam text**
   - What we know: Benchmarks show Qwen2.5 performs well on Chinese NLP tasks. Real exam text with complex formatting, multi-line stems, and mixed numbering schemes may be harder.
   - What's unclear: The gap between benchmark scores and real-world parsing accuracy on the `doc/example/` sample files.
   - Recommendation: The `StubLlmClient` enables developing and testing the full parse pipeline without a model. The `HttpLlmClient` makes it easy to swap models. Plan a manual validation step: run all 4 sample files through each model tier and record accuracy. This informs which model is truly "Recommended."

4. **llama.cpp server discovery and lifecycle**
   - What we know: Users must manually start `llama-server` in v1 (FFI spike would change this).
   - What's unclear: What UX flow to use for first-time setup. Should the app detect missing server and offer to download both the server binary AND a model?
   - Recommendation: v1 scope is: user manually installs llama.cpp and starts the server. The app detects server availability and shows helpful error messages. Full integrated server lifecycle management is deferred to FFI spike (Plan 03-07) or a future phase.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | llama.cpp server runs on localhost only; no authentication needed |
| V3 Session Management | No | Stateless HTTP calls; no sessions |
| V4 Access Control | No | localhost-only; OS-level firewall sufficient |
| V5 Input Validation | Yes | Validate LLM output against question JSON schema; reject malformed candidates; sanitize model file downloads (magic number check) |
| V6 Cryptography | Yes | SHA-256 for model file integrity verification via `crypto` package; GGUF files are downloaded over HTTPS (HuggingFace CDN enforces HTTPS) |

### Known Threat Patterns for llama.cpp HTTP Local Server

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Malicious `.gguf` file with crafted metadata | Tampering | SHA-256 verification against known hash; magic number validation; only download from trusted HuggingFace repos |
| LLM prompt injection via crafted question text in `.docx` | Spoofing | LLM output is constrained by GBNF grammar (only valid JSON structure); post-parse validation rejects semantically invalid fields. GBNF prevents the LLM from being jailbroken into outputting arbitrary text. |
| Localhost port conflict (another process on 8080) | Denial of Service | Make server port configurable via `llmModeProvider` settings; validate response is from llama.cpp (check for expected response fields) |
| Man-in-the-middle on model download | Information Disclosure | HTTPS enforced for all HuggingFace downloads; SHA-256 verification catches tampered files regardless of transport security |

## Sources

### Primary (HIGH confidence)
- llama.cpp server README (official) -- `/completion` endpoint parameters: `prompt`, `n_predict`, `temperature`, `seed`, `grammar`, `json_schema`, `stream`, `cache_prompt`, `stop`, `samplers`. [VERIFIED: web search, multiple GitHub mirrors]
- llama.cpp grammar README (`ggml-org/llama.cpp/grammars/README.md`) -- GBNF syntax specification, JSON Schema auto-conversion, known limitations. [VERIFIED: web search]
- llama.cpp server changelog (Issue #9291) -- REST API changes; PR #5978 added `json_schema` parameter to `/completion`. [VERIFIED: web search]
- HuggingFace `Qwen/Qwen2.5-{size}-Instruct-GGUF` repos -- Model file sizes, download URLs using `/resolve/main/` pattern. [VERIFIED: HuggingFace Qwen org]
- `pub.dev/packages/crypto` version feed -- v3.0.7 released Nov 2025. [VERIFIED: pub.dev API]
- `pub.dev/packages/range_request` -- v0.2.0, Dart SDK ^3.8.0 requirement. [VERIFIED: pub.dev]
- GGUF specification -- Magic number `0x47 0x47 0x55 0x46` = "GGUF" at offset 0. [VERIFIED: Wikipedia, ggml docs]

### Secondary (MEDIUM confidence)
- llama.cpp Issue #7052 (multi-slot non-determinism) -- Floating-point ordering differences across slots. [CITED: ggml-org/llama.cpp]
- llama.cpp Issue #4902 (cache_prompt breaks determinism) -- Enabling caching with temperature=0 produces random output. [CITED: ggml-org/llama.cpp]
- llama.cpp Issue #10197 (AMD ROCm non-determinism) -- GPU backend non-determinism even with temperature=0. CPU not affected. [CITED: ggml-org/llama.cpp]
- PITFALLS.md (Phase 1/2 research) -- LLM JSON drift (PITFALL 1), answer stringification (PITFALL 5), chunking strategy (PITFALL 6). [VERIFIED: project file]

### Tertiary (LOW confidence)
- Dart `http` package latest version -- Web search results incomplete. [ASSUMED: ^1.2.0+ based on known release cadence]
- HuggingFace exact download URL format stability -- The `/resolve/main/` pattern works as of 2026. [ASSUMED: HuggingFace could change URL structure; community relies on this pattern]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- llama.cpp server API is well-documented; Qwen2.5 GGUF models are officially published; Dart packages are on pub.dev with version history.
- Architecture: HIGH -- Patterns drawn from existing Phase 1/2 codebase (Riverpod, platform gating, feature-first structure). The `LlmClient` abstraction follows the same strategy pattern used elsewhere in the project.
- Pitfalls: MEDIUM-HIGH -- Primarily sourced from llama.cpp GitHub issues (real bug reports) and project's own PITFALLS.md research. The temperature=0 determinism edge case has multiple verified sources.

**Research date:** 2026-06-19
**Valid until:** 2026-08-19 (llama.cpp and Qwen models update frequently; re-verify model download URLs and server API before implementing Plan 03-03)
