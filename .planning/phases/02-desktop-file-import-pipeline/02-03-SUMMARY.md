---
phase: "02-desktop-file-import-pipeline"
plan: "02-03"
subsystem: "import"
tags:
  - cjk-validation
  - skipped-items
  - route-guards
  - bank-name-editing
requires:
  - "02-01 (code generation)"
provides:
  - cjk-bank-name
  - skipped-candidates-ui
  - route-redirect-guards
affects:
  - import-notifier
  - import-state
  - import-preview-screen
  - import-summary-screen
  - router
tech-stack:
  patterns:
    - "CJK-aware character counting (Unicode ranges U+4E00–U+9FFF etc.)"
    - "GoRouter redirect with ProviderScope.containerOf"
    - "Riverpod State Notifier pattern"
    - "Dart record types for skipped items"
key-files:
  modified:
    - lib/features/import/providers/import_state.dart
    - lib/features/import/providers/import_notifier.dart
    - lib/features/import/presentation/import_preview_screen.dart
    - lib/features/import/presentation/import_summary_screen.dart
    - lib/routing/router.dart
decisions:
  - "CJK 感知字符计数使用 Unicode 范围判断，覆盖 U+4E00–U+9FFF (CJK Uni), U+3400–U+4DBF (CJK ExtA), U+F900–U+FAFF (Compat), U+FF01–U+FF5E (全角), U+3000–U+303F (中文标点)"
  - "跳过原因推导规则：confidence<0.3→置信度过低, unknown→题型未识别, 空题干选项→题干和选项均缺失, options<2→选项不足, answer空→答案未识别, 其他→用户跳过"
  - "GoRouter redirect 作为第一层守卫，ImportPreviewScreen.initState / ImportSummaryScreen.initState 作为第二层防御"
  - "移除未使用 imports (dart:io, import_state.dart) 和未使用变量 (hasModifications)"
metrics:
  tasks_total: 3
  tasks_completed: 3
  duration: "~5 minutes"
  completed_date: "2026-06-19T23:00:00+08:00"
---

# Phase 02 Plan 03: CJK 题库名称 + 跳过项列表 + 路由守卫 Summary

**一句话：** 补全导入预览/摘要页缺失功能——CJK 感知题库名称编辑（D-18）、跳过题目列表含重试/编辑按钮（D-09）、过期 jobId 路由守卫。

---

## 已完成任务

| # | 任务 | 提交 | 类型 | 关键文件 |
|---|------|------|------|----------|
| 1 | ImportState skippedCandidates + ImportNotifier setBankName/retryParseCandidate | `0e68cb5` | feat | import_state.dart, import_notifier.dart |
| 2 | ImportPreviewScreen CJK 题库名称编辑 + jobId 守卫 | `0e68cb5` | feat | import_preview_screen.dart |
| 3 | ImportSummaryScreen 跳过列表 + GoRouter redirect | `0e68cb5` | feat | import_summary_screen.dart, router.dart |

---

## 详细说明

### Task 1: ImportState + ImportNotifier 新增方法

**ImportState 新增：**
- `skippedCandidates` getter — 返回 `List<({int index, ParseCandidate candidate, String reason})>`，仅含未被确认的候选
- `_deriveSkipReason(ParseCandidate)` — 6 条推导规则

**ImportNotifier 新增：**
- `setBankName(String name)` — 将题库名称写入 state
- `retryParseCandidate(int index)` — 对 `candidates[index].rawText` 重新调用 `_parser.parse()`，保留原始行号，无论结果均加入 confirmedIndices

### Task 2: ImportPreviewScreen D-18 实现

1. **题库名称 TextField** — 位于 toolbar 上方，从 `state.bankName` 预填充
2. **CJK 感知验证** — `_cjkAwareLength()` 覆盖 5 个 Unicode 范围；上限 20；空名阻止提交
3. **jobId 守卫** — `initState` 中检查 `!isEditing && !isCommitting` → 重定向 `/`
4. **_onSave 增强** — 提交前验证名称，无效时中止
5. **修复 filteredCandidates 类型推断** — 统一使用 `MapEntry` 列表，消除 Object.key/value 编译错误

### Task 3: ImportSummaryScreen D-09 + Router Guards

**跳过题目列表：**
- 橙色警告卡片（`Colors.orange.shade50`）
- 每条显示：`#{序号}: {原因}` + 题干预览（1行截断）
- "重试"按钮 → `retryParseCandidate(index)` + `setState`
- "手动编辑"按钮 → 导航 `/import/preview/${jobId}`

**GoRouter redirect 守卫：**
- `/import/preview/:jobId` → 不在 editing/committing → 重定向 `/`
- `/import/summary/:jobId` → 不在 done 且 committedCount==0 → 重定向 `/`

---

## 验证结果

### 通过
- [x] `ImportState` 含有 `skippedCandidates` getter
- [x] `ImportNotifier` 含有 `setBankName(String name)` 方法
- [x] `ImportNotifier` 含有 `retryParseCandidate(int index)` 方法
- [x] `ImportPreviewScreen` 顶部含题库名称 TextField（label: '题库名称'）
- [x] `_cjkAwareLength()` 覆盖 CJK Unicode 范围
- [x] CJK 上限 20 验证有效
- [x] 空名称阻止提交
- [x] jobId 有效性守卫在 initState 中
- [x] `ImportSummaryScreen` 含跳过题目区域（`_buildSkippedSection`）
- [x] 重试/手动编辑按钮功能完备
- [x] `/import/preview/:jobId` 含 redirect 守卫
- [x] `/import/summary/:jobId` 含 redirect 守卫
- [x] `flutter analyze` 全部修改文件 **零错误、零警告**

### 仅 info（非阻塞）
- 16× info：withOpacity 弃用、BuildContext 异步 lint、prefer_const_constructors
