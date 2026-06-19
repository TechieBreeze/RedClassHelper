# Phase 3: Desktop LLM Integration & Parse Quality - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-19
**Phase:** 03-desktop-llm-integration-parse-quality
**Areas discussed:** 解析引擎策略, 模型管理 UX, 解析管道集成

---

## 解析引擎策略：LLM 与启发式并存

| Option | Description | Selected |
|--------|-------------|----------|
| 完全替换 — LLM 是唯一解析器 | 桌面端导入一律走 LLM。无模型或失败时报错，不自动回退 | |
| LLM 优先 + 启发式兜底 | LLM 失败时自动回退到启发式解析器，用户无感知 | |
| 用户可选两种方案并存 | 导入时让用户选择"快速解析（启发式）"或"高精度解析（LLM）" | ✓ |

**User's choice:** 用户可选两种方案并存
**Notes:** 每次导入时弹出对话框让用户选择，不记忆选择——每次重新问

---

## 模型管理 UX

### 模型入口
| Option | Description | Selected |
|--------|-------------|----------|
| 独立模型管理页（设置内） | 设置页有"模型管理"入口，查看已安装、下载推荐模型 | ✓ |
| 导入流程内嵌 | 选择 LLM 解析时在流程内嵌下载步骤 | |
| 两者都有 | 设置管理 + 导入内嵌下载 | |

### 模型分层
| Option | Description | Selected |
|--------|-------------|----------|
| 按模型大小分层 | 推荐(1.5B)/快速(0.5B)/实验(3B) 预设列表 | ✓ |
| 用户自由添加模型 | 不预设，用户自行管理 .gguf | ✓ |
| 远程模型目录 | 从 HuggingFace 拉取列表 | |

### 下载体验
| Option | Description | Selected |
|--------|-------------|----------|
| 应用内下载 + 断点续传 | HTTP Range 请求，显示进度和速度 | ✓ |
| 浏览器外链下载 | 引导用户到浏览器下载 | |
| 简单下载 | 无断点续传 | |

**User's choice:** 独立模型管理页 + 预设列表（用户也可添加）+ 应用内下载断点续传
**Notes:** 预设三级推荐模型，用户可粘贴 URL 或选择本地 .gguf 添加自定义模型

---

## 解析管道集成

### 管道集成方式
| Option | Description | Selected |
|--------|-------------|----------|
| 扩展现有管道 — 加 LLM 子阶段 | ImportPhase 增加 llmParsing，共用管道 | ✓ |
| 双轨并行 | 启发式先行 + LLM 后台优化 | |
| 独立 LLM 管道 | 完全独立的管道和 UI | |

### 预览界面
| Option | Description | Selected |
|--------|-------------|----------|
| 自动确认 — 跳过审核 | LLM 结果全确认，直接入库 | ✓ |
| 仍需审核 — 标注来源 | 仍需逐题审核但标注 LLM 来源 | |
| 对照视图 | 原文与解析结构对照 | |

### 单题失败处理
| Option | Description | Selected |
|--------|-------------|----------|
| 跳过 + 汇总展示 | 静默跳过，汇总页列出 | |
| LLM 失败 → 启发式兜底 | 自动回退到启发式 | |
| 暂停 + 用户决策 | 暂停整个导入让用户选择 | |
| 3次重试→启发式兜底→标识来源 | 用户自定义方案 | ✓ |

**User's choice:** 扩展现有管道 + LLM 结果自动确认 + 3次重试后启发式兜底
**Notes:** 汇总页标注每道题的解析来源（LLM/启发式/兜底），用户可追溯解析质量

---

## Claude's Discretion

- `LlmClient` 抽象接口签名（用户未讨论此区域）
- GBNF grammar 文件格式和 schema 校验
- 分块策略实现细节
- 模型下载的具体实现
- FFI spike 的 go/no-go 标准
- 模型管理页 UI 设计
- 导入模式选择对话框 UI 设计

## Deferred Ideas

- macOS/iOS LLM 支持 — v1 不涉及
- FFI 绑定作为默认实现 — 取决于 spike 结果
- 模型自动更新检查 — Phase 6 或未来
