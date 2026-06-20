---
plan: 05-02
wave: 2
status: complete
---

# 05-02 Summary: BankDetailScreen

## What was done

Replaced the TODO placeholder with a full `ConsumerWidget` BankDetailScreen showing bank info card, JSON export button, and review entry point.

## Commits

| Commit | Message |
|--------|---------|
| `253ed0c` | feat(05-02): implement BankDetailScreen with bank info card, JSON export, and review entry |
| `7357187` | test(05-02): add BankDetailScreen widget tests (8 cases) |

## Key files

| File | Status |
|------|--------|
| `lib/features/bank_detail/presentation/bank_detail_screen.dart` | Modified (+225) |
| `test/features/bank_detail/bank_detail_screen_test.dart` | Created (+263) |

## Features

- **Bank info card:** bank name (headlineSmall), source filename via `p.basename()`, question count
- **"导出 JSON" FilledButton.icon:** triggers `FilePicker.saveFile()` system native save dialog, then writes JSON via `bankToUserJson()` + `dart:io File.writeAsString()` — two-step desktop export pattern
- **"开始复习" FilledButton.tonalIcon:** navigates to `/quiz/pick/random` via `context.push()`
- **Responsive layout:** LayoutBuilder 3-breakpoint logic matching HomeScreen
- **Filename sanitization:** `bank.name.replaceAll(RegExp(r'[/\\:]'), '_')` for path traversal prevention

## Deviations

- `FilePicker.platform.saveFile()` → `FilePicker.saveFile()` — file_picker v11.x API change
- Test assertion `findsOneWidget` → `findsAtLeast(1)` — bank name appears in both AppBar title and info card

## Verification

- `flutter test test/features/bank_detail/bank_detail_screen_test.dart` — 8/8 pass
- `dart analyze lib/features/bank_detail/` — clean
