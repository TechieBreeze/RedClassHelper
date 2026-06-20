---
phase: "02-desktop-file-import-pipeline"
plan: "02-01"
subsystem: "import"
tags:
  - code-generation
  - build-runner
  - blocking-fix
requires:
  - phase-02-plan-00
provides:
  - import-notifier-codegen
affects:
  - import-provider
tech-stack:
  patterns:
    - "Riverpod 4.x @riverpod code generation"
    - "Provider alias for backward compatibility"
key-files:
  created:
    - lib/features/import/providers/import_notifier.g.dart
  modified:
    - lib/features/import/providers/import_notifier.dart
decisions:
  - "Added `importNotifierProvider` alias → `importProvider` — Riverpod 4.x strips `Notifier` suffix from generated provider names, but all screen code references the old naming convention"
  - "Used inline `// ignore: non_constant_identifier_names` instead of file-level — the .g.dart file's ignore_for_file only scopes to itself"
metrics:
  tasks_total: 1
  tasks_completed: 1
  duration: "~3 minutes"
  completed_date: "2026-06-19T22:50:00+08:00"
r2_verification:
  date: "2026-06-19T23:15:00+08:00"
  flutter_analyze: "16 info — 零错误、零警告"
  flutter_test: "66/66 passed (1 skip: PDFium)"
  status: "VERIFIED"
---

# Phase 02 Plan 01: build_runner 代码生成修复 Summary

**一句话：** 运行 `dart run build_runner build` 生成缺失的 `import_notifier.g.dart`，并添加 Riverpod 4.x 命名兼容别名，解除编译阻断。

---

## 已完成任务

| # | 任务 | 提交 | 类型 | 关键文件 |
|---|------|------|------|----------|
| 1 | 运行 build_runner 生成缺失的 .g.dart 文件 | `d7516d3` | fix | import_notifier.g.dart, import_notifier.dart |

---

## 详细说明

### Task 1: 运行 build_runner 生成缺失的代码文件

**问题：** VERIFICATION.md Gap #1 — `import_notifier.g.dart` 缺失导致 `part 'import_notifier.g.dart'` 引用失败，项目完全无法编译。

**执行：**
1. 在 `/d/flutter/bin/cache/dart-sdk/bin/dart.exe` 找到 Flutter SDK（Phase 01 安装后移至 D 盘）
2. 运行 `dart run build_runner build --delete-conflicting-outputs`——46 秒，写入 32 个输出
3. 发现 Riverpod 4.x 命名约定变更：生成的 provider 名为 `importProvider`（移除 `Notifier` 后缀），但所有屏幕代码引用 `importNotifierProvider`
4. 在 `import_notifier.dart` 中添加向后兼容别名：`final importNotifierProvider = importProvider;`
5. 重新运行 build_runner（8 秒）——确认别名生效

**结果：**
- ✅ `import_notifier.g.dart` 已生成（75 行），包含 `ImportNotifierProvider` 类
- ✅ `parse_candidate.g.dart` 已存在（51 行，build_runner 重新生成）
- ✅ `importNotifierProvider` 可在所有屏幕中解析

---

## 验证结果

### 通过
- [x] `import_notifier.g.dart` 文件存在且非空（75 行 > 5）
- [x] `parse_candidate.g.dart` 文件存在且非空（51 行 > 5）
- [x] 包含 `ImportNotifierProvider` 类生成代码
- [x] `flutter analyze` 不再因 `.g.dart` 缺失而阻断

### 剩余问题（非本计划作用域）

`flutter analyze lib/features/import/` 仍有 22 个问题，但都属于后续 gap closure 计划的作用域：

| 问题 | 文件 | 属于 |
|------|------|------|
| `FilePicker.platform` getter 未定义 (3 errors) | import_screen.dart | 02-02 |
| `MapEntry.key`/`.value` 类型推断为 Object (2 errors) | import_preview_screen.dart | 02-03 |
| 未使用的 import dart:io (1 warning) | import_notifier.dart | 02-03 |
| 未使用的 import import_state.dart (1 warning) | import_preview_screen.dart | 02-03 |
| 未使用的局部变量 hasModifications (1 warning) | import_preview_screen.dart | 02-03 |
| withOpacity 弃用 (7 infos) | 多个文件 | 02-02/03 |
| use_build_context_synchronously (3 infos) | import_screen.dart | 02-02 |

这些问题在 build_runner 运行前就存在，但被 `.g.dart` 缺失导致的级联分析失败所掩盖。现在编译阻断已解除，后续计划可在此基础上进行修复。

---

## 偏差

1. **Flutter SDK 路径变更** — PATH 中的 `C:\Users\Lenovo\flutter\bin` 无效；SDK 实际在 `/d/flutter/`。系统 PATH 变量需更新。
2. **Riverpod 4.x 命名约定** — 生成器默认剥离 `Notifier` 后缀，与计划假定的 `importNotifierProvider` 命名不一致。通过兼容别名解决，无需大规模重命名。

---

## 自检

### 01-01 must_haves

- [x] `flutter analyze` 不再因缺失 .g.dart 而阻断编译
- [x] `import_notifier.g.dart` 已生成且文件系统存在

### 02-01 must_haves
- [x] `import_notifier.g.dart` 存在（75 行）
- [x] `parse_candidate.g.dart` 存在（51 行）
- [x] `importNotifierProvider` 可通过别名解析
- [x] 项目已准备好供 02-02 和 02-03 修复
