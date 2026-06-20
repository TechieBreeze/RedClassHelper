# Phase 5: JSON Export/Import + Multiple-Choice + Statistics - Research

**Researched:** 2026-06-20
**Domain:** Flutter desktop JSON serialization, file I/O, drift SQL aggregation, multi-choice grading
**Confidence:** HIGH

## Summary

Phase 5 adds five interconnected features to the RedClass desktop app: (1) JSON export using system native save dialog, (2) JSON import integrated into the existing import pipeline with direct commit, (3) multiple-choice exact-match grading confirmation, (4) per-bank statistics with per-mode breakdown, and (5) real bank list on the home screen replacing the placeholder card. All 15 user decisions (D-01 through D-15) from the discuss-phase are locked and constrain implementation.

**Primary recommendation:** Reuse existing infrastructure heavily -- `file_picker` v11.0.2 already supports `saveFile()` on Windows/Linux, `bankPickListProvider` already provides bank list data, `QuizSessionController._gradeMultiChoice()` already implements exact-match grading. The primary new code is JSON format conversion layer (DB schema <-> user format), JSON import pipeline branch in `ImportNotifier`, statistics aggregation queries, and three screen implementations (BankDetailScreen, StatsScreen, home bank list).

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** JSON 格式对齐用户提供的真实题库格式。题目为编号对象（非数组），每题包含：`question`（题干，含题号前缀）、`answer`（`{"A":"...", ...}` 选项映射）、`key`（拼接答案字符串，如 `"B"` / `"ABC"`）、`answer_type`（`0`=单选, `1`=多选）。
- **D-02:** 题库级元数据：仅 `name` + `version`（schema version，初始 `"1.0"`）。不导出 timestamps 或原始 UUID。
- **D-03:** 导出入口：题库详情页（bank detail page）内的"导出 JSON"按钮。非右键菜单。
- **D-04:** 导出时弹出系统原生文件保存对话框，用户选择保存路径。
- **D-05:** JSON 导入集成到现有导入流程：导入页选 `.json` → 文件选择器 → 直接解析提交入库（不走预览编辑页，因为 JSON 格式已是精确数据）。
- **D-06:** 同名题库处理：替换已有题库（按题库名匹配）。不弹出确认对话框。
- **D-07:** 精确匹配判分 —— 用户必须选中全部正确选项且不多选任何错误选项才算正确。`["A","C"]` 选 `["A"]` 或 `["A","C","D"]` 均为错误。
- **D-08:** 多选题提交流程：复选框 + 确认按钮（QuizScreen 已有此逻辑，`isMultiChoice = correctKeys.length > 1` 时选项切换 + 必须点确认提交）。
- **D-09:** 每题题库统计卡片：总题数、总答题次数、正确率、错题本活跃错题数。
- **D-10:** 每题题库展开显示各模式正确率：乱序抽题 / 错题复习 / 错题抽查。
- **D-11:** 纯文字 + 数字展示，不使用图表。复用 `Card` + `InkWell` 模式。
- **D-12:** 移除"还没有题库"占位卡片，接入真实题库列表（已有 `questionBanksProvider`）。
- **D-13:** 题库卡片显示：题库名、题数、来源文件名。点击进入题库详情页（bank detail）。
- **D-14:** 题库详情页提供"导出 JSON"按钮 + "开始复习"入口。
- **D-15:** 收藏功能从 Phase 5 移出（用户明确"不需要收藏"）。已存在的 `Bookmarks` 表保留但不使用。主页不添加收藏入口。QuizScreen 不添加星标按钮。

### Claude's Discretion

- 题库详情页（BankDetailScreen）具体布局
- JSON 转换层实现（DB schema `optionsJson`/`correctJson` <-> 用户 JSON 格式 `answer`/`key`）
- 统计页视觉布局（卡片 per bank，展开/per-mode 分解，无图表）
- 文件保存/打开对话框集成
- 主页题库卡片设计

### Deferred Ideas (OUT OF SCOPE)

- 收藏功能 — 用户明确"不需要收藏"。`Bookmarks` 表保留但不在 Phase 5 实现。
- 暗色/浅色主题切换 — Phase 6
- 答题页动画打磨 — Phase 6
- session state 恢复 — Phase 6
- 统计图表（趋势图、错题分布图）— v2
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| IMP-06 | Desktop user can export a parsed question bank as a standard JSON file | Sec. 1 (JSON Export): file_picker saveFile + dart:io write |
| IMP-07 | Desktop user can select a `.json` file and import it as a question bank | Sec. 2 (JSON Import): ImportNotifier fast-track + duplicate replace |
| QST-02 | App supports multiple-choice questions (all correct options must be selected) | Sec. 3 (Multi-choice grading): already implemented in QuizSessionController |
| STAT-02 | User can view answer statistics: correct rate, per-mode aggregation | Sec. 4 (Statistics): drift aggregation queries |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `dart:convert` | (built-in) | JSON encode/decode for export and import | Already used throughout codebase (jsonEncode/jsonDecode); no third-party JSON lib needed |
| `dart:io` | (built-in) | File write for JSON export (`File().writeAsBytes()` / `File().writeAsString()`) | Native Dart; already used across codebase for file I/O |
| `file_picker` | 11.0.2 | System native file save dialog (`saveFile()`) and file open dialog | Already a direct dependency; supports saveFile on Windows + Linux [VERIFIED: pubspec.lock] |
| `drift` | 2.34.0 | SQL aggregation queries for statistics (COUNT, GROUP BY, JOIN) | Already the project ORM; schema already defined |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `uuid` | 4.5.1 | Generate new bank/import job IDs for JSON import | Already in deps; used in ImportNotifier |
| `go_router` | 17.3.0 | Navigation to /bank/:id, /stats (routes already exist) | Already the only navigation API |
| `flutter_riverpod` | 3.3.2 | New providers for stats data + existing bankPickListProvider | Already the state management framework |
| `riverpod_annotation` | 4.0.3 | @riverpod codegen for new stats providers | Already used project-wide |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `file_picker.saveFile()` | `file_saver` package | `file_saver` requires additional dependency; `file_picker` is already installed and supports saveFile on Windows+Linux |
| `dart:io` direct file write | `file_picker.saveFile(bytes:)` | `saveFile(bytes:)` only works on mobile (writes bytes directly); on desktop it only opens the dialog and ignores bytes [VERIFIED: file_picker issue #1725]. Manual write with `dart:io` is the documented desktop workaround |
| Custom stats provider | `bankPickListProvider` reuse | `bankPickListProvider` is per-bank preview data; stats need different aggregation (per-mode breakdown, global totals). New provider needed |

**Installation:**
```bash
# No new dependencies needed. All required packages are already in pubspec.yaml.
```

**Version verification:** `file_picker` version confirmed as 11.0.2 in pubspec.lock (sha256: f13a0300...). `saveFile()` API stable since file_picker 8.x; fully supported on Windows and Linux in v11.x [VERIFIED: pubspec.lock + GitHub miguelpruivo/flutter_file_picker].

## Architecture Patterns

### Recommended Project Structure (New Files)
```
lib/
├── features/
│   ├── bank_detail/
│   │   └── presentation/
│   │       └── bank_detail_screen.dart     # Full implementation (currently placeholder)
│   ├── export/                              # NEW: JSON export feature
│   │   └── services/
│   │       └── json_export_service.dart     # DB → user JSON format conversion + file write
│   ├── home/
│   │   └── presentation/
│   │       └── home_screen.dart            # Modified: replace _BankEmptyStateCard with Consumer
│   ├── import/
│   │   ├── presentation/
│   │   │   └── import_screen.dart          # Existing; JSON tile already wired
│   │   └── providers/
│   │       ├── import_notifier.dart         # Extended: add importJsonFile() method
│   │       └── import_state.dart           # No change needed (ImportPhase enum sufficient)
│   ├── quiz/
│   │   └── providers/
│   │       └── quiz_session_controller.dart # Verify: _gradeMultiChoice() already exact-match
│   └── stats/
│       ├── presentation/
│       │   └── stats_screen.dart           # Full implementation (currently placeholder)
│       └── providers/
│           └── stats_provider.dart         # NEW: per-bank + per-mode aggregation queries
└── data/
    ├── db/
    │   └── tables/                          # No schema changes needed
    └── repositories/
        └── ledger_repository.dart           # Existing; getActiveByBank() already available
```

### Pattern 1: JSON Format Conversion Layer (DB <-> User Format)

**What:** A bidirectional converter that maps between the DB schema (optionsJson/correctJson/type columns) and the user's established JSON format (answer option map / key concatenated string / answer_type 0/1).

**When to use:** On export (DB data → user JSON) and import (user JSON → DB entities).

**DB Schema (source of truth):**
```
Questions table:
  type: 'single' | 'multiple'
  optionsJson: '[{"key":"A","text":"选项内容"}, ...]'
  correctJson: '["A"]' or '["A","C"]'
```

**User JSON Format (D-01):**
```json
{
  "name": "题库名称",
  "version": "1.0",
  "questions": {
    "1": {
      "question": "1. 这是题干内容",
      "answer": {"A": "选项A内容", "B": "选项B内容"},
      "key": "A",
      "answer_type": 0
    },
    "2": {
      "question": "2. 多选题干",
      "answer": {"A": "选项A", "B": "选项B", "C": "选项C", "D": "选项D"},
      "key": "ABC",
      "answer_type": 1
    }
  }
}
```

**Conversion mapping (D-01 + D-02):**

| Direction | DB Field | User JSON Field | Transformation |
|-----------|----------|-----------------|----------------|
| Export | `type` | `answer_type` | `'single'` → `0`, `'multiple'` → `1` |
| Export | `optionsJson` | `answer` | `[{"key":"A","text":"x"}]` → `{"A":"x"}` |
| Export | `correctJson` | `key` | `["A","C"]` → `"AC"` (concatenated) |
| Export | `bank.name` | `name` | Direct copy |
| Export | schema version | `version` | Always `"1.0"` |
| Import | `answer_type` | `type` | `0` → `'single'`, `1` → `'multiple'` |
| Import | `answer` | `optionsJson` | `{"A":"x"}` → `[{"key":"A","text":"x"}]` |
| Import | `key` | `correctJson` | `"AC"` → `["A","C"]` (split chars) |

**Key constraint (D-01):** Questions are numbered objects (`"1": {...}, "2": {...}`), NOT a JSON array. This matches real Chinese university exam format where question numbering is significant. Parsing order: extract keys, sort numerically, iterate.

**Example (verified from user's real 159-question sample):**
```json
{
  "name": "2024秋-数据库原理",
  "version": "1.0",
  "questions": {
    "1": {
      "question": "1. 数据库系统的核心是_____。",
      "answer": {"A": "数据库", "B": "数据库管理系统", "C": "数据模型", "D": "软件工具"},
      "key": "B",
      "answer_type": 0
    }
  }
}
```
[CITED: CONTEXT.md D-01 + user-provided real question bank JSON sample]

### Pattern 2: JSON Export Flow (D-03, D-04)

**What:** BankDetailScreen "导出 JSON" button → system native save dialog → DB query → JSON convert → file write → SnackBar feedback.

**Sequence:**
```dart
// Source: file_picker saveFile API + dart:io File.writeAsString
Future<void> _exportJson(BankDetailData bank) async {
  // 1. Open system native save dialog
  final outputPath = await FilePicker.platform.saveFile(
    dialogTitle: '导出 JSON 题库',
    fileName: '${bank.name}.json',
    type: FileType.custom,
    allowedExtensions: ['json'],
  );

  if (outputPath == null) return; // User cancelled

  // 2. Load questions from DB
  final questions = await db...;

  // 3. Convert to user JSON format
  final json = JsonExportService.toUserFormat(bank, questions);

  // 4. Write file
  try {
    await File(outputPath).writeAsString(jsonEncode(json));
    // 5. Show success SnackBar
    showSnackBar('已导出到 ${p.basename(outputPath)}');
  } catch (e) {
    showSnackBar('导出失败: $e');
  }
}
```

**Critical detail:** `file_picker.saveFile(bytes:)` does NOT write bytes on desktop -- it only opens the dialog and returns the path. The `bytes` parameter is ignored on Windows/Linux [VERIFIED: GitHub file_picker issue #1725]. Always use two-step: `saveFile()` for path, `dart:io File().writeAsString()` for content.

### Pattern 3: JSON Import Fast-Track (D-05, D-06)

**What:** A new `importJson()` method in `ImportNotifier` that bypasses the extraction/parsing/editing phases and directly commits to DB.

**Sequence:**
1. `ImportScreen._pickJsonFile()` already exists and calls `_onFileSelected()`
2. In `_startParseAndNavigate()`: detect `.json` extension → call new `importJson()` method
3. `importJson()`: read file → `jsonDecode()` → validate format → `_convertAndCommit()`
4. Skip editing phase entirely (D-05: "JSON 格式已是精确数据")
5. Navigate directly to import summary

**Duplicate bank handling (D-06):**
```dart
// Inside a DB transaction:
final existingBank = await (db.select(db.questionBanks)
  ..where((b) => b.name.equals(jsonBankName))
).getSingleOrNull();

if (existingBank != null) {
  // Delete old bank (cascade deletes all its questions + ledger + attempts)
  await (db.delete(db.questionBanks)
    ..where((b) => b.id.equals(existingBank.id))
  ).go();
}

// Insert new bank + questions
await db.into(db.questionBanks).insert(newBank);
for (final q in convertedQuestions) {
  await db.into(db.questions).insert(q);
}
```

**No user-facing confirmation dialog (D-06).** Show SnackBar "已替换已有题库「bankName」" after successful replacement.

**JSON validation before commit:**
- Must have `name` (string, non-empty)
- Must have `version` (string)
- Must have `questions` (Map, non-empty)
- Each question must have: `question` (string), `answer` (Map<String,String>), `key` (string, A-H chars only), `answer_type` (int, 0 or 1)
- `key` must not be empty; `key` for `answer_type=0` must be single char
- Reject entire import with clear error message on validation failure

### Pattern 4: Statistics Aggregation Queries

**What:** Drift queries that aggregate `AnswerAttempts` + `Questions` + `QuestionBanks` + `WrongLedgerEntries` data per bank and per mode.

**Per-bank aggregate (D-09):**
```dart
// Total questions: SELECT COUNT(*) FROM questions WHERE bank_id = ?
// Already available: bank.questionCount or COUNT query

// Total attempts: SELECT COUNT(*) FROM answer_attempts
//   JOIN questions ON questions.id = answer_attempts.question_id
//   WHERE questions.bank_id = ?

// Correct rate: (COUNT WHERE is_correct=1) / (total attempts) * 100

// Ledger active count: Already available via ledgerRepo.getActiveByBank(bankId)
```

**Per-mode breakdown (D-10):**
```dart
// For each mode ('random', 'review', 'spotcheck'):
//   SELECT COUNT(*), SUM(CASE WHEN is_correct THEN 1 ELSE 0 END)
//   FROM answer_attempts
//   JOIN questions ON questions.id = answer_attempts.question_id
//   WHERE questions.bank_id = ? AND answer_attempts.mode = ?
```

**Implementation approach:** Use drift's `selectOnly()` with `addColumns()` + `COUNT()` + `SUM()` expressions for efficient aggregation in a single query per bank. Wrap in a Riverpod provider that returns `Future<List<BankStats>>`.

**D-11 enforcement:** Return typed data models (`BankStats`, `ModeBreakdown`), not chart widgets. StatsScreen renders numbers as text only.

### Pattern 5: Home Screen Bank List (D-12, D-13)

**What:** Replace `_BankEmptyStateCard` (always visible) with a `Consumer` widget that watches `bankPickListProvider`.

**States:**
| State | Widget |
|-------|--------|
| Loading (`AsyncValue.loading`) | Skeleton cards with shimmer-like surface + spinner |
| Empty (`AsyncValue.data` with empty list) | Keep existing `_BankEmptyStateCard` |
| Error (`AsyncValue.error`) | Error card with retry button |
| Data (`AsyncValue.data` with items) | Vertical list of `_BankCard` widgets |

**Data source:** `bankPickListProvider` (already exists at `lib/features/quiz/providers/bank_pick_provider.dart`). Returns `Future<List<BankPickItem>>` where each item has:
- `bank`: `QuestionBank` (id, name, source, questionCount, createdAt, updatedAt)
- `totalQuestions`: int
- `activeWrongCount`: int

**`_BankCard` fields per D-13:**
- Bank name (`bank.name`, `titleMedium`)
- Question count (`"${item.totalQuestions}题"`)
- Source filename (`bank.source`, displayed via `p.basename()`)
- Tap → `context.push('/bank/${bank.id}')`

### Anti-Patterns to Avoid

- **Do NOT use `file_picker.saveFile(bytes:)` for writing content on desktop** -- the `bytes` parameter is ignored on Windows/Linux. Always use `saveFile()` for path selection, then `dart:io File().writeAsString()` for writing.
- **Do NOT add confirmation dialog for bank replacement on import** -- D-06 explicitly prohibits this.
- **Do NOT create charts or graphs for stats** -- D-11 explicitly requires text + numbers only.
- **Do NOT add bookmark UI elements** -- D-15 explicitly removes bookmarks from Phase 5.
- **Do NOT add new GoRouter routes** -- /bank/:id, /stats already exist. No new routes needed.
- **Do NOT use Navigator.push** -- GoRouter is the only navigation API per project convention.
- **Do NOT introduce `FontWeight.w600`** -- Phase 5 additions must use w700 (Bold) for emphasis per UI-SPEC.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| System native file save dialog | Custom platform channel for save dialog | `FilePicker.platform.saveFile()` | Already a dependency; handles Windows COM dialog + Linux zenity/kdialog/qarma; tested on both platforms |
| JSON serialization | Custom string builder | `dart:convert jsonEncode/jsonDecode` | Built-in, fast, handles UTF-8, already used everywhere in codebase |
| JSON format validation | Manual field-by-field checks | `_validateJsonFormat()` helper + typed data classes | Schema validation with clear error messages; typed conversion isolates format logic |
| File I/O for export | Stream-based or buffered writer | `File().writeAsString(jsonEncode(data))` | Simple, atomic, handles encoding. Question banks are small (<1MB for 500+ questions) |
| Statistics aggregation | Multiple sequential queries per bank | Single `selectOnly()` with COUNT + SUM expressions | Drift supports complex aggregations; single query avoids N+1 problem |
| Bank duplicate detection | Manual name comparison | `db.select(db.questionBanks)..where((b) => b.name.equals(name)).getSingleOrNull()` | Drift's type-safe query builder; returns null if not found |
| Expanding card animation | Custom animation controller | `AnimatedCrossFade` or `AnimatedSize` + `Visibility` | Built-in M3 widgets; AnimatedRotation for chevron per UI-SPEC |

**Key insight:** The heavy lifting (file dialogs, JSON encoding, DB queries) is handled by existing dependencies. The only "new" code is the JSON format conversion layer and statistics aggregation queries, both of which are straightforward data transformations.

## Runtime State Inventory

> Phase 5 is primarily greenfield feature additions (no rename/refactor). Skip full inventory.

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| Stored data | None — Phase 5 adds new data (JSON exports, stats views), doesn't rename existing data | — |
| Live service config | None — no external services | — |
| OS-registered state | None | — |
| Secrets/env vars | None | — |
| Build artifacts | None | — |

**Nothing found in any category — Phase 5 adds features, does not rename/move existing state.**

## Common Pitfalls

### Pitfall 1: file_picker saveFile bytes ignored on desktop
**What goes wrong:** Developer calls `FilePicker.platform.saveFile(bytes: jsonBytes, fileName: 'bank.json')` expecting the file to be written. On desktop (Windows/Linux), the dialog opens and returns a path, but the bytes are silently ignored. No error is thrown; the file is never created.
**Why it happens:** `file_picker` v11.x (and v12 beta) only writes bytes on mobile (Android/iOS). Desktop platforms use OS-native dialogs that return a path only [VERIFIED: GitHub issue #1725].
**How to avoid:** Always use two-step: `saveFile()` for path → `File(outputPath).writeAsBytes(bytes)` for content. **Never pass `bytes` parameter on desktop.**
**Warning signs:** Export "succeeds" (no error) but file doesn't exist at expected location.

### Pitfall 2: JSON numbered-object key ordering
**What goes wrong:** `jsonDecode()` parses `{"2": {...}, "1": {...}}` as a `Map<String, dynamic>`. Iterating with `.entries` or `.forEach` may not preserve insertion order for numeric keys. Questions could appear out of order.
**Why it happens:** Dart `Map` does NOT guarantee insertion order for numeric-looking string keys. `jsonDecode` may reorder `"1"`, `"2"`, ..., `"159"`.
**How to avoid:** Extract keys, sort them numerically (`keys.map(int.parse).toList()..sort()`), then iterate in sorted order. Never iterate `jsonMap.entries` directly for ordered output.
**Warning signs:** Exported JSON has questions in wrong order (e.g., question 5 appears before question 1).

### Pitfall 3: Duplicate bank replacement not atomic
**What goes wrong:** Delete old bank, then insert new bank in separate operations. If insert fails mid-way, the old bank is lost.
**Why it happens:** Separate DB operations without transaction wrapping.
**How to avoid:** Wrap the entire delete+insert sequence in `db.transaction(() async { ... })`. Drift transactions are atomic -- if any operation fails, all changes roll back.
**Warning signs:** App crash during JSON import leaves bank in partially-deleted state.

### Pitfall 4: Stats correct rate division by zero
**What goes wrong:** Computing correct rate when a bank has 0 attempts produces `NaN` or division error.
**Why it happens:** `correctCount / totalAttempts` when `totalAttempts == 0`.
**How to avoid:** Guard with `if (totalAttempts == 0) return '暂无'` (per UI-SPEC copywriting contract). Never compute percentage without checking denominator.

### Pitfall 5: JSON import overwrite with different question count
**What goes wrong:** User imports a bank with 50 questions that replaces an existing bank with 200 questions. Answer history from the old bank's questions is cascade-deleted. User loses all review progress silently.
**Why it happens:** D-06 mandates silent replacement (no confirm dialog). Cascade delete on QuestionBanks FK removes all related data.
**How to avoid:** This is by design per D-06. Mitigate by showing clear SnackBar message: "已替换已有题库「bankName」(200题 → 50题)". The user should understand the scope of the replacement. **Do not add a confirmation dialog** -- D-06 explicitly prohibits it.

## Code Examples

### Export: DB to User JSON Format Conversion

```dart
// Source: D-01 format specification + existing DB schema
/// Converts a bank + its questions to the user's established JSON format.
Map<String, dynamic> bankToUserJson(
  QuestionBank bank,
  List<Question> questions,
) {
  final questionsMap = <String, dynamic>{};
  for (var i = 0; i < questions.length; i++) {
    final q = questions[i];
    final optionsList = (jsonDecode(q.optionsJson) as List)
        .map((o) => Map<String, dynamic>.from(o as Map))
        .toList();
    final correctList = List<String>.from(jsonDecode(q.correctJson) as List);

    // Convert options array to answer map: {"A": "text", "B": "text"}
    final answerMap = <String, String>{};
    for (final opt in optionsList) {
      answerMap[opt['key'] as String] = opt['text'] as String;
    }

    // Convert correct keys array to concatenated string: ["A","C"] → "AC"
    final keyStr = correctList.join();

    questionsMap['${i + 1}'] = {
      'question': '${i + 1}. ${q.stem}',
      'answer': answerMap,
      'key': keyStr,
      'answer_type': q.type == 'multiple' ? 1 : 0,
    };
  }

  return {
    'name': bank.name,
    'version': '1.0',
    'questions': questionsMap,
  };
}
```

### Import: User JSON to DB Entities

```dart
// Source: D-01 format specification + existing drift table definitions
/// Converts user JSON format to Question entities for DB insertion.
({String bankName, List<QuestionsCompanion> questions}) userJsonToEntities(
  Map<String, dynamic> json,
  String bankId,
) {
  final bankName = json['name'] as String;
  final questionsMap = json['questions'] as Map<String, dynamic>;

  // Sort keys numerically (Pitfall 2)
  final sortedKeys = questionsMap.keys
      .map((k) => int.parse(k))
      .toList()
    ..sort();

  final companions = <QuestionsCompanion>[];
  for (final numKey in sortedKeys) {
    final q = questionsMap['$numKey'] as Map<String, dynamic>;
    final answerMap = Map<String, String>.from(q['answer'] as Map);
    final keyStr = (q['key'] as String).toUpperCase();
    final answerType = q['answer_type'] as int; // 0=single, 1=multiple

    // Convert answer map to options array: {"A":"text"} → [{"key":"A","text":"text"}]
    final optionsList = answerMap.entries.map((e) => {
      'key': e.key,
      'text': e.value,
    }).toList();

    // Convert key string to array: "AC" → ["A","C"]
    final correctList = keyStr.split('').toList();

    companions.add(QuestionsCompanion.insert(
      id: const Uuid().v4(),
      bankId: bankId,
      type: answerType == 1 ? 'multiple' : 'single',
      stem: (q['question'] as String),
      optionsJson: jsonEncode(optionsList),
      correctJson: jsonEncode(correctList),
      rawText: (q['question'] as String),
      createdAt: DateTime.now(),
    ));
  }

  return (bankName: bankName, questions: companions);
}
```

### File Save Dialog + Write Pattern

```dart
// Source: file_picker 11.0.2 saveFile API + GitHub issue #1725 workaround
Future<void> exportBankToFile(
  BuildContext context,
  String bankName,
  Map<String, dynamic> jsonData,
) async {
  // Step 1: Open native save dialog
  final outputPath = await FilePicker.platform.saveFile(
    dialogTitle: '导出 JSON 题库',
    fileName: '$bankName.json',
    type: FileType.custom,
    allowedExtensions: ['json'],
  );

  if (outputPath == null || !context.mounted) return; // Cancelled

  // Step 2: Write content (desktop: bytes parameter is ignored)
  try {
    final file = File(outputPath);
    await file.writeAsString(jsonEncode(jsonData));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已导出到 ${p.basename(outputPath)}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('导出失败: $e'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}
```

### Statistics: Per-Bank Aggregation Query

```dart
// Source: drift 2.34.0 selectOnly API + existing LedgerRepository patterns
/// Aggregated statistics for a single question bank.
@immutable
class BankStats {
  const BankStats({
    required this.bank,
    required this.totalQuestions,
    required this.totalAttempts,
    required this.correctCount,
    required this.activeLedgerCount,
    required this.modes,
  });

  final QuestionBank bank;
  final int totalQuestions;
  final int totalAttempts;
  final int correctCount;
  final int activeLedgerCount;
  final List<ModeBreakdown> modes;

  double get correctRate =>
      totalAttempts == 0 ? 0.0 : correctCount / totalAttempts;
}

@immutable
class ModeBreakdown {
  const ModeBreakdown({
    required this.mode,
    required this.attempts,
    required this.correctCount,
  });

  final String mode; // 'random', 'review', 'spotcheck'
  final int attempts;
  final int correctCount;

  double get correctRate =>
      attempts == 0 ? 0.0 : correctCount / attempts;

  String get displayName => switch (mode) {
    'random' => '乱序抽题',
    'review' => '错题复习',
    'spotcheck' => '错题抽查',
    _ => mode,
  };
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `doc/question-bank-json.md` stub format (array-based, `$schema`, `exported_at`, `correct` array) | D-01 user format (numbered objects, `answer` map, `key` string, `answer_type` 0/1) | Phase 5 discuss-phase | The stub in `doc/` is stale -- do not implement against it. Use D-01 format exclusively. |
| LLM/Heuristic import pipeline (extract → parse → edit → commit) | JSON fast-track (parse → commit, skip edit) | Phase 5 (D-05) | JSON imports bypass the editing phase entirely |
| Single-choice grading only | Multi-choice exact-match grading | Phase 5 (D-07) | Already implemented in Phase 4 `_gradeMultiChoice()`; Phase 5 verifies correctness |

**Deprecated/outdated:**
- `doc/question-bank-json.md`: The array-based stub format with `$schema`, `exported_at`, and `correct: ["A"]` field names is superseded by D-01's user format (numbered objects, `key` string, `answer_type` int). Update this doc to match D-01 during Phase 5.
- `_BankEmptyStateCard` (_always visible_ variant): The card is kept for the empty state but the "always shown as placeholder" behavior is removed in favor of real bank list rendering.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `file_picker` 11.0.2 `saveFile()` works on Linux via zenity/kdialog/qarma auto-detection | Standard Stack | If none of these dialog tools are installed on a minimal Linux system, the save dialog fails silently. Mitigation: detect and show clear error. LOW risk -- most desktop Linux distros ship at least one of these. |
| A2 | The `bankPickListProvider` returns data compatible with home screen bank card needs (bank.name, bank.source, totalQuestions) | Arch. Pattern 5 | Provider already exists and was built for BankPickerScreen. If it lacks a field needed for home cards, extend `BankPickItem`. LOW risk -- code review confirms all needed fields exist. |
| A3 | `QuizSessionController._gradeMultiChoice()` uses exact-match Set comparison (as confirmed by code review) | Arch. Pattern 5 | If the implementation were partial-match, D-07 would not be satisfied. Verified by reading source: `correctSet.length == givenSet.length && correctSet.containsAll(givenSet)` -- this IS exact match. HIGH confidence. |
| A4 | User JSON format uses simple integer keys ("1", "2", ... "159") for question numbering | JSON Format Conversion | If format uses non-numeric keys (e.g., "Q1", "1-1"), sorting logic would break. Verified from user's real 159-question sample: keys are plain integers. HIGH confidence. |
| A5 | JSON export file size is manageable (<5MB for largest banks) for synchronous `writeAsString()` | JSON Export | If a bank has >10,000 questions with long stems, the JSON string could be >10MB. Synchronous write on the UI thread may cause a brief frame drop. Mitigation: run in compute isolate if profiling shows >16ms. LOW risk for typical university exam banks (50-200 questions). |

## Open Questions

1. **JSON export file encoding and BOM**
   - What we know: `dart:io File().writeAsString()` writes UTF-8 without BOM by default.
   - What's unclear: Whether Windows Notepad (which some users may use to inspect JSON) handles UTF-8 without BOM correctly for CJK characters.
   - Recommendation: Write UTF-8 with BOM on Windows (`utf8.encodeWithBom`), UTF-8 without BOM on Linux. Add a `Platform.isWindows` branch.

2. **Stats provider caching strategy**
   - What we know: Stats data changes after every quiz answer. `@riverpod` auto-disposes when no listeners.
   - What's unclear: Whether to `keepAlive: true` (stats screen is a secondary view, may not be frequently visited) or let it recompute on each visit.
   - Recommendation: Do NOT use `keepAlive: true`. StatsScreen queries are fast (<10ms for typical data volume). Re-computing on each visit is acceptable and ensures freshness.

3. **JSON import -- what to show on import summary screen**
   - What we know: D-05 says "直接解析提交入库（不走预览编辑页）". The existing `ImportSummaryScreen` shows committed count, bank name, and skipped items.
   - What's unclear: Whether to reuse the existing `ImportSummaryScreen` (at `/import/summary/:jobId`) or navigate directly to bank detail after JSON import.
   - Recommendation: Reuse `ImportSummaryScreen` for consistency. JSON import creates a ParseJob and uses the same `ImportNotifier` state. The summary shows "N 题导入成功" with the bank name. No skipped items (all JSON questions pass validation or the entire import is rejected).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | All features | Check | >=3.35.0 (from pubspec.yaml) | — |
| Dart SDK | All features | Check | ^3.12.2 (from pubspec.yaml) | — |
| `file_picker` package | JSON export save dialog, JSON import open dialog | ✓ | 11.0.2 | — (already installed) |
| `dart:io` | File write for export, file read for import | ✓ | (built-in) | — |
| `dart:convert` | JSON encode/decode | ✓ | (built-in) | — |
| `drift` / SQLite | Statistics queries, DB reads/writes | ✓ | 2.34.0 | — (already installed) |
| Linux: zenity/kdialog/qarma | Native save dialog on Linux via file_picker | Unknown | N/A | If none installed, file_picker saveFile fails. Detection + error message needed. |
| Windows: COM/OLE32 | Native save dialog on Windows via file_picker | ✓ | (built-in OS) | — |

**Missing dependencies with fallback:**
- Linux dialog tools (zenity/kdialog/qarma): If none are installed, the save dialog fails. Fallback: detect the error and show a clear message to the user: "需要安装 zenity 以使用文件保存对话框。运行: sudo apt install zenity".

**Missing dependencies with no fallback:**
- None. All core dependencies are already installed.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | `flutter_test` (built-in) + `ProviderScope` overrides |
| Config file | none -- implicit via `flutter test` |
| Quick run command | `flutter test` |
| Full suite command | `flutter test --coverage` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| IMP-06 | JSON export produces valid user-format JSON file round-trip safe | unit | `flutter test test/features/export/json_export_service_test.dart` | No -- Wave 0 |
| IMP-06 | Export save dialog opens with correct default filename | widget | `flutter test test/features/bank_detail/bank_detail_screen_test.dart` | No -- Wave 0 |
| IMP-07 | JSON import parses user format and creates bank with correct question count | unit | `flutter test test/features/import/json_import_test.dart` | No -- Wave 0 |
| IMP-07 | Duplicate bank name triggers silent replacement (D-06) | unit | `flutter test test/features/import/json_import_test.dart` | No -- Wave 0 |
| QST-02 | Multi-choice exact-match: correct selection scores correct | unit | `flutter test test/features/quiz/providers/quiz_session_controller_test.dart -- --name "multi-choice"` | Yes -- existing test may need extending |
| QST-02 | Multi-choice exact-match: missing option scores incorrect | unit | `flutter test test/features/quiz/providers/quiz_session_controller_test.dart` | Yes -- existing test may need extending |
| QST-02 | Multi-choice exact-match: extra option scores incorrect | unit | `flutter test test/features/quiz/providers/quiz_session_controller_test.dart` | Yes -- existing test may need extending |
| STAT-02 | Stats provider returns per-bank aggregates (total questions, attempts, rate) | unit | `flutter test test/features/stats/stats_provider_test.dart` | No -- Wave 0 |
| STAT-02 | Per-mode breakdown shows correct split by review mode | unit | `flutter test test/features/stats/stats_provider_test.dart` | No -- Wave 0 |
| STAT-02 | Stats screen empty state shows correct message when no attempts | widget | `flutter test test/features/stats/stats_screen_test.dart` | No -- Wave 0 |
| D-12 | Home screen shows real bank list when banks exist | widget | `flutter test test/features/home/home_screen_test.dart` | Yes -- existing test needs modification |
| D-13 | Bank card tap navigates to /bank/:id | widget | `flutter test test/features/home/home_screen_test.dart` | Yes -- existing test needs modification |

### Sampling Rate
- **Per task commit:** `flutter test` (all tests)
- **Per wave merge:** `flutter test --coverage`
- **Phase gate:** Full suite green + 80%+ coverage on new code before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/features/export/json_export_service_test.dart` -- covers IMP-06 (format conversion + round-trip)
- [ ] `test/features/import/json_import_test.dart` -- covers IMP-07 (JSON parse, duplicate replace, validation)
- [ ] `test/features/stats/stats_provider_test.dart` -- covers STAT-02 (aggregation queries, per-mode breakdown)
- [ ] `test/features/stats/stats_screen_test.dart` -- covers STAT-02 screen states (empty/loading/error/data)
- [ ] `test/features/bank_detail/bank_detail_screen_test.dart` -- covers BankDetailScreen (export button, review entry, layout)
- [ ] Modify `test/features/home/home_screen_test.dart` -- covers D-12/D-13 (bank list rendering, card tap navigation)
- [ ] Modify `test/features/quiz/providers/quiz_session_controller_test.dart` -- extend multi-choice grading test cases if coverage incomplete

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | No auth in this desktop app |
| V3 Session Management | No | No sessions |
| V4 Access Control | No | Single-user desktop app |
| V5 Input Validation | Yes | JSON import: validate structure, field types, key constraints before DB commit. Reject malformed JSON with clear error. |
| V6 Cryptography | No | No cryptographic operations in Phase 5 |

### Known Threat Patterns for Flutter Desktop + JSON

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Malicious JSON file (oversized, deeply nested) causing DoS on import | Denial of Service | Validate JSON size before parsing (reject >10MB). Limit nesting depth. Use `jsonDecode` which has built-in nesting limits in Dart 3.x. |
| JSON injection via crafted `key` field (e.g., `key: "A; DROP TABLE"`) | Tampering | Validate `key` contains only A-H characters via regex before processing. Reject on validation failure. |
| Path traversal via crafted bank `name` in JSON export filename | Tampering | Sanitize `bankName` for filename use: strip path separators (`/`, `\`, `:`) before constructing default filename. `p.basename()` on final path. |
| Information disclosure via exported JSON (UUIDs, timestamps exposed) | Information Disclosure | D-02 explicitly prohibits exporting timestamps and UUIDs. Export format only includes `name` + `version` metadata. Verify no PII leaks into export. |

## Sources

### Primary (HIGH confidence)
- `pubspec.lock` -- confirmed `file_picker` version 11.0.2 with sha256 verification
- `lib/features/quiz/providers/quiz_session_controller.dart` -- confirmed `_gradeMultiChoice()` exact-match Set comparison (lines 277-283)
- `lib/features/quiz/providers/bank_pick_provider.dart` -- confirmed `bankPickListProvider` returns `List<BankPickItem>` with bank, totalQuestions, activeWrongCount
- `lib/features/import/providers/import_notifier.dart` -- confirmed 7-phase ImportPhase enum and `extractAndParse()` pipeline
- `lib/features/import/presentation/import_screen.dart` -- confirmed JSON tile already wired to `_pickJsonFile()` (lines 209-214)
- `lib/data/db/tables/questions.dart` -- confirmed Questions table schema (type, optionsJson, correctJson columns)
- `lib/data/db/tables/question_banks.dart` -- confirmed QuestionBanks table schema (name, source, questionCount)
- `lib/data/db/tables/answer_attempts.dart` -- confirmed AnswerAttempts table schema (mode, isCorrect, elapsedMs)
- `lib/data/repositories/ledger_repository.dart` -- confirmed `getActiveByBank()` method available
- `lib/core/paths.dart` -- confirmed PathResolver structure (jsonImportDir/jsonExportDir mentioned in CONTEXT but not implemented; PathResolver has databasePath, modelsDir, tempDir, etc.)
- `doc/question-bank-json.md` -- STUB (superseded by D-01), confirmed format difference
- `.planning/codebase/CONVENTIONS.md` -- confirmed StatelessWidget, const constructors, Card+InkWell, LayoutBuilder patterns
- GitHub `miguelpruivo/flutter_file_picker` issue #1725 -- confirmed saveFile(bytes:) ignored on desktop

### Secondary (MEDIUM confidence)
- WebSearch: `file_picker` saveFile API documentation -- confirmed `saveFile()` supported on Windows/Linux, confirmed `bytes` parameter desktop behavior
- DeepWiki: `miguelpruivo/flutter_file_picker` API Reference -- confirmed parameter list, platform support matrix

### Tertiary (LOW confidence)
- WebSearch: `filegate` as alternative to `file_picker` -- not needed since file_picker already meets requirements

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all packages already in pubspec.lock; versions confirmed; saveFile API verified
- Architecture: HIGH -- patterns derived from existing codebase conventions (Card+InkWell, LayoutBuilder, Riverpod ConsumerWidget); JSON format explicitly specified in D-01
- Pitfalls: HIGH -- file_picker saveFile(bytes:) issue confirmed via official GitHub issue; other pitfalls derived from direct code review
- Multi-choice grading: HIGH -- confirmed already implemented in source code with exact-match logic

**Research date:** 2026-06-20
**Valid until:** 2026-07-20 (30 days -- stable Flutter ecosystem; no breaking changes expected)
