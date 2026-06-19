# Tech Stack

## Languages

| Language | Version | Usage |
|----------|---------|-------|
| Dart | ^3.12.2 (Flutter 3.44.2 bundled) | 100% application code |
| C++ | C++14 | Linux plugin FFI (GTK 3.0 host) |
| Kotlin/Java | AGP 8.x | Android host (no custom platform code yet) |
| CMake | ≥3.13 | Windows + Linux build orchestration |

## Runtime & SDK

- **Flutter:** 3.44.2 stable (installed at `C:\Users\Lenovo\flutter`, git-cloned, not FVM)
- **Dart:** 3.12.2 (bundled with Flutter 3.44.2)
- **Android SDK:** `C:\Users\Lenovo\AppData\Local\Android\Sdk` (cmdline-tools CLI install; Platform 35, Build-Tools 35.0.0)
- **JDK:** D:\Java\jdk-21 (JAVA_HOME; used for Android builds)
- **VS Build Tools:** 2026 18.1.1 (pre-existing; `flutter doctor` green for Windows)

## Core Dependencies

| Package | Version | Purpose | Decision Ref |
|---------|---------|---------|-------------|
| `flutter` | SDK | UI framework | — |
| `flutter_riverpod` | ^3.3.2 | Reactive state management | D-03 |
| `riverpod_annotation` | ^4.0.3 | @riverpod codegen | D-03 |
| `drift` | ^2.34.0 | Type-safe SQLite ORM | STOR-01 |
| `sqlite3_flutter_libs` | ^0.5.38 | Pre-compiled SQLite .so (avoids network download) | STOR-01 |
| `go_router` | ^17.3.0 | Declarative routing (6 routes) | Plan 01-04 |
| `dynamic_color` | ^1.8.1 | Material You dynamic color (nullable; desktop fallback) | D-20 |
| `path` | ^1.9.1 | Cross-platform path manipulation | — |
| `path_provider` | ^2.1.6 | Platform directory resolution (used only in `PathResolver`) | — |
| `freezed_annotation` | ^3.1.0 | Immutable data classes + sealed unions | Phase 2+ |
| `json_annotation` | ^4.9.0 | JSON serialization annotations | Phase 5 |

## Code-Generation Stack

Single `build_runner: ^2.4.13` drives all codegen (D-06):

| Generator | Version | Output |
|-----------|---------|--------|
| `drift_dev` | ^2.34.0 | `*.g.dart` (database + DAO code) |
| `riverpod_generator` | ^4.0.4 | `*.g.dart` (providers) |
| `freezed` | ^3.2.5 | `*.freezed.dart` (data classes) |
| `json_serializable` | ^6.8.0 | `*.g.dart` (JSON) |

## Lint Configuration

- `flutter_lints: ^6.0.0` (Flutter 3.44.2 default; v5 incompatible with analyzer 7.x)
- `analysis_options.yaml`: `prefer_const_constructors`, `prefer_final_locals`, `avoid_print`, `require_trailing_commas`, `sort_child_properties_last`
- Custom lint (`riverpod_lint`) was removed in Plan 01-01: `custom_lint 0.8.x` pins analyzer ^7.5.0 but `drift_dev 2.34.0` needs ^10.0.0 — mutually exclusive
- Generated files excluded from analysis: `*.g.dart`, `*.freezed.dart`, `*.config.dart`

## Deferred Dependencies

Packages expected in later phases but not yet added:
- `archive` + `xml` → Phase 2 `.docx` parsing
- `pdfx` → Phase 2 PDF text extraction
- `file_picker` → Phase 2 file selection
- `shared_preferences` → Phase 5 settings
- `intl` → Phase 5 Chinese locale formatting

## Platform Targets

| Platform | Status | Artifact Type |
|----------|--------|--------------|
| Windows | ✅ Builds & passes tests | `.exe` (CMake + MSVC) |
| Linux | ✅ compiles (not tested on real Linux) | ELF (CMake + GCC) |
| Android | ⚠️ NDK deferred (disk space) | `.apk` (Gradle + AGP) |
| iOS | Source-level only | No build verified |
| macOS | Source-level only | No build verified |

> Platform decision: 3 distributable targets (Windows/Linux/Android), 5 source-level platforms (iOS/macOS compile-only).
