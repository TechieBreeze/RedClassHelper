---
status: partial
phase: 04-quiz-core-wrong-question-ledger
source: [04-VERIFICATION.md]
started: 2026-06-20T02:00:00.000Z
updated: 2026-06-20T02:00:00.000Z
---

## Current Test

[awaiting human testing]

## Tests

### 1. OptionCard visual feedback states
expected: All 5 post-submit states (correct, wrongSelected, correctUnselected, dimmed) render with correct colors per UI-SPEC D-04 — correct=green bg, wrong=red bg, unselected=dimmed opacity
result: [pending]

### 2. Desktop keyboard shortcuts
expected: A/B/C/D keys select options, Space submits in confirm mode, ArrowRight advances in manual advance mode. All 6 bindings work on Windows and Linux.
result: [pending]

### 3. Auto-advance timer
expected: After submitting answer in auto-advance mode, question advances after ~2 seconds. Timer is cancelled when user manually advances or leaves quiz.
result: [pending]

### 4. Wrong-question chip animation
expected: "已加入错题本" chip slides up + fades in over 200ms, auto-dismisses after 1.5s. Only appears on incorrect answers.
result: [pending]

### 5. Badge reactivity
expected: Home screen mode tile badges update in real-time after answering questions incorrectly (count increases) and after mastering in review mode (count decreases).
result: [pending]

### 6. dart analyze + flutter test
expected: `dart analyze lib/` exits 0 with no errors. `flutter test` passes all existing and new tests (66 from Phase 2 + 9 ledger + 15 controller = ~90 tests).
result: [pending]

### 7. Full quiz E2E flow
expected: Home → tap mode tile → bank picker shows banks → tap bank → quiz screen loads → answer all questions → summary screen shows stats → "再来一轮" returns to bank picker → "返回主页" returns home.
result: [pending]

## Summary

total: 7
passed: 0
issues: 0
pending: 7
skipped: 0
blocked: 0

## Gaps
