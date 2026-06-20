---
phase: 04
slug: quiz-core-wrong-question-ledger
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-20
---

# Phase 04 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` (package:flutter_test) + `mocktail` for mocks |
| **Config file** | none — flutter_test uses convention |
| **Quick run command** | `flutter test` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter test`
- **After every plan wave:** Run `flutter test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task | Plan | Wave | Requirements | Threat Ref | Secure Behavior | Test Type | Automated Command | Status |
|------|------|------|-------------|------------|-----------------|-----------|-------------------|--------|
| Models + shared_preferences | 04-01 | 1 | — | T-04-01 | N/A | unit | `flutter test` | ⬜ pending |
| LedgerRepository + atomic txns | 04-01 | 1 | REV-02, REV-03, REV-04, REV-06, STAT-01 | T-04-01 | Atomic ledger write within drift transaction() | unit | `flutter test` | ⬜ pending |
| Providers + SharedPreferences init | 04-01 | 1 | REV-01, REV-05 | — | N/A | unit | `flutter test` | ⬜ pending |
| QuizSessionController | 04-02 | 2 | QST-01, REV-01~06, STAT-01 | T-04-02 | N/A | unit | `flutter test` | ⬜ pending |
| Controller unit tests | 04-02 | 2 | QST-01, REV-01~06 | — | N/A | unit | `flutter test` | ⬜ pending |
| Quiz widgets (OptionCard et al.) | 04-03 | 3 | QST-01, UI-03 | — | N/A | unit | `flutter test` | ⬜ pending |
| QuizScreen implementation | 04-03 | 3 | QST-01, UI-03 | — | N/A | unit | `flutter test` | ⬜ pending |
| build_runner codegen | 04-03 | 3 | — | — | N/A | integration | `dart analyze` | ⬜ pending |
| BankPickerScreen | 04-04 | 3 | REV-01, REV-03, REV-05 | — | N/A | unit | `flutter test` | ⬜ pending |
| QuizSummaryScreen | 04-04 | 3 | REV-01~06 | — | N/A | unit | `flutter test` | ⬜ pending |
| GoRouter + redirect guards | 04-04 | 3 | REV-01, REV-03, REV-05 | T-04-04 | Redirect guard prevents access without session | unit | `flutter test` | ⬜ pending |
| HomeScreen wrong-count badges | 04-05 | 4 | REV-01, REV-03, REV-05 | — | N/A | unit | `flutter test` | ⬜ pending |
| SettingsScreen quiz toggles | 04-05 | 4 | QST-01, UI-03 | — | N/A | unit | `flutter test` | ⬜ pending |
| Full dart analyze | 04-05 | 4 | — | — | N/A | integration | `dart analyze` | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/data/repositories/ledger_repository_test.dart` — stubs for LedgerRepository (04-01)
- [ ] `test/features/quiz/quiz_session_controller_test.dart` — stubs for QuizSessionController (04-02)
- [ ] `test/features/quiz/quiz_screen_test.dart` — stubs for QuizScreen widget tests (04-03)
- [ ] `test/features/quiz/bank_pick_screen_test.dart` — stubs for BankPickerScreen (04-04)
- [ ] `test/features/quiz/quiz_summary_screen_test.dart` — stubs for QuizSummaryScreen (04-04)
- [ ] `test/features/home/home_screen_test.dart` — update for badge assertions (04-05)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Keyboard shortcut behavior (A/B/C/D/Space/Right) | UI-03 | Flutter test cannot simulate raw keyboard events reliably on desktop | Launch app, navigate to quiz, verify all 6 key bindings |
| "已加入错题本" chip animation timing | UI-03 | Animation timing (~1.5s) is visual and subjective | Launch app, answer incorrectly, observe chip appearance/duration |
| Settings toggle persistence across app restart | QST-01 | shared_preferences reset between test runs | Toggle settings, kill app, relaunch, verify settings preserved |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
