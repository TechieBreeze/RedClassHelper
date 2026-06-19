# Phase 2: Desktop File Import Pipeline - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-19
**Phase:** 02-desktop-file-import-pipeline
**Areas discussed:** 文件选取入口, .doc 格式范围扩展

---

## 文件选取入口

| Option | Description | Selected |
|--------|-------------|----------|
| HomeScreen FAB | 右下角悬浮按钮，点击弹出导入选项 | ✓ |
| HomeScreen AppBar 按钮 | 顶部栏右侧图标按钮 | |
| 导入页内按钮 | 导航到 /import 页面后再选 | |
| FAB + 拖放 | FAB 入口 + 桌面端拖放文件到窗口 | ✓（合并选择） |

**User's choice:** HomeScreen FAB + 桌面端拖放支持

---

### FAB 交互方式

| Option | Description | Selected |
|--------|-------------|----------|
| 直接打开文件对话框 | 一键选文件，无需中间步骤 | ✓ |
| 弹出底部菜单 | BottomSheet 先选格式再开对话框 | |
| SpeedDial 展开 | 展开小按钮组，每个对应一种格式 | |

**User's choice:** 直接打开文件对话框（一步到位）

---

### 文件类型过滤

| Option | Description | Selected |
|--------|-------------|----------|
| 智能过滤 | "支持的题库文件"组，含 .doc/.docx/.pdf/.json | ✓ |
| 三组独立过滤 | 默认全部 + 三个独立筛选选项 | |
| 仅 .docx + .pdf | 桌面端不显 .json | |

**User's choice:** 智能过滤

---

### 拖放支持

| Option | Description | Selected |
|--------|-------------|----------|
| 支持拖放 | 桌面端窗口接受拖放，与 FAB 并行 | ✓ |
| 仅 FAB 入口 | v1 不做拖放 | |

**User's choice:** 支持拖放

---

### Android 端 FAB

| Option | Description | Selected |
|--------|-------------|----------|
| FAB 存在但只弹 .json 对话框 | 两端操作一致，文件过滤不同 | ✓ |
| Android 不显示 FAB | 初期 /import 是空白占位 | |

**User's choice:** FAB 存在但只弹 .json 对话框

---

## .doc 格式范围扩展

| Option | Description | Selected |
|--------|-------------|----------|
| 纳入 Phase 2 | .doc + .docx + .pdf 全覆盖 | ✓ |
| 手动转换 .doc→.docx | 用户预先用 Word/WPS 转换 | |
| 仅 PDF + .docx | 保持 ROADMAP 原计划 | |

**User's choice:** 纳入 Phase 2

**Notes:** 用户在 `doc/example/` 提供了 4 份真实题库文件（2 份 .doc、1 份 .docx、1 份 .pdf）。.doc 是 Word 97-2003 OLE2 二进制格式，与 .docx (Office Open XML) 完全不同。researcher 需调研纯 Dart 或命令行 fallback 方案。

---

## Claude's Discretion

- FAB 图标选择
- 拖放视觉反馈样式
- 文件对话框自定义文本
- 预览编辑模型、解析进度 UX、解析失败处理——planner 自行决定

## Deferred Ideas

- Android .json 导入 → Phase 5
- JSON 导出 → Phase 5
- LLM 解析 → Phase 3
