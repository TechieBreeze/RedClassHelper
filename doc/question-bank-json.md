# Question Bank JSON Format (RedClass)

> **Status**: STUB — will be finalized in Phase 5 (JSON Cross-Device Transfer) plan-phase.
> This document exists today only to anchor the cross-device transfer design. Do not implement against this stub; treat the format as pre-design.

## Purpose

RedClass uses a JSON file as the **cross-device transfer protocol** for question banks:

- **Desktop** (Windows / macOS / Linux) exports a parsed bank as JSON
- **All 5 platforms** (desktop + Android + iOS) can re-import that JSON to get a fully functional bank
- **Third parties** (the user themselves, future tools, alternate front-ends) can author or modify JSON files following this spec

This file is the authoritative specification. The JSON file format is **versioned** to allow future evolution.

## Design Constraints (informational; final spec lands in Phase 5)

- **Public format**: no proprietary binary blobs; UTF-8 text JSON; human-readable
- **Self-contained**: each file includes all questions + correct answers + metadata; no external dependencies
- **Round-trip safe**: an exported file, when re-imported, produces a bank functionally equivalent to the original
- **Cross-platform**: works on Windows / macOS / Linux / Android / iOS (the parser must tolerate BOM, LF/CRLF, JSON-LD or pure JSON; pure JSON preferred)
- **No PII**: no user-attempt history, no wrong-question ledger entries, no bookmarks; those are per-device, not transferred in v1

## Conceptual Shape (stub)

```json
{
  "$schema": "https://redclass.local/schemas/question-bank-v1.json",
  "version": "1.0.0",
  "exported_at": "2025-01-14T12:00:00Z",
  "exported_by": "RedClass 0.1.0",
  "bank": {
    "id": "uuid-once-imported",
    "name": "高数期末复习题库",
    "source": "老师发的 docx (2024-12-20)",
    "created_at": "2024-12-20T00:00:00Z"
  },
  "questions": [
    {
      "id": "uuid-once-imported",
      "type": "single",
      "stem": "下列哪个是连续函数的定义？",
      "options": [
        { "key": "A", "text": "..." },
        { "key": "B", "text": "..." },
        { "key": "C", "text": "..." },
        { "key": "D", "text": "..." }
      ],
      "correct": ["A"],
      "explanation": null,
      "tags": []
    }
  ]
}
```

For **multiple-choice** questions:

```json
{
  "type": "multiple",
  "stem": "下列哪些是连续函数的等价定义？",
  "options": [...],
  "correct": ["A", "C"],
  ...
}
```

## Versioning Strategy

- Major version (`X.0.0`): breaking changes to the format (rename fields, change types)
- Minor version (`1.X.0`): additive changes (new optional fields)
- Patch version (`1.0.X`): bug fixes / clarifications, no format change

Importer behavior on version mismatch:
- Same major version → import accepted
- Different major version → import rejected with clear error message

## What This File Will Contain When Finalized

- Full JSON Schema (Draft 2020-12) for the file
- Field-by-field documentation
- Validation rules (e.g., `correct` must be non-empty; `single` type requires exactly 1 element; `multiple` requires ≥2 elements)
- Worked example with real Chinese question text
- Round-trip test cases
- Migration notes for any future version bump

---

*Stub created: 2025-01-14 — finalizes in Phase 5 plan-phase*
