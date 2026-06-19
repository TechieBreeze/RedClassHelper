# Phase 3: Desktop LLM Integration & Parse Quality - Context

**Gathered:** 2026-06-19
**Status:** Ready for planning

<domain>
## Phase Boundary

用可替换的 `LlmClient` 抽象替换现有的启发式正则解析器。仅桌面端（Windows/Linux）启用 LLM 解析；Android 端 provider stub 抛出 `UnsupportedError`。先交付 Stub + HTTP 两个实现；FFI 绑定作为研究 spike 评估。

**本阶段不实现**：答题循环（Phase 4）、JSON 导入/导出（Phase 5）、诊断包导出（Phase 6）。本阶段只产出"LlmClient 抽象 + Stub + HTTP + GBNF grammar + 模型管理页 + 解析管道 LLM 分支"。

</domain>

<decisions>
## Implementation Decisions

### 解析引擎策略：LLM 与启发式并存
- **D-01:** 每次导入时用户选择解析引擎——文件选择后弹出对话框："快速解析（启发式）" / "高精度解析（LLM）"。不记忆选择——每次导入重新问。
- **D-02:** 两种解析引擎共用解析结果预览页（ImportPreviewScreen）。推荐在候选题目上标注解析来源便于用户理解。

### 模型管理 UX
- **D-03:** 独立的模型管理页——入口在设置（Settings）中。页面功能：查看已安装模型列表、下载预设推荐模型、添加自定义模型（本地 .gguf 或 URL）。
- **D-04:** 预设模型分三级——推荐（Qwen2.5-1.5B Q4_K_M，默认，平衡质量与速度）、快速（Qwen2.5-0.5B Q4_K_M，极速但精度略低）、实验（Qwen2.5-3B Q4_K_M，最高质量需 4GB+ 内存）。模型管理页展示三级模型目录，每个模型标注名称、大小、内存需求、推荐理由。**用户按需逐个下载，不自动下载、不一次全下。**
- **D-05:** 单个模型应用内 HTTP 下载，显示进度条和速度。支持断点续传（HTTP Range 请求）——中断后可从上次位置继续。下载完成后 Sha256 校验完整性。模型文件存入 PathResolver.modelsDir。
- **D-06:** 用户可自由添加模型——粘贴 HuggingFace/ModelScope URL 下载，或通过文件选择器导入本地 .gguf 文件。应用只做格式校验（.gguf 后缀 + magic number）。

### 解析管道集成
- **D-07:** 扩展现有 ImportNotifier 管道——在 `ImportPhase` 枚举中增加 `llmParsing` 子状态。流程：`idle → picking → extracting → [用户选 LLM → llmParsing | 用户选启发式 → parsing] → editing → committing → done`。
- **D-08:** LLM 解析结果自动确认（全部候选题目标记为已确认，跳过逐题审核步骤）。启发式解析结果保持现有行为（需手动审核确认）。
- **D-09:** 单题 LLM 解析失败处理：3 次重试 → 仍失败则启发式兜底重解析该题 → 汇总页展示最终结果并标注每题的解析来源（LLM / 启发式 / 兜底）。失败的原始信息写入 `parse_log` 表。

### Claude's Discretion
- `LlmClient` 抽象接口的具体签名（parse 方法、返回类型、错误类型）
- GBNF grammar 文件的详细格式和 schema 校验逻辑
- 分块策略的具体实现（如何按题号切分原始文本送入 LLM）
- 模型下载的具体实现（下载目录、并发分片数、Sha256 校验）
- FFI spike 的 go/no-go 标准和评估报告格式
- 模型管理页的具体 UI 布局和交互动效
- 导入模式选择对话框的 UI 设计

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### 项目级上下文
- `.planning/PROJECT.md` — Core value, constraints, key decisions；双层工作流（桌面 LLM + 移动 JSON）
- `.planning/REQUIREMENTS.md` — Phase 3 拥有 IMP-03 (LLM 解析)、IMP-04 (进度+失败+重试)；IMP-06 (JSON 导出) 属于 Phase 5
- `.planning/ROADMAP.md` §"Phase 3: Desktop LLM Integration & Parse Quality" — 阶段目标、成功标准、8 个计划列表

### 前序阶段产物
- `.planning/phases/01-foundation-persistence/01-CONTEXT.md` — DB schema (ParseJob/ParseLog/Questions 表已存在)、PathResolver (modelsDir/cacheDir/tempDir)、项目分层结构
- `.planning/phases/02-desktop-file-import-pipeline/02-CONTEXT.md` — 导入管道架构 (ImportState/ImportNotifier/ImportPhase)、启发式解析器设计、平台分支模式

### 现有代码
- `lib/features/import/parsing/heuristic_parser.dart` — 当前启发式解析器实现，LLM 需要与之互操作的参考
- `lib/features/import/providers/import_state.dart` — ImportState 和 ImportPhase 枚举，需要扩展
- `lib/features/import/providers/import_notifier.dart` — 导入管道 Notifier，LLM 分支的集成点
- `lib/core/paths.dart` — PathResolver，modelsDir 已预留 .gguf 模型目录
- `lib/data/db/tables/parse_jobs.dart` — ParseJobs 表定义
- `lib/data/db/tables/parse_logs.dart` — ParseLogs 表定义
- `lib/data/db/tables/questions.dart` — Questions 表，raw_text 字段可用于 LLM 重放

### 研究参考
- `.planning/research/PITFALLS.md` §PITFALL 1 (LLM JSON 格式漂移 — GBNF + canonicalization + 多层解析) + §PITFALL 4 (Android OOM — 能力探测 + lazy model load) + §Trap (全文一次送入会被截断 — 按题号分块)

### 外部（待调研）
- llama.cpp GBNF grammar 规范（planner 需调研官方文档和社区示例）
- HuggingFace/ModelScope GGUF 模型分发 API（模型下载 URL 格式和元数据）
- `pub.dev` 上可用的 Dart HTTP 下载 + Range 请求支持库

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **HeuristicParser** (`lib/features/import/parsing/heuristic_parser.dart`)：作为 LLM 失败时的兜底解析器，以及对标参考——LLM 解析结果的格式应对齐 ParseCandidate
- **ImportState / ImportNotifier** (`lib/features/import/providers/`)：管道状态机已定义 7 个阶段，LLM 只需扩展 1 个 `llmParsing` 子状态
- **PathResolver.modelsDir** (`lib/core/paths.dart`)：模型文件目录已预留，LLM 下载和管理直接使用
- **ParseJobs / ParseLogs 表**：解析任务和日志表已存在，LLM 解析产出的 job 和 log 写入同一套表
- **ParseCandidate 模型** (`lib/features/import/parsing/parse_candidate.dart`)：LLM 解析产出的结构化数据应对齐此模型，确保预览和入库管道一致

### Established Patterns
- Riverpod `@riverpod` 代码生成——`LlmClient` 及其实现的 provider 遵循此模式
- 按特性分层——LLM 相关代码放在 `lib/data/llm_client/`（接口+实现）和 `lib/features/import/`（管道集成）
- 平台分支：`Platform.isWindows || Platform.isLinux` 用于桌面端 LLM 能力守护
- Material 3 主题系统——模型管理页和导入对话框使用 `Theme.of(context)`

### Integration Points
- ImportNotifier 的 `extractAndParse()` 方法是主集成点——根据用户选择分支调用 `HeuristicParser` 或 `LlmClient`
- 设置页路由需要新增 `/settings/models` 或类似路由，并在 Settings 页面添加入口
- 模型下载通过 PathResolver 写入 `modelsDir`，下载进度通过 Riverpod provider 暴露给 UI
</code_context>

<specifics>
## Specific Ideas

- 用户特别关心解析结果的可追溯性——汇总页必须清晰标注每道题的解析来源（LLM / 启发式 / 兜底），方便用户判断解析质量
- 模型管理页是独立页面而非弹窗——用户预期在设置中有一个完整的模型管理中心
- 断点续传对 1-3GB 的 GGUF 文件至关重要——网络不稳定的大陆用户场景

</specifics>

<deferred>
## Deferred Ideas

- **macOS/iOS LLM 支持**：v1 不涉及——macOS/iOS 打包不在范围，但 `LlmClient` 接口设计应为未来平台扩展留空间
- **FFI 绑定作为默认实现**：取决于 spike 结果——如果 spike 成功，会新增 03-08 计划；如果失败，HTTP-only 作为生产路径
- **模型自动更新检查**：不在 Phase 3 范围——v1 用户手动管理模型版本

</deferred>

---

*Phase: 03-desktop-llm-integration-parse-quality*
*Context gathered: 2026-06-19*
