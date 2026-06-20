---
phase: 05
slug: json-export-import-multiple-choice-bookmarks-statistics
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-20
---

# Phase 05 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` (built-in) + `ProviderScope` overrides |
| **Config file** | none — implicit via `flutter test` |
| **Quick run command** | `flutter test` |
| **Full suite command** | `flutter test --coverage` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter test`
- **After every plan wave:** Run `flutter test --coverage`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 05-01-01 | 01 | 1 | IMP-06 | T-05-01 | N/A | unit | `flutter test test/features/export/json_export_service_test.dart` | ❌ W0 | ⬜ pending |
| 05-01-02 | 01 | 1 | IMP-06 | — | N/A | widget | `flutter test test/features/bank_detail/bank_detail_screen_test.dart` | ❌ W0 | ⬜ pending |
| 05-02-01 | 02 | 1 | IMP-07 | T-05-02 | Validate JSON structure + key format before DB commit | unit | `flutter test test/features/import/json_import_test.dart` | ❌ W0 | ⬜ pending |
| 05-03-01 | 03 | 2 | QST-02 | — | N/A | unit | `flutter test test/features/quiz/providers/quiz_session_controller_test.dart` | ✅ exists | ⬜ pending |
| 05-04-01 | 04 | 2 | STAT-02 | — | N/A | unit | `flutter test test/features/stats/stats_provider_test.dart` | ❌ W0 | ⬜ pending |
| 05-04-02 | 04 | 2 | STAT-02 | — | N/A | widget | `flutter test test/features/stats/stats_screen_test.dart` | ❌ W0 | ⬜ pending |
| 05-05-01 | 05 | 3 | D-12, D-13 | — | N/A | widget | `flutter test test/features/home/home_screen_test.dart` | ✅ exists | ⬜ pending |
| 05-06-01 | 06 | 3 | D-14 | — | N/A | widget | `flutter test test/features/bank_detail/bank_detail_screen_test.dart` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/features/export/json_export_service_test.dart` — format conversion + round-trip (IMP-06)
- [ ] `test/features/import/json_import_test.dart` — JSON parse, duplicate replace, validation (IMP-07)
- [ ] `test/features/stats/stats_provider_test.dart` — aggregation queries + per-mode breakdown (STAT-02)
- [ ] `test/features/stats/stats_screen_test.dart` — empty/loading/error/data states (STAT-02)
- [ ] `test/features/bank_detail/bank_detail_screen_test.dart` — export button, review entry, layout
- [ ] Modify `test/features/home/home_screen_test.dart` — bank list rendering + card tap navigation (D-12, D-13)
- [ ] Modify `test/features/quiz/providers/quiz_session_controller_test.dart` — extend multi-choice grading test cases if incomplete

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| System native save dialog opens on Windows | IMP-06 | Cannot automate OS-native dialog in flutter_test | Click "导出 JSON", verify save dialog appears with correct filename |
| System native save dialog opens on Linux | IMP-06 | Cannot automate OS-native dialog in flutter_test | Same as above, verify on Linux |
| file_picker saveFile(bytes:) workaround works on desktop | IMP-06 | Desktop-specific file I/O behavior | Export a bank, verify file exists at chosen path with correct content |
| Linux dialog tools (zenity/kdialog/qarma) detection | IMP-06 | Environment-specific | Run on minimal Linux without dialog tools, verify error message |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
