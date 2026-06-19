---
phase: "02-desktop-file-import-pipeline"
plan: "02-02"
subsystem: "import"
tags:
  - navigation
  - drag-and-drop
  - visual-feedback
requires:
  - "02-01 (code generation)"
provides:
  - drag-drop-overlay
  - navigation-stack-fix
affects:
  - import-screen
  - import-progress-screen
tech-stack:
  patterns:
    - "StatefulWidget for drag state tracking"
    - "AnimatedContainer overlay on DropTarget"
    - "GoRouter push/pop for navigation stack preservation"
key-files:
  modified:
    - lib/features/import/presentation/import_screen.dart
    - lib/features/import/presentation/import_progress_screen.dart
decisions:
  - "Converted ImportScreen from StatelessWidget to StatefulWidget — needed for _isDragOver state"
  - "FilePicker.platform.pickFiles() → FilePicker.pickFiles() — file_picker 11.x removed the .platform getter"
  - "Error-state '返回首页' button keeps context.go('/') — semantically correct, user wants to fully exit"
metrics:
  tasks_total: 2
  tasks_completed: 2
  duration: "~3 minutes"
  completed_date: "2026-06-19T22:55:00+08:00"
---

# Phase 02 Plan 02: 导航栈修复 + 拖放视觉反馈 Summary

**一句话：** 修复导入流程中两个 UI 行为缺陷——取消导航使用 push/pop 保留路由栈、桌面端拖放悬停显示视觉反馈覆盖层。

---

## 已完成任务

| # | 任务 | 提交 | 类型 | 关键文件 |
|---|------|------|------|----------|
| 1 | 导航栈管理修复 (context.go → context.push) | `af813c3` | fix | import_screen.dart, import_progress_screen.dart |
| 2 | 拖放视觉反馈覆盖层 (D-03) | `af813c3` | feat | import_screen.dart |

---

## 详细说明

### Task 1: 导航栈管理修复

**问题：** 
- `ImportScreen._navigateToProgress` 使用 `context.go('/import/progress')` 替换整个路由栈，用户取消后无法返回格式选择页
- `ImportProgressScreen._onWillPop` 取消后使用 `context.go('/')` 直接回首页

**修改：**
1. `import_screen.dart:275` — `context.go('/import/progress', ...)` → `context.push('/import/progress', ...)`
2. `import_progress_screen.dart:99` — `context.go('/')` → `context.pop()`（用户主动取消时返回 /import）
3. 错误状态"返回首页"按钮保留 `context.go('/')`——语义合理
4. 进度完成自动跳转 `context.go('/import/preview/...')` 保留不变

### Task 2: 拖放视觉反馈覆盖层

**问题：** D-03 — `onDragEntered`/`onDragExited` 为空操作，拖放悬停无任何视觉反馈

**实现：**
1. `ImportScreen` StatelessWidget → StatefulWidget（需要 `_isDragOver` 状态）
2. `onDragEntered` → `setState(() => _isDragOver = true)`
3. `onDragExited` → `setState(() => _isDragOver = false)`
4. `onDragDone` → `setState(() => _isDragOver = false)`
5. DropTarget child 包裹在 Stack 中，条件渲染覆盖层：
   - `AnimatedContainer`（200ms 过渡动画）
   - 半透明 primaryContainer 背景 + 主色调实线边框 + 12px 圆角
   - 居中显示云上传图标 + "释放以导入" 文字 + 支持格式列表

### 额外修复: FilePicker API 变更

`file_picker` 11.x 移除了 `FilePicker.platform` getter。将 3 处 `FilePicker.platform.pickFiles()` 改为 `FilePicker.pickFiles()`。

---

## 验证结果

### 通过
- [x] `import_screen.dart` 使用 `context.push('/import/progress', ...)`（非 `context.go`）
- [x] `import_progress_screen.dart` 取消路径使用 `context.pop()`
- [x] grep: `context.go('/import/progress')` 在 import_screen.dart 中不存在
- [x] `import_screen.dart` 从 StatelessWidget 改为 StatefulWidget
- [x] `onDragEntered` 回调设置 `_isDragOver = true`
- [x] 存在 `_isDragOver` 条件渲染覆盖层，含 "释放以导入" 文字
- [x] 覆盖层使用 AnimatedContainer + 半透明背景 + 主色调边框
- [x] Android 端无拖放覆盖层（`_buildAndroidLayout` 不包含 DropTarget）
- [x] `flutter analyze` import_screen.dart + import_progress_screen.dart — **零错误、零警告**

### 仅 info 级别（非阻塞）
- 4× `withOpacity` 弃用 → 后续用 `.withValues()` 替代
- 3× `use_build_context_synchronously` → 已通过 `mounted` 守卫，lint 误报
