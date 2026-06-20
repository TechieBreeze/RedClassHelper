# Phase 5: JSON Export/Import + Multiple-Choice + Statistics - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-20
**Phase:** 05-json-export-import-multiple-choice-bookmarks-statistics
**Areas discussed:** JSON format, JSON export/import UX, multiple-choice grading, bookmarks, statistics, home screen bank list

---

## JSON Format Design

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal: name + version | Bank name + schema version only, cleanest | ✓ |
| Moderate: name + source + version | Adds source filename context | |
| Full: all metadata | timestamps + UUID + everything | |

**User's choice:** Minimal: name + version
**Notes:** JSON format follows user-provided real question bank example: numbered objects, `answer` as option map, `key` as concatenated string, `answer_type` 0/1.

---

## JSON Export UX

| Option | Description | Selected |
|--------|-------------|----------|
| Context menu on bank card | Right-click → export | |
| Export button in bank detail page | Navigate in → button | ✓ |
| Both | Context menu + detail page button | |

**User's choice:** Export button in bank detail page
**Notes:** File save dialog for destination selection.

---

## JSON Import UX

| Option | Description | Selected |
|--------|-------------|----------|
| Integrated: reuse existing flow | Tap .json → file picker → direct commit | ✓ |
| Integrated with preview | Full pipeline including preview/edit | |
| Standalone | Separate import page | |

**User's choice:** Integrated into existing import flow, direct commit (no preview)

---

## Duplicate Bank Handling

| Option | Description | Selected |
|--------|-------------|----------|
| Replace existing bank | Overwrite by name match | ✓ |
| Create with suffix | New bank gets "(2)" suffix | |
| Ask the user | Dialog to choose | |

**User's choice:** Replace existing bank

---

## Multiple-Choice Grading

| Option | Description | Selected |
|--------|-------------|----------|
| Exact match only | All correct + no extras required | ✓ |

**User's choice:** Exact match only
**Notes:** Example: Correct=ABC. User selects ABC→correct, AB→wrong (missing C), ABCD→wrong (extra D).

---

## Bookmarks

| Option | Description | Selected |
|--------|-------------|----------|
| Removed from Phase 5 | User explicitly said "不需要收藏" | ✓ |

**User's choice:** Bookmarks removed from Phase 5 scope entirely.

---

## Statistics

| Option | Description | Selected |
|--------|-------------|----------|
| Per-bank + per-mode breakdown | Each bank: total questions, attempts, correct rate, ledger count + per-mode breakdown | ✓ |
| Global dashboard + per-bank detail | Top-level global stats then drill down | |
| Numbers only, simple tables | Plain tables | |

**User's choice:** Per-bank + per-mode breakdown, text + numbers only (no charts). Includes ledger active count per bank.

---

## Home Screen Bank List

| Option | Description | Selected |
|--------|-------------|----------|
| Fix in Phase 5 | Replace placeholder with real bank list | ✓ |
| Fix immediately | Quick fix now, outside Phase 5 | |

**User's choice:** Include in Phase 5 — replace `_BankEmptyStateCard` with real bank list, tap → bank detail page.

---

## Claude's Discretion

- Bank detail page layout
- JSON conversion layer (DB schema ↔ user JSON format)
- Stats page visual layout
- File save/open dialog integration
- Home page bank card design

## Deferred Ideas

- Bookmarks — removed by user, `Bookmarks` table retained but unused

---

*Phase: 05-json-export-import-multiple-choice-bookmarks-statistics*
*Log written: 2026-06-20*
