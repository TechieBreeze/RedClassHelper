---
phase: 2
slug: desktop-file-import-pipeline
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-19
---

# Phase 2 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution. Phase 2 = Desktop File Import Pipeline (.docx/.doc/.pdf text extraction + heuristic regex parser + preview/edit UI + DB commit).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` (built into Flutter SDK) — same as Phase 1 |
| **Config file** | none — Flutter SDK ships the test runner |
| **Quick run command** | `flutter analyze lib/features/import/ lib/data/providers/import*` |
| **Full suite command** | `flutter test test/features/import/ test/data/providers/import*` |
| **Windows build check** | `flutter build windows --debug` |
| **Linux build check** | `flutter build linux --debug` |
| **Estimated full-suite runtime** | ~2-5 minutes (unit/widget tests + analyzer) + ~5-10 minutes (build) |

> **Environment note:** Phase 1 toolchain is fully installed and verified. `flutter --version` = 3.44.2, `flutter doctor` green for Windows/Linux/Android. No new toolchain steps needed. `pdfx` requires one-time `flutter pub run pdfx:install_windows` (task 01). Pandoc is optional — .doc tests are skipped if absent.

---

## Sampling Rate

- **After every task commit:** Run `flutter analyze` (must exit 0; 0 new warnings)
- **After each plan wave:** Run full parser unit tests + affected widget tests + at least one Windows debug build
- **Before `/gsd-verify-work`:** Full test suite green + Windows + Linux debug build + sample file integration test
- **Max feedback latency:** ~15 seconds (analyzer) / ~90 seconds (unit+widget tests) / ~5 minutes (full suite + build)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 02-00-01 | 00 | 1 | IMP-01 / IMP-02 | — | `flutter pub get` succeeds; pdfx install script completes on Windows | build | `flutter pub get --offline` exits 0 | ❌ W0 | ⬜ pending |
| 02-00-02 | 00 | 1 | IMP-01 / IMP-02 | — | PathResolver pandoc getter resolves or throws `PandocNotFoundException`; tempImportDir creates directory | unit | `flutter test test/core/path_resolver_ext_test.dart` | ❌ W0 | ⬜ pending |
| 02-00-03 | 00 | 2 | IMP-01 / IMP-02 | T-02-01 | .docx text extractor returns plain text from real sample files; corrupt .docx throws `FormatException` | unit | `flutter test test/features/import/extraction/docx_extractor_test.dart` | ❌ W0 | ⬜ pending |
| 02-00-03b | 00 | 2 | IMP-01 (scope creep) | T-02-02 | .doc extractor: pandoc → .docx → extract; missing pandoc → `PandocNotFoundException` | unit | `flutter test test/features/import/extraction/doc_extractor_test.dart` | ❌ W0 | ⬜ pending |
| 02-00-03c | 00 | 2 | IMP-02 | T-02-03 | .pdf text extractor returns text; scanned PDF → `ScannedPdfException`; encrypted PDF → `EncryptedPdfException` | unit | `flutter test test/features/import/extraction/pdf_extractor_test.dart` | ❌ W0 | ⬜ pending |
| 02-00-04 | 00 | 3 | IMP-01 / IMP-02 / QST-03 | T-02-04 | Heuristic parser: 9-step pipeline produces correct ParsedQuestion list; inline answers detected; multi-choice auto-detected; warnings for malformed questions | unit | `flutter test test/features/import/parse/heuristic_parser_test.dart` | ❌ W0 | ⬜ pending |
| 02-00-04b | 00 | 3 | IMP-01 / IMP-02 | T-02-05 | Isolate entry function: accepts rawText → returns JSON list; progress messages via SendPort; error on crash | unit | `flutter test test/features/import/parse/parse_isolate_test.dart` | ❌ W0 | ⬜ pending |
| 02-00-05 | 00 | 4 | IMP-04 | — | Riverpod providers: parseJob lifecycle (pending→extracting→parsing→done/cancelled/error); parsedQuestions mutable list with edit ops; commit creates Bank + Questions in DB | unit | `flutter test test/data/providers/import_providers_test.dart` | ❌ W0 | ⬜ pending |
| 02-00-06 | 00 | 5 | UI-04 | — | ImportScreen: desktop shows 4 format tiles; Android shows only .json (disabled); tap → file_picker called with correct extensions; unsupported drag → SnackBar | widget | `flutter test test/features/import/screens/import_screen_test.dart` | ❌ W0 | ⬜ pending |
| 02-00-07 | 00 | 5 | IMP-04 | — | ImportProgressScreen: progress bar 0→1; cancel dialog on back press; error state with retry | widget | `flutter test test/features/import/screens/import_progress_screen_test.dart` | ❌ W0 | ⬜ pending |
| 02-00-08 | 00 | 6 | UI-04 / QST-03 | — | ImportPreviewScreen: edit stem/options/answers; type toggle single↔multi; delete with confirmation; bulk "仅保留有效"; submit disabled when 0 valid or empty bank name | widget | `flutter test test/features/import/screens/import_preview_screen_test.dart` | ❌ W0 | ⬜ pending |
| 02-00-09 | 00 | 6 | IMP-04 | — | ImportSummaryScreen: correct success/skip counts; retry + manual-edit buttons; "开始复习" navigates to quiz; summary hidden if no skips | widget | `flutter test test/features/import/screens/import_summary_screen_test.dart` | ❌ W0 | ⬜ pending |
| 02-00-10 | 00 | 5 | UI-04 | — | HomeScreen FAB: visible, tappable; routes to /import; empty-state CTA now enabled | widget | `flutter test test/features/home/screens/home_screen_test.dart` | ❌ W0 | ⬜ pending |
| 02-00-11 | 00 | 7 | UI-04 | — | go_router: 3 new routes resolve correctly; deep-link to stale jobId redirects to / | unit | `flutter test test/app_router_test.dart` | ❌ W0 | ⬜ pending |
| 02-00-12 | 00 | 8 | IMP-01 / IMP-02 / IMP-04 | — | Full pipeline integration: sample .docx → extract → parse → edit 1 question → commit → verify DB | integration | `flutter test test/features/import/integration_test.dart` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/features/import/` — test directory structure (extraction/, parse/, screens/)
- [ ] `test/data/providers/import_providers_test.dart` — provider test stubs
- [ ] `test/features/import/integration_test.dart` — integration test with real sample files
- [ ] `flutter analyze` exits 0 on existing Phase 1 code (baseline before Phase 2 changes)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| File picker opens native dialog | IMP-01 / IMP-02 | Cannot automate OS file dialog via `flutter_test`; `file_picker` is a platform channel | Launch app → tap FAB → tap .docx tile → verify system file dialog opens with `.docx,.doc` filter |
| Drag-and-drop from Windows Explorer | IMP-01 | `desktop_drop` platform channel cannot be fully simulated in widget tests | Launch app → drag a `.docx` from Explorer onto the window → verify overlay appears → release → verify parse starts |
| Pandoc installation detection | IMP-01 | Pandoc presence depends on dev machine state | Run app with pandoc installed → .doc tile works. Uninstall pandoc → .doc tile shows download link error |
| Actual file parse accuracy on sample files | IMP-01 / IMP-02 | Real sample files in `doc/example/` have complex formatting; manual verification of parse quality | Import each sample file → preview → verify questions are correctly split, answers detected, type correct |
| PDF text extraction quality | IMP-02 | pdfx extraction quality varies by PDF generator; manual check | Import sample .pdf → preview → verify text is clean, no garbled characters |
| Android: .docx/.pdf entries hidden | UI-04 | Cross-platform UI behavior requires Android device/emulator | Launch on Android → FAB → Import screen → verify only .json entry visible (disabled) |

---

## Validation Sign-Off

- [ ] All 14 tasks have automated verify or documented manual verification
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5 minutes (full suite)
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
