---
phase: 01-foundation-persistence
plan: 01
subsystem: scaffold
tags: [flutter, riverpod, deps, scaffold, pubspec, directory-layout]

requires:
  - phase: 01-foundation-persistence
    plan: 00
    provides: "Flutter SDK 3.44.2 + Android SDK + VS Build Tools"
provides:
  - "Flutter project with 5 platform source folders"
  - "pubspec.yaml with Phase 1 dependencies (drift, riverpod, go_router, dynamic_color, freezed)"
  - "lib/{core,data,domain,features}/ directory scaffolding with .gitkeep"
  - "Minimal ProviderScope → RedClassApp MaterialApp scaffold"
  - "Widget test passing: RedClassApp renders scaffold"
affects:
  - "All subsequent Phase 1 plans (01-02 through 01-06) — they extend the project created here"

tech-stack:
  added:
    - "flutter_riverpod 3.3.2"
    - "riverpod_annotation 4.0.3"
    - "drift 2.34.0"
    - "go_router 17.3.0"
    - "dynamic_color 1.8.1"
    - "freezed_annotation 3.1.0"
    - "json_annotation 4.9.0"
    - "path_provider 2.1.6"
    - "build_runner 2.4.13 (dev)"
    - "riverpod_generator 4.0.4 (dev)"
    - "drift_dev 2.34.0 (dev)"
    - "freezed 3.2.5 (dev)"
    - "json_serializable 6.8.0 (dev)"
  deferred:
    - "custom_lint + riverpod_lint (blocked by analyzer version conflict: custom_lint 0.8.x pins analyzer ^7.5.0 but drift_dev 2.34 needs ^10.0.0)"
    - "intl (Phase 5)"
    - "file_picker (Phase 2)"

key-files:
  created:
    - "lib/main.dart"
    - "lib/core/.gitkeep"
    - "lib/data/.gitkeep"
    - "lib/domain/.gitkeep"
    - "lib/features/.gitkeep"
    - "pubspec.yaml"
    - "android/"
    - "ios/"
    - "linux/"
    - "macos/"
    - "windows/"
    - "test/widget_test.dart"
  modified:
    - "lib/main.dart (replaced default counter app)"
    - "test/widget_test.dart (replaced counter test)"

key-decisions:
  - "Package name: com.redclass (flutter create --org com.redclass)"
  - "5 platform source folders created despite v1 shipping only 3 (iOS/macOS source-compile, no distributable)"
  - "custom_lint + riverpod_lint skipped — incompatible analyzer pins with drift_dev 2.34.0"
  - "sqlite3_flutter_libs not added (deprecated per RESEARCH.md — drift 2.32+ bundles native SQLite)"
  - "flex_color_scheme not added (D-22 explicitly rejected)"

patterns-established:
  - "ProviderScope → ConsumerWidget entry point (ready for go_router MaterialApp.router in Plan 01-04)"
  - "deferred-deps comment pattern in pubspec.yaml (notes reasons for skipping deps)"
  - ".gitkeep pattern for empty feature scaffolding dirs"

requirements-completed:
  - "PLT-04 (core app structure)"
  - "PLT-05 (directory layout from D-02)"
  - "PLT-06 (library conventions)"
  - "STOR-01 (drift dependency)"
  - "IMP-05 (pubspec.yaml with all Phase 1 deps)"

acceptance-criteria:
  - "pubspec.yaml contains flutter_riverpod: 3.3.2 — ✓"
  - "pubspec.yaml contains drift: ^2.34.0 — ✓"
  - "flutter analyze exits 0 — ✓"
  - "4 directories lib/{core,data,domain,features}/ with .gitkeep — ✓"
  - "5 platform folders exist — ✓"
  - "flutter pub get exits 0 — ✓"
  - "lib/main.dart imports flutter_riverpod and calls runApp(ProviderScope(...)) — ✓"

metrics:
  duration: 22min
  completed: 2026-06-19
---

# Phase 1 Plan 01: Project Scaffold Summary

**Flutter 5-platform project created, Phase 1 dependencies installed, lib/{core,data,domain,features}/ scaffolding ready with ProviderScope entry point. `flutter analyze` is green.**

## Accomplishments

- `flutter create --platforms=windows,linux,android,ios,macos --org com.redclass` → 5 platform source folders
- pubspec.yaml: 16 dependencies (8 runtime + 8 dev) pinned to STACK.md versions
- lib/main.dart: ProviderScope → RedClassApp → MaterialApp scaffold (ready for go_router + theme)
- .gitkeep files in all 4 lib/ subdirectories (empty dirs tracked by git)
- Widget test fix: `MyApp` → `RedClassApp` (flutter analyze green)
- Acceptance criteria: all 7 items green (pubspec versions, directory layout, flutter analyze, etc.)

## Commits

| Commit | Type | Description |
|--------|------|-------------|
| aeb5ee0 | feat | `flutter create` — 5 platform folders + default template |
| ca9fd8c | feat | Phase 1 dependency set per STACK.md locked versions |
| 8ba6e93 | feat | .gitkeep scaffold + minimal ProviderScope main.dart |
| bc45a4c | test | Fix widget_test to reference RedClassApp |

## Technical Notes

- **custom_lint skipped:** The custom_lint 0.8.x release pins analyzer ^7.5.0/^8.0.0, but drift_dev 2.34.0 requires analyzer ^10.0.0-^13.0.0. riverpod_generator 4.0.4 works standalone; re-add riverpod_lint in a later phase if the version gap closes.
- **ProviderScope in main.dart:** The `ConsumerWidget`-based `RedClassApp` is the shim that Plan 01-04 (go_router) and Plan 01-05 (theme) will extend — `MaterialApp` will become `MaterialApp.router`, and a `DynamicColorBuilder` wrapper will be added.
- **Dependencies versioned per RESEARCH.md:** All versions match the STACK.md recommendations from the research phase; `flutter pub outdated` shows 13 newer versions but these were intentionally pinned down for Phase 1 stability.
