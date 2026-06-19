# Concerns & Technical Debt

## Active Concerns

### 1. `.doc` Binary Format — No Pure Dart Solution (HIGH)

**File:** Phase 2 scope expansion (02-CONTEXT.md D-04)

Word 97-2003 `.doc` files use OLE2 Compound File Binary Format — there is no known pure-Dart library for reading this format. Options:
- **pandoc CLI** — requires separate install, adds deployment complexity
- **LibreOffice headless** — heavyweight dependency, may not work on all Linux distros
- **Windows COM interop** — Windows-only, breaks cross-platform

**Status:** Researcher must evaluate during Phase 2 planning.

### 2. Phase 3 LLM FFI — No Cross-Platform Dart Wrapper (HIGH)

**File:** `.planning/research/PITFALLS.md` (Pitfall 4)

llama.cpp has no pub.dev wrapper covering both Windows + Linux. Expected 1-2 weeks of FFI shim work.
- `dart:ffi` → `libllama.dll` (Windows) / `libllama.so` (Linux)
- Memory management: 1.5B Q4_K_M model needs ~2-2.5 GB peak RAM
- HTTP-only fallback documented but requires network dependency

### 3. Android NDK Not Installed (MEDIUM)

**File:** `01-06-SMOKE-REPORT.md`

Android build cannot be verified — NDK download requires ~2 GB disk space. This blocks:
- Real Android smoke testing
- `sqlite3_flutter_libs` Android .so verification
- Future platform-specific debugging

**Mitigation:** CI/CD can handle Android builds when available. Current priority is Windows + Linux.

### 4. HomeScreen `ignore_for_file` Pragmas (LOW)

**File:** `lib/features/home/presentation/home_screen.dart`

```dart
// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
```

HomeScreen uses `Card(child: InkWell(...))` — the `InkWell` can't be `const` because `onTap` closures are runtime. The ignore was added in Plan 01-05 as a pragmatic compromise. Future refactoring could extract card content into separate const widgets.

### 5. No Error/Empty/Loading State Widgets (LOW)

No standardized `ErrorWidget`, `EmptyStateWidget`, or `LoadingWidget` exist. These will be needed for:
- Phase 2: file parse errors, empty preview
- Phase 3: model load errors, OOM
- Phase 4: empty quiz banks

### 6. No Logging Framework (LOW)

`print()` is banned by lint, but no structured logging (e.g., `package:logging`) is configured. Diagnostic data is expected in Phase 6.

## Technical Debt Register

| ID | Item | Severity | Phase to Fix | Owner |
|----|------|----------|-------------|-------|
| TD-01 | `ignore_for_file` on HomeScreen | Low | 5 (UX polish) | — |
| TD-02 | No error/empty/loading widget library | Medium | 2 (first real data flow) | — |
| TD-03 | No structured logging | Low | 6 (diagnostics) | — |
| TD-04 | `.doc` format parsing strategy undefined | High | 2 (research phase) | — |

## Security

- **No secrets in codebase** — verified; zero API keys, tokens, or credentials
- **`hooks.user_defines.sqlite3.source: system`** in pubspec.yaml — uses system SQLite, no network download
- **No auth system** — app is fully offline, no user accounts planned
- **SQL injection:** drift's query builder uses parameterized queries by default — safe

## Performance

- **Startup:** `PathResolver.create()` runs async before `runApp()` — no measurable delay
- **DB:** WAL mode enables concurrent reads; single-threaded writes acceptable for single-user desktop app
- **Memory:** No large assets loaded at startup; LLM model loading (Phase 3) is the only anticipated memory pressure point

## Deferred Items

- `riverpod_lint` / `custom_lint` → re-add when `custom_lint` supports analyzer ^10.0.0
- `intl` localization → Phase 5
- Android NDK install → when disk space allows or CI available
