---
phase: 1
slug: foundation-persistence
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-19
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution. Phase 1 = Foundation & Persistence (runnable Flutter skeleton + drift schema + PathResolver + go_router on 3 v1 platforms + iOS/macOS source support).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` (built into Flutter SDK) |
| **Config file** | none — Flutter SDK ships the test runner |
| **Quick run command** | `flutter analyze` (analyzer gate, ~10s) |
| **Full suite command** | `flutter test` (widget + unit tests, ~30s) |
| **Build smoke command** | `flutter build windows --debug` + `flutter build linux --debug` + `flutter build apk --debug` (~5-10 min cold, 1-2 min warm) |
| **Source-level iOS/macOS build** | `flutter build ios --no-codesign --simulator` + `flutter build macos --debug` (only on macOS host; deferred to CI or future host) |
| **Estimated full-suite runtime** | ~3-12 minutes (mostly build steps) |

> **Environment note (per RESEARCH.md A6):** The dev machine currently has NO Flutter SDK installed. Plan 01-00 (Install Flutter + Android SDK + Visual Studio 2022 C++ workload) must complete before any build verification can run. Until then, the only runnable command is `flutter analyze` after Flutter install.

---

## Sampling Rate

- **After every task commit:** Run `flutter analyze` (must exit 0; 0 new warnings introduced)
- **After every plan wave:** Run `flutter test` (full widget + unit suite) + at least one `flutter build <platform> --debug`
- **Before `/gsd-verify-work`:** Full suite + at least one Windows + one Linux + one Android debug build all green
- **Max feedback latency:** ~30 seconds (`flutter analyze`) / ~5 minutes (`flutter test` + single platform build) / ~15 minutes (3-platform build matrix)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 01-00-01 | 00 | 0 | none (env) | — | Flutter SDK + Android SDK + VS2022 C++ installed; `flutter doctor` returns green for Windows/Linux/Android sections | manual smoke | `flutter doctor` | ❌ W0 | ⬜ pending |
| 01-01-01 | 01 | 1 | PLT-04 | — | Project compiles for all 5 platforms; 3 v1 platforms + 2 source-only | build | `flutter build windows --debug && flutter build linux --debug && flutter build apk --debug` | ❌ W0 | ⬜ pending |
| 01-01-02 | 01 | 1 | PLT-04 | — | pubspec.lock committed; `flutter pub get` reproducible | build | `flutter pub get --offline` exits 0 | ❌ W0 | ⬜ pending |
| 01-02-01 | 02 | 2 | STOR-01 / STOR-02 / IMP-05 | — | drift schema opens on 3 v1 platforms; 6 tables created; onUpgrade is no-op for v1 | unit | `flutter test test/data/db/migration_test.dart` | ❌ W0 | ⬜ pending |
| 01-02-02 | 02 | 2 | STOR-01 | — | DB file persists at `getApplicationSupportDirectory()/redclass.db` after app restart (manual smoke on each platform) | manual | open app, close, reopen, verify DB exists | ❌ W0 | ⬜ pending |
| 01-02-03 | 02 | 2 | STOR-01 | — | Drift schema codegen output (database.g.dart) is committed; no regeneration drift | build | `dart run build_runner build --delete-conflicting-outputs` exits 0 | ❌ W0 | ⬜ pending |
| 01-03-01 | 03 | 2 | PLT-05 / PITFALL 3 | — | PathResolver is the ONLY caller of `path_provider`; no other file imports path_provider | static grep | `grep -r "path_provider" lib/ --include="*.dart" \| grep -v "PathResolver"` returns 0 lines | ❌ W0 | ⬜ pending |
| 01-03-02 | 03 | 2 | PLT-05 | — | PathResolver test: all 5 getters return expected paths; Riverpod override works in widget tests | unit | `flutter test test/core/paths/path_resolver_test.dart` | ❌ W0 | ⬜ pending |
| 01-04-01 | 04 | 2 | PLT-04 | — | go_router config covers all 6 routes; each route is a placeholder screen with AppBar + Center(Text) | unit | `flutter test test/routing/router_test.dart` (asserts 6 routes resolve) | ❌ W0 | ⬜ pending |
| 01-04-02 | 04 | 2 | PLT-04 | — | Navigation between all 6 routes succeeds (no Navigator.push used; go_router is sole nav API) | static grep | `grep -r "Navigator.push" lib/ --include="*.dart"` returns 0 lines | ❌ W0 | ⬜ pending |
| 01-05-01 | 05 | 3 | UI-02 | — | Home screen renders all 3 mode tiles + stats entry + bank empty state per UI-SPEC | widget | `flutter test test/features/home/home_screen_test.dart` (golden test optional) | ❌ W0 | ⬜ pending |
| 01-05-02 | 05 | 3 | UI-01 | — | Material 3 theme renders correctly in light AND dark mode; seed color 0xFF6750A4 fallback works | widget | `flutter test test/core/theme/theme_test.dart` (renders home in both modes) | ❌ W0 | ⬜ pending |
| 01-05-03 | 05 | 3 | UI-01 | — | dynamic_color graceful fallback (returns null on most desktop platforms) | widget | `flutter test test/core/theme/dynamic_color_fallback_test.dart` | ❌ W0 | ⬜ pending |
| 01-05-04 | 05 | 3 | UI-02 | — | All UI strings match UI-SPEC copywriting table (no fabricated copy) | static grep | `grep -r "乱序抽题\|错题复习\|错题抽查\|数据统计\|还没有题库" lib/features/home/` finds all | ❌ W0 | ⬜ pending |
| 01-06-01 | 06 | 4 | PLT-04 / PLT-05 / STOR-01 | — | App launches on Windows; home screen renders; DB initializes; can navigate all 6 routes | manual smoke | run on Windows host | ❌ W0 | ⬜ pending |
| 01-06-02 | 06 | 4 | PLT-04 / PLT-05 | — | App launches on Linux; same checks as 01-06-01 | manual smoke | run on Linux host | ❌ W0 | ⬜ pending |
| 01-06-03 | 06 | 4 | PLT-04 / PLT-05 | — | App launches on Android (emulator or device); same checks | manual smoke | run on Android | ❌ W0 | ⬜ pending |
| 01-06-04 | 06 | 4 | PLT-04 | — | `flutter build ios --no-codesign --simulator` succeeds on macOS host (deferred — not runnable on Windows dev machine) | manual smoke | requires macOS host or CI | ❌ W0 | ⬜ pending |
| 01-06-05 | 06 | 4 | PLT-04 | — | `flutter build macos --debug` succeeds on macOS host (deferred) | manual smoke | requires macOS host or CI | ❌ W0 | ⬜ pending |
| 01-06-06 | 06 | 4 | PLT-05 | — | DB file persists across app restart on all 3 v1 platforms (close app, reopen, verify DB exists and has expected schema) | manual smoke | platform-specific | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Phase 1 has no existing test infrastructure (greenfield). Wave 0 (Plan 01-00) must create:

- [ ] **Plan 01-00 (Environment bootstrap)** — Install Flutter 3.35.7 + Android SDK + Visual Studio 2022 C++ workload + Linux toolchain; `flutter doctor` green for Windows/Linux/Android
- [ ] `test/core/paths/path_resolver_test.dart` — stubs for PathResolver 5 getters
- [ ] `test/data/db/migration_test.dart` — stubs for drift schema version 1 + onCreate + onUpgrade
- [ ] `test/routing/router_test.dart` — stubs for 6 go_router routes
- [ ] `test/core/theme/theme_test.dart` + `test/core/theme/dynamic_color_fallback_test.dart` — stubs for theme + fallback
- [ ] `test/features/home/home_screen_test.dart` — stubs for home screen widgets
- [ ] `.github/workflows/phase1-smoke.yml` — (optional, Phase 1 is personal use) CI smoke for `flutter analyze` + `flutter test`

> **Why no conftest.dart or shared fixtures:** Flutter uses per-test setup via `setUp()` callbacks. No cross-file fixture sharing needed for Phase 1's narrow test surface.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `flutter run -d windows` launches home screen | PLT-04 / STOR-01 / UI-02 | GUI launch + visual confirmation | `flutter run -d windows`; verify 3 mode tiles + bank empty state appear; Ctrl+Q to close |
| `flutter run -d linux` launches home screen | PLT-04 / STOR-01 / UI-02 | GUI launch + visual confirmation | same as Windows but on Linux host |
| `flutter run -d <android>` launches home screen | PLT-04 / STOR-01 / UI-02 | GUI launch + touch test on emulator/device | `flutter run -d <device-id>`; verify tiles are tappable; back button works |
| DB file persists across app restart | PLT-05 / STOR-01 | File-system state + cross-launch persistence | Open app, create a row in DB (via debug menu OR add a temp test), close app, reopen, verify row still exists |
| `getApplicationSupportDirectory()` returns expected path on Windows | PLT-05 / PITFALL 3 | Platform-specific path | Add a debug print on first launch; verify path is NOT in OneDrive sync folder |
| `getApplicationSupportDirectory()` returns expected path on Android | PLT-05 / PITFALL 3 | Platform-specific path | Same as above on Android device/emulator |
| Material 3 theme renders correctly in both modes | UI-01 | Visual confirmation in dark mode | Switch system theme to dark; verify app respects `ThemeMode.system` |
| iOS / macOS source builds (deferred) | PLT-04 | Requires macOS host | `flutter build ios --no-codesign --simulator` on macOS; same for macos debug |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies (or are manual smoke with instructions)
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify (Plan 01-04 has 2 automated + Plan 01-05 has 4 automated; both meet the bar)
- [ ] Wave 0 covers all MISSING references (Plan 01-00 + 5 test stubs)
- [ ] No watch-mode flags used in CI commands
- [ ] Feedback latency: `flutter analyze` ~10s; `flutter test` ~30s; single-platform build ~2-5 min; full 3-platform matrix ~15 min (acceptable)
- [ ] `nyquist_compliant: true` set in frontmatter (set after Plan 01-00 + Wave 0 test stubs are created)

**Approval:** pending — awaits execution of Plan 01-00 + Wave 0
