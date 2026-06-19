---
phase: "02-desktop-file-import-pipeline"
plan: "02-00"
subsystem: "import"
tags:
  - desktop
  - file-import
  - pipeline
  - extraction
  - parsing
  - drag-and-drop
requires:
  - phase-01-foundation
provides:
  - question-bank-creation
affects:
  - routing
  - home-screen
  - data-layer
tech-stack:
  added:
    - archive:4.x (ZIP decode)
    - xml:6.x (WordprocessingML)
    - pdfrx:1.x (PDF extraction via PDFium)
    - file_picker:11.x (native file dialog)
    - desktop_drop:0.x (drag-and-drop)
    - uuid:4.x (UUID generation)
  patterns:
    - "@riverpod Notifier for pipeline state machine"
    - "feature-first directory structure"
    - "dart:io Platform checks for desktop branching"
key-files:
  created:
    - lib/features/import/providers/import_state.dart
    - lib/features/import/providers/import_notifier.dart
    - lib/features/import/presentation/import_screen.dart
    - lib/features/import/presentation/import_progress_screen.dart
    - lib/features/import/presentation/import_preview_screen.dart
    - lib/features/import/presentation/import_summary_screen.dart
    - lib/features/import/widgets/file_format_tile.dart
    - lib/features/import/widgets/candidate_card.dart
    - lib/features/import/extraction/text_extractor.dart
    - lib/features/import/extraction/docx_extractor.dart
    - lib/features/import/extraction/doc_extractor.dart
    - lib/features/import/extraction/pdf_extractor.dart
    - lib/features/import/parsing/heuristic_parser.dart
    - lib/features/import/parsing/parse_candidate.dart
    - test/features/import/pipeline_integration_test.dart
    - test/features/import/extraction/extraction_test.dart
    - test/features/import/parsing/heuristic_parser_test.dart
  modified:
    - lib/core/paths.dart
    - lib/features/home/presentation/home_screen.dart
    - lib/routing/router.dart
    - pubspec.yaml
    - windows/CMakeLists.txt
  deleted:
    - test/widget_test.dart
decisions:
  - "Use pdfrx instead of pdfx for PDF extraction (better platform support)"
  - "Use @riverpod Notifier pattern over StateNotifierProvider (Riverpod 3.x compatible)"
  - "Feature-first directory structure (lib/features/import/) instead of data/providers/ as planned"
  - "UUID generation via uuid package instead of custom _generateId"
  - "Store import state in feature directory rather than lib/data/ (follows existing project convention)"
metrics:
  tasks_total: 12
  tasks_completed: 12
  duration: "~30 minutes (this session)"
  completed_date: "2026-06-19T22:06:45+08:00"
---

# Phase 02 Plan 00: 桌面文件导入管道 Summary

**一句话：** 桌面端 `.docx`/`.doc`/`.pdf`/`.json` 文件导入管道——从文件选择、文本提取、启发式解析、候选审核到数据库持久化的完整生命周期，含 7 个新页面和拖放支持。

---

## 已完成任务

| # | 任务 | 提交 | 类型 | 关键文件 |
|---|------|------|------|----------|
| 1 | 添加依赖 | `f259c98` | chore | pubspec.yaml, windows/CMakeLists.txt |
| 2 | PathResolver 扩展 | `8726d9c` | feat | lib/core/paths.dart |
| 3 | 文本提取器 | `9974dfc` | feat | docx_extractor.dart, doc_extractor.dart, pdf_extractor.dart, text_extractor.dart |
| 4 | 启发式解析器 | `bf3c36f` | feat | heuristic_parser.dart, parse_candidate.dart |
| 5 | 导入状态管理 | `864d6f6` | feat | import_state.dart, import_notifier.dart |
| 6 | 导入屏幕重写 | `5af2369` | feat | import_screen.dart, file_format_tile.dart |
| 7 | 进度屏幕 | `3115732` | feat | import_progress_screen.dart |
| 8 | 预览编辑屏幕 | `0531145` | feat | import_preview_screen.dart, candidate_card.dart |
| 9 | 摘要屏幕 | `ae83b5d` | feat | import_summary_screen.dart |
| 10 | 首页 FAB 集成 | `5feee20` | feat | home_screen.dart |
| 11 | 路由更新 | `88bda2f` | feat | router.dart |
| 12 | 集成测试 | `3545285` | test | pipeline_integration_test.dart |

---

## 架构概览

### 导入管道状态机

```
idle → picking → extracting → parsing → editing → committing → done
  ↑       ↑                                                      |
  └───────┴──────────────── reset ───────────────────────────────┘
```

**ImportState** 管理全生命周期：文件列表 → 提取文本 → 候选题目 → 确认集 → 已提交计数。

**ImportNotifier**（`@riverpod`）通过单个可测试类协调管道：
- `pickFiles()` → 从文件名推导题库名称
- `extractAndParse()` → 分派到 text_extractor → heuristic_parser
- 编辑方法：`toggleCandidate()`, `setCandidateType()`, `setCandidateOptions()`, `setCandidateAnswer()`
- `commitToDatabase()` → 写入 ParseJob + QuestionBank + Question 到 SQLite

### 导航流

```
/ (HomeScreen + FAB)
  → /import (ImportScreen: 格式选择 + 拖放)
    → /import/progress (ImportProgressScreen: 提取 + 解析进度)
      → /import/preview/:jobId (ImportPreviewScreen: 候选审核编辑)
        → /import/summary/:jobId (ImportSummaryScreen: 成功摘要 + CTA)
          → /quiz/:bankId/random 或 /
```

### 页面清单（7 个页面）

1. **ImportScreen** — 桌面端：3 个格式图块（Word/PDF/JSON）+ 拖放；Android：仅 JSON（禁用）
2. **ImportProgressScreen** — 文件图标、文件名、进度条、取消（含确认弹窗）、错误重试、10s 卡住提示
3. **ImportPreviewScreen** — 候选列表、题型筛选芯片、全选/取消全选、逐题编辑（题型/选项/答案）、删除/恢复
4. **ImportSummaryScreen** — 成功图标、数量和名称、题型分布统计、"开始复习"+"返回首页"CTA
5. **HomeScreen（已更新）** — 桌面端 FAB（+）、启用"导入题库"和 3 个模式"开始"按钮

---

## 从计划的偏离

### 自动修复问题

**1. [Rule 2 - 缺失关键功能] 为 ImportState 添加 jobId 字段**
- **发现于：** 任务 7
- **问题：** ImportNotifier 生成 UUID 但未在 state 中跟踪，进度→预览导航需要 jobId 作为路径参数
- **修复：** 在 ImportState 中添加 `jobId` 字段并加入 `copyWith`；在 `pickFiles()` 中通过 uuid 包生成
- **修改文件：** import_state.dart, import_notifier.dart, import_progress_screen.dart
- **提交：** `3115732`

**2. [Rule 1 - Bug] _generateId 方法生成相同字符**
- **发现于：** 任务 5
- **问题：** 自定义 `_generateId()` 为所有字符使用 `DateTime.now().microsecondsSinceEpoch % 16`，在同一微秒内产生相同的十六进制字符
- **修复：** 替换为 `uuid` 包（`const Uuid()`），该包已在 pubspec.yaml 中声明
- **修改文件：** import_notifier.dart
- **提交：** `864d6f6`

**3. [Rule 2 - 缺失关键功能] JSON 序列化使用 list.toString()**
- **发现于：** 任务 5
- **问题：** `_optionsToJson` 和 `_answerToJson` 使用了 Dart 的 `list.toString()`，产生 `"[{key: A, text: ...}]"` 而非合法 JSON
- **修复：** 添加 `import 'dart:convert'` 并使用 `jsonEncode()`
- **修改文件：** import_notifier.dart
- **提交：** `864d6f6`

**4. [Rule 3 - 阻塞问题] PathResolver 以 FutureProvider 访问但未 await**
- **发现于：** 任务 5
- **问题：** `ref.read(pathResolverProvider)` 返回 `AsyncValue<PathResolver>`，需要 `.future`
- **修复：** 使用 `await ref.read(pathResolverProvider.future)` 并在闭包中预解析
- **修改文件：** import_notifier.dart
- **提交：** `864d6f6`

### 架构偏离（已记录，非修复）

- **目录结构：** Plan 指定 `lib/data/providers/` 和 `lib/data/models/`，代码实际放在 `lib/features/import/providers/` 和 `lib/features/import/parsing/`。遵循项目既有的功能优先约定（Phase 01 已建立）。
- **Provider 模式：** Plan 引用 `StateNotifierProvider`；实现采用 Riverpod 3.x 的 `@riverpod` codegen with `Notifier`。StateNotifier 在 Riverpod 3.x 中已弃用。
- **PDF 库：** Plan 指定 `pdfx`；实现使用 `pdfrx`（更好的平台支持，更活跃的维护）。

---

## 已知 Stubs

| 文件 | 行 | 原因 |
|------|-----|------|
| `import_screen.dart:148` | Android .json tile 的 `onTap: () {}` | Phase 5 启用 Android 文件导入 |
| `import_screen.dart:97` | `onDragEntered` 和 `onDragExited` 为 no-op | DropTarget builder 提供视觉反馈；handler 留空但准备就绪 |

---

## 威胁标记

| 标记 | 文件 | 描述 |
|------|------|------|
| `threat_flag: file-access` | import_screen.dart | `File.statSync()` 以同步调用访问本地文件系统；大文件或远程挂载可能阻塞 UI 线程 |
| `threat_flag: process-exec` | doc_extractor.dart | `Process.run(runInShell: true)` 以 shell 模式执行 pandoc；文件路径未经过滤即传递给命令行参数 |

> **注：** 威胁标记不阻塞此计划——在此阶段它们属于可接受风险，于 Phase 03（安全加固）处理。

---

## 自我检查

✅ 通过——全部 9 个关键文件存在，全部 12 个提交已验证。

```
FOUND: lib/features/import/providers/import_state.dart
FOUND: lib/features/import/providers/import_notifier.dart
FOUND: lib/features/import/presentation/import_screen.dart
FOUND: lib/features/import/presentation/import_progress_screen.dart
FOUND: lib/features/import/presentation/import_preview_screen.dart
FOUND: lib/features/import/presentation/import_summary_screen.dart
FOUND: lib/features/import/widgets/file_format_tile.dart
FOUND: lib/features/import/widgets/candidate_card.dart
FOUND: test/features/import/pipeline_integration_test.dart

FOUND: f259c98 | FOUND: 8726d9c | FOUND: 9974dfc | FOUND: bf3c36f
FOUND: 864d6f6 | FOUND: 5af2369 | FOUND: 3115732 | FOUND: 0531145
FOUND: ae83b5d | FOUND: 5feee20 | FOUND: 88bda2f | FOUND: 3545285
```
