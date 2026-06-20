---
status: partial
phase: 05-json-export-import-multiple-choice-bookmarks-statistics
source: [05-VERIFICATION.md]
started: 2026-06-20
updated: 2026-06-20
---

## Current Test

[awaiting human testing]

## Tests

### 1. JSON Export Flow
expected: "导出 JSON" button → OS native save dialog with `{bankName}.json` default name → file written to chosen path → SnackBar "已导出到 {filename}"
result: [pending]

### 2. JSON Import Flow
expected: Pick .json file → import pipeline shows progress → navigates to import summary showing committed count → duplicate bank triggers silent atomic replacement
result: [pending]

### 3. StatsScreen Visual
expected: Expandable cards with AnimatedRotation chevron, per-mode breakdown rows (乱序抽题, 错题复习, 错题抽查) showing attempt count + correct rate
result: [pending]

### 4. HomeScreen Bank Cards
expected: Bank cards with titleMedium name, bodyMedium count/source, library icon, chevron. Tap opens /bank/:id with correct info.
result: [pending]

### 5. Full Test Suite
expected: `flutter test` — all 82 tests pass (13 export + 14 import + 23 quiz + 14 stats + 8 bank detail + 10 home screen)
result: [pending]

## Summary

total: 5
passed: 0
issues: 0
pending: 5
skipped: 0
blocked: 0

## Gaps
