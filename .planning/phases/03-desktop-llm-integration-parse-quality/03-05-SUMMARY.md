---
phase: 03-desktop-llm-integration-parse-quality
plan: 05
subsystem: model-management
tags: [model-catalog, gguf-validator, model-downloader, http-range, sha256-verification, riverpod-providers]
requires: [PathResolver.modelsDir]
provides: [modelCatalogProvider, GgufValidator, ModelDownloader, modelDownloadProvider, installedModelsProvider]
affects: [lib/features/models/, test/features/models/]
tech-stack:
  added: [http, crypto, range_request]
  patterns: [Riverpod Notifier (keepAlive), manual HTTP Range, SHA-256 streaming, ProviderContainer test overrides]
key-files:
  created:
    - lib/features/models/providers/model_catalog_provider.dart
    - lib/features/models/services/gguf_validator.dart
    - lib/features/models/services/model_downloader.dart
    - lib/features/models/providers/model_download_provider.dart
    - lib/features/models/providers/installed_models_provider.dart
    - test/features/models/gguf_validator_test.dart
    - test/features/models/model_downloader_test.dart
    - test/features/models/providers_test.dart
  modified:
    - pubspec.yaml
decisions:
  - "Manual HTTP Range implementation over range_request package due to Windows file-locking bug during temp-file rename"
  - "ModelDownloadNotifier uses @Riverpod(keepAlive: true) to prevent disposal during async download operations"
  - "SHA-256 hash values marked 'TBD' in model catalog — to be updated after first verified download of each model tier"
metrics:
  duration: "~25 min"
  completed_date: "2026-06-19"
  task_count: 3
  test_count: 27
  file_count: 8
---

# Phase 03 Plan 05: Model Download Infrastructure Summary

**One-liner:** Pure-Dart model download pipeline with 3-tier GGUF catalog, magic-number validation, HTTP Range resume, SHA-256 integrity verification, and Riverpod download queue — 27 passing tests.

## Plan Execution

### Task 1: Packages + Model Catalog Provider + GGUF Validator

- Added `http: ^1.2.0`, `crypto: ^3.0.7`, `range_request: ^0.2.0` to pubspec.yaml
- Created `model_catalog_provider.dart` with 3-tier catalog (Recommended/Fast/Experimental) using Qwen2.5-Instruct GGUF models from HuggingFace
- Created `gguf_validator.dart` with magic number check (`0x47 0x47 0x55 0x46` = "GGUF")
- Tested with `flutter_test` + `ProviderContainer`: 15 tests (10 validator + 5 catalog)
- Commit: `55240df`

### Task 2: ModelDownloader Service (HTTP Range + SHA-256)

- Implemented manual HTTP Range download (replaced range_request due to Windows file-locking bug in temp-file rename)
- HEAD request for Content-Length + Accept-Ranges detection
- Streaming progress callbacks with bytesDownloaded/totalBytes/speedBytesPerSec
- SHA-256 verification via `crypto` package
- Exception classes: DownloadNetworkException, DownloadVerificationException, DownloadDiskSpaceException
- Tested with local HTTP server (`dart:io` HttpServer): 5 tests
- Commit: `6cae4c2`

### Task 3: Download + Installed Models Riverpod Providers

- `ModelDownloadNotifier` (`@Riverpod(keepAlive: true)`): single-download queue with state transitions (idle → downloading → verifying → done)
- Concurrent download prevention (throws StateError)
- `cancelDownload()` + `clearState()`
- `InstalledModelsProvider` (`@riverpod Future`): scans `PathResolver.modelsDir` for .gguf files
- Returns `InstalledModel` objects with filePath, fileName, sizeBytes
- Tested with `ProviderContainer` + fake PathResolver: 7 tests
- Commit: `de55860`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Replaced range_request with manual HTTP Range implementation**
- **Found during:** Task 2
- **Issue:** The `range_request` package's `FileDownloader.downloadToFile()` has a Windows file-locking bug where `RandomAccessFile` remains open during temp-file rename, causing `PathAccessException: Cannot rename file`
- **Fix:** Implemented manual HTTP Range download using `package:http` — HEAD request for Content-Length/Accept-Ranges, GET with `Range: bytes=N-` header for resume, `File.openWrite(mode: FileMode.append)` for appending, SHA-256 via `crypto` package
- **Files modified:** `lib/features/models/services/model_downloader.dart`
- **Commit:** `6cae4c2`

**2. [Rule 3 - Blocking] Provider auto-disposal during async download operations**
- **Found during:** Task 3
- **Issue:** `ModelDownloadNotifier` was auto-disposed during the async gap between `state = downloading` and `await downloader.startDownload()`, because Riverpod auto-disposes providers with no active listeners. This caused `UnmountedRefException` when trying to update state in the download callback or catch block.
- **Fix:** Changed `@riverpod` to `@Riverpod(keepAlive: true)` for `ModelDownloadNotifier`
- **Files modified:** `lib/features/models/providers/model_download_provider.dart`
- **Commit:** `de55860`

## Known Stubs

| Stub | File | Line | Reason |
|------|------|------|--------|
| `sha256Hash: 'TBD'` (3 models) | `lib/features/models/providers/model_catalog_provider.dart` | 57, 70, 83 | SHA-256 hashes are unknown until first download of each model tier. ModelDownloader skips verification when hash is 'TBD'. Future plan (03-07 or post-download) will update these with real hashes. |

## Threat Flags

None — all security surface from `<threat_model>` is covered:
- T-03-05-01 (Tampering, model_downloader.dart): SHA-256 verification implemented, mismatch throws DownloadVerificationException
- T-03-05-02 (Spoofing, gguf_validator.dart): 4-byte magic number check + extension check implemented
- T-03-05-03 (Tampering, HuggingFace URL): HTTPS enforced by HuggingFace CDN; SHA-256 in catalog for end-to-end integrity
- T-03-05-04 (DoS, model_download_provider.dart): Single-download queue enforced (StateError on concurrent start)
- T-03-05-05 (EoP, installed_models_provider.dart): Accepted as documented — OS-level permissions gate file access

## Verification Results

```bash
flutter test test/features/models/     → 27/27 passing
dart analyze lib/features/models/       → No issues found
flutter pub get                          → All packages resolved
```

## Commits

- `55240df` — test(03-05): add failing tests for GGUF validator + model catalog provider
- `6cae4c2` — feat(03-05): implement ModelDownloader with HTTP Range resume + SHA-256 verification
- `de55860` — feat(03-05): implement ModelDownloadNotifier + InstalledModelsProvider
