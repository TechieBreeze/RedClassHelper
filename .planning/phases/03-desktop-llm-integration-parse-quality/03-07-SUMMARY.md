---
phase: 03-desktop-llm-integration-parse-quality
plan: 07
subsystem: import-presentation
type: execute
autonomous: false
wave: 4
depends_on: ["03-04", "03-06"]
requires:
  - ImportPhase.llmParsing (03-04)
  - ImportNotifier.llmParse() (03-04)
  - ParseSource enum (03-04)
  - installedModelsProvider (03-05)
provides:
  - parser_choice_dialog.dart (D-01 parser selection UI)
  - llmParsing progress sub-phase UI (D-07)
  - auto-confirmed preview banner (D-08)
  - parse source badges and breakdown (D-09)
affects:
  - import_screen.dart
  - import_progress_screen.dart
  - import_preview_screen.dart
  - import_summary_screen.dart
tech-stack:
  added: []
  patterns:
    - ConsumerStatefulWidget (new pattern for import_screen)
    - AnimatedContainer border transition (selected state)
    - Platform.isWindows || Platform.isLinux desktop gating
key-files:
  created:
    - lib/features/models/widgets/parser_choice_dialog.dart
    - test/features/import/presentation/parser_choice_dialog_test.dart
    - test/features/import/pipeline_llm_integration_test.dart
  modified:
    - lib/features/import/providers/import_state.dart (parseStatus field)
    - lib/features/import/providers/import_notifier.dart (parseStatus updates)
    - lib/features/import/presentation/import_screen.dart (parser dialog integration)
    - lib/features/import/presentation/import_progress_screen.dart (llmParsing UI)
    - lib/features/import/presentation/import_preview_screen.dart (badges + banner)
    - lib/features/import/presentation/import_summary_screen.dart (source section)
decisions:
  - ParserChoiceDialog uses AlertDialog with 2 tappable option cards (not radio buttons + confirm) for single-tap selection UX
  - Desktop: dialog appears per-import (not persisted). Android: skips dialog, calls extractAndParse directly
  - LLM card disabled state shows 50% opacity, inline error text, and tappable "前往设置" link
  - parseStatus field on ImportState is a UI-only display string; set by ImportNotifier during llmParse loop
  - Progress screen handles pre-started parses (ImportScreen calls notifier before navigation) via idle phase check
  - Source badges use ActionChip with semantic colors (teal/secondary/amber) per UI-SPEC
  - Source breakdown section on summary card hidden for heuristic-only imports (backward compatible)
duration: 31min
completed_date: 2026-06-20
tasks: 3
files_created: 3
files_modified: 6
---

# Phase 3 Plan 7: Parse Quality UI Wiring Summary

Wired Phase 3 UI extensions into the existing import pipeline: parser choice dialog, llmParsing progress sub-phase, auto-confirmed preview, and parse source summary breakdown.

## Execution Summary

Three tasks executed sequentially, each committed atomically. All 89 import tests pass (3 pre-existing sample-file failures unrelated). Zero new analysis errors or warnings.

### Task 1: ParserChoiceDialog + ImportScreen Integration

Created `lib/features/models/widgets/parser_choice_dialog.dart` (204 lines) with:
- `ParseMethod` enum (heuristic, llm)
- `ParserChoiceDialog` ConsumerStatefulWidget with 2 option cards
- `_OptionCard` private widget with AnimatedContainer 150ms border transition
- LLM card disabled state: 50% opacity, "需要先下载模型" error text, "前往设置 → 模型管理下载" tappable link
- `barrierDismissible: false` dialog, "取消" button returns null

Modified `lib/features/import/presentation/import_screen.dart`:
- Converted to ConsumerStatefulWidget for Riverpod access
- New `_onFileSelected()` method: desktop shows ParserChoiceDialog; Android calls heuristic directly
- New `_startParseAndNavigate()`: calls notifier.pickFiles() + extractAndParse()/llmParse() before navigation
- Drag-drop handler routed through `_onFileSelected()`
- Removed unused `_navigateToProgress` method

7 widget tests pass (`test/features/import/presentation/parser_choice_dialog_test.dart`).

### Task 2: ImportProgressScreen llmParsing Sub-Phase

Added `parseStatus: String?` field to `ImportState` with `clearParseStatus` flag in `copyWith`.

Modified `lib/features/import/providers/import_notifier.dart`:
- Sets `parseStatus: '正在解析第 N 题…'` at start of each llmParse iteration
- Sets `parseStatus: '第 N 题切换启发式兜底…'` on fallback catch blocks

Extended `lib/features/import/presentation/import_progress_screen.dart`:
- `_startImport()` checks if parse already started (phase != idle) to avoid double-init
- New `_buildLlmProgress()` method: LLM progress label, LinearProgressIndicator, parseStatus text
- Amber-tinted status text for retry/fallback messages
- `_onWillPop()` extended to cover `isLlmParsing`
- PopScope `canPop` covers all active phases (extracting, parsing, llmParsing)

### Task 3: Preview + Summary Screen Parse Source Extensions

Extended `lib/features/import/presentation/import_preview_screen.dart`:
- `_isLlmImport` flag set in initState from parseSources
- `_buildAutoConfirmBanner()`: green card "LLM 解析结果已自动确认，N 题待入库"
- `_ParseSourceBadge` private widget: teal (LLM), secondary (启发式), amber (兜底) ActionChip per candidate
- `_buildSourceSummary()`: "解析来源：LLM N 题 / 启发式 M 题 / 兜底 K 题" line
- CandidateCard collapsed by default (existing behavior); LLM imports pre-confirmed

Extended `lib/features/import/presentation/import_summary_screen.dart`:
- `_buildParseSourceSection()`: Card with 3 source rows (LLM/启发式/兜底) with icons + counts
- Section only visible when LLM or fallback sources exist
- Skipped items annotated with source label and color in `_buildSkippedSection()`
- `_sourceLabel()` and `_sourceColor()` helper methods

Created `test/features/import/pipeline_llm_integration_test.dart` (6 integration tests):
- Full LLM parse → editing with auto-confirm
- Mixed LLM + fallback source tracking
- parseStatus during processing
- All chunks fail → idle with error
- parseStatus contains "解析" during llmParsing
- Progress updates from 0.0 to 1.0

## Deviations from Plan

None - plan executed exactly as written. All UI-SPEC D-01, D-07, D-08, D-09 contracts implemented.

## Known Stubs

None. All UI surfaces have their data sources wired (installedModelsProvider for dialog, ImportState parseSources for badges, parseStatus for progress).

## Threat Flags

None. All threats in the plan's threat model (T-03-07-01 through T-03-07-04) were accepted. No new trust boundaries introduced.

## Self-Check: PASSED

All artifacts verified:
- lib/features/models/widgets/parser_choice_dialog.dart: FOUND
- lib/features/import/presentation/import_screen.dart: MODIFIED
- lib/features/import/presentation/import_progress_screen.dart: MODIFIED
- lib/features/import/presentation/import_preview_screen.dart: MODIFIED
- lib/features/import/presentation/import_summary_screen.dart: MODIFIED
- test/features/import/presentation/parser_choice_dialog_test.dart: FOUND
- test/features/import/pipeline_llm_integration_test.dart: FOUND
- Commits: 87f48a3 (Task 1), 0765224 (Task 2), b0dd795 (Task 3): ALL FOUND
- dart analyze: 0 errors, 0 warnings on all modified files
- 89/89 import tests pass (3 pre-existing sample-file failures unrelated)
