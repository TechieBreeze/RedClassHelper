---
status: partial
phase: 03-desktop-llm-integration-parse-quality
source: [03-VERIFICATION.md]
started: 2026-06-20
updated: 2026-06-20
---

## Current Test

[awaiting human testing]

## Tests

### 1. LLM parsing end-to-end with real llama.cpp server + Qwen2.5 model
expected: 1. Start llama-server with Qwen2.5-1.5B GGUF 2. Import doc/example/ PDF 3. Verify parse results correct 4. Verify source badges on summary screen
result: [pending]

### 2. Model download with HTTP Range resume
expected: 1. Start model download 2. Kill app mid-download 3. Restart app and verify resume from checkpoint
result: [pending]

### 3. Model management page visual appearance
expected: 3 sections (已安装模型/推荐模型/自定义模型), tier badges (推荐/快速/实验), download states (下载/下载中/已安装/等待中), all matches UI-SPEC
result: [pending]

### 4. Parse source badges on preview and summary screens
expected: LLM (teal chip), 启发式 (secondary chip), 兜底 (amber chip) render correctly; auto-confirmed banner visible; source summary line above submit; 解析来源 section on summary
result: [pending]

### 5. Parser choice dialog UX
expected: 2 option cards (快速解析/高精度解析), LLM disabled when no models with red "需要先下载模型", 150ms AnimatedContainer transition, "取消" dismisses, heuristic on Android
result: [pending]

### 6. build_runner regeneration + full flutter test suite
expected: `dart run build_runner build --delete-conflicting-outputs` succeeds; `flutter test` all tests pass; `dart analyze` clean
result: [pending]

## Summary

total: 6
passed: 0
issues: 0
pending: 6
skipped: 0
blocked: 0

## Gaps
