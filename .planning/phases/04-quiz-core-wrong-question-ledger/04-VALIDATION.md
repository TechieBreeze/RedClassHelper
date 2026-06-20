---
phase: 04
slug: quiz-core-wrong-question-ledger
status: draft
nyquist_compliant: false
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

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 04-01-01 | 01 | 1 | QST-01, UI-03 | T-04-01 | N/A | unit | `flutter test` | ❌ W0 | ⬜ pending |
| 04-02-01 | 02 | 1 | REV-01, QST-01 | T-04-02 | N/A | unit | `flutter test` | ❌ W0 | ⬜ pending |
| 04-03-01 | 03 | 2 | REV-02, REV-03, REV-04 | T-04-03 | Atomic ledger write within transaction | unit | `flutter test` | ❌ W0 | ⬜ pending |
| 04-04-01 | 04 | 2 | REV-05, REV-06 | T-04-03 | mastered_at IS NULL guard | unit | `flutter test` | ❌ W0 | ⬜ pending |
| 04-05-01 | 05 | 2 | STAT-01 | — | N/A | unit | `flutter test` | ❌ W0 | ⬜ pending |
| 04-06-01 | 06 | 3 | REV-01~06, UI-03 | — | N/A | unit | `flutter test` | ❌ W0 | ⬜ pending |
| 04-07-01 | 07 | 3 | REV-01~06 | — | N/A | unit | `flutter test` | ❌ W0 | ⬜ pending |
| 04-08-01 | 08 | 1 | QST-01 | — | N/A | unit | `flutter test` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/features/quiz/quiz_session_controller_test.dart` — stubs for QuizSessionController
- [ ] `test/data/repositories/ledger_repository_test.dart` — stubs for LedgerRepository
- [ ] `test/features/quiz/quiz_screen_test.dart` — stubs for QuizScreen widget tests
- [ ] `test/features/quiz/bank_picker_screen_test.dart` — stubs for BankPickerScreen
- [ ] `test/features/quiz/quiz_summary_screen_test.dart` — stubs for QuizSummaryScreen
- [ ] `test/data/repositories/answer_attempt_repository_test.dart` — stubs for AnswerAttemptRepository

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Keyboard shortcut behavior (A/B/C/D/Space/Right) | UI-03 | Flutter test cannot simulate raw keyboard events reliably on desktop | Launch app, navigate to quiz, verify all 6 key bindings |
| "已加入错题本" chip animation timing | UI-03 | Animation timing (~1.5s) is visual and subjective | Launch app, answer incorrectly, observe chip appearance/duration |
| Settings toggle persistence across app restart | QST-01 | shared_preferences reset between test runs | Toggle settings, kill app, relaunch, verify settings preserved |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
