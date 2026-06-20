---
plan: 05-06
wave: 1
status: complete
---

# 05-06 Summary: Home Screen Bank List

## What was done

Replaced the `_BankEmptyStateCard` placeholder on the home screen with a real `Consumer` widget that watches `bankPickListProvider` and renders `_BankCard` widgets with tap-to-navigate.

Added full test coverage: 5 new widget tests for bank list rendering and navigation, plus provider override fixes for 5 existing tests.

## Commits

| Commit | Message |
|--------|---------|
| `98018dd` | feat(05-06): replace home screen placeholder with real bank list from bankPickListProvider |
| `fff3006` | test(05-06): add bank list rendering and navigation tests for home screen |

## Key files

| File | Status |
|------|--------|
| `lib/features/home/presentation/home_screen.dart` | Modified (+175) |
| `test/features/home/home_screen_test.dart` | Modified (+147) |

## Widgets added

- `_BankCard` — bank name/subtitle/count chip with ripple tap → `BankDetailScreen`
- `_BankListLoading` — shimmer placeholder
- `_BankListError` — error message with retry button

## Provider changes

- `_BankEmptyStateCard` removed
- `bankPickListProvider` Consumer replaces the TODO placeholder
- `_emptyBankListOverrides()` helper for test isolation

## Deviations

- [Bug fix] Added `bankPickListProvider` overrides to 5 existing test cases that would fail without database overrides after the Consumer wiring.

## Verification

- `flutter test test/features/home/home_screen_test.dart` — all tests pass
