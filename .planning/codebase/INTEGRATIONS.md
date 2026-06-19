# Integrations

## Current State (Phase 1)

**No external APIs or services.** The application is fully offline by design.

## Internal Integration Points

### SQLite via drift

- **Provider:** `appDatabaseProvider` (keepAlive: true) in `lib/data/db/database.dart`
- **Path:** `PathResolver.databasePath` → `getApplicationSupportDirectory()/redclass.db`
- **Mode:** WAL journal mode, foreign_keys ON
- **Schema:** v1 — 7 tables (question_banks, questions, wrong_ledger_entries, answer_attempts, bookmarks, parse_jobs, parse_logs)
- **Access pattern:** All DB access through Riverpod providers; drift DAO auto-generated

### File System via PathResolver

- **Entry point:** `PathResolver.create()` (run in `main()` before `runApp()`)
- **Provider:** `pathResolverProvider` (keepAlive: true) in `lib/core/paths.dart`
- **3-layer path model:** AppSupport (DB) / AppDocs (models, cache, diagnostics) / Temp
- **Singleton enforcement:** `PathResolver` is the ONLY class allowed to import `path_provider`

### Dynamic Color via Material You

- **Entry point:** `DynamicColorBuilder` in `lib/main.dart`
- **Fallback:** Most desktops return null → `buildAppTheme()` in `lib/core/theme.dart` uses `ColorScheme.fromSeed()`

## Planned Integrations (Later Phases)

| Phase | Integration | Approach |
|-------|------------|----------|
| 2 | `file_picker` | Native file dialog (.doc/.docx/.pdf/.json) |
| 2 | `.docx` parsing | `archive` + `xml` (pure Dart WordprocessingML traversal) |
| 2 | `.doc` parsing | TBD — no known pure Dart OLE2 reader; may need pandoc/LibreOffice CLI fallback |
| 2 | `.pdf` parsing | `pdfx` or similar pub.dev package |
| 3 | llama.cpp FFI | `dart:ffi` bindings to `libllama` (.dll/.so); no pub.dev wrapper covers both Windows + Linux |
| 3 | HTTP fallback | OpenAI-compatible API as backup when local model unavailable |
| 5 | JSON import/export | `json_annotation` + `json_serializable` codegen already wired |
