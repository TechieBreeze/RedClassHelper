# Phase 2: Desktop File Import Pipeline - Context

**Gathered:** 2026-06-19
**Status:** Ready for planning

<domain>
## Phase Boundary

桌面端用户选取 `.doc` / `.docx` / `.pdf` 文件 → 提取纯文本 → 启发式正则解析为结构化题目 → 预览编辑界面确认 → 写入数据库。Android 端 `/import` 页面存在但 `.doc`/`.docx`/`.pdf` 入口隐藏（仅 `.json` 入口在 Phase 5 激活）。

**本阶段不实现**：LLM 解析（Phase 3）、答题循环（Phase 4）、JSON 导入/导出（Phase 5）、诊断日志（Phase 6）。本阶段只产出"文件选取 → 文本提取 → 正则解析 → 预览确认 → 入库"的端到端管道。

> **范围变更**：原始 ROADMAP.md 只覆盖 `.docx` + `.pdf`。用户提供了真实 `.doc` 格式题库文件（`doc/example/`），因此 Phase 2 范围扩展至同时支持 `.doc`（Word 97-2003 二进制格式）。

</domain>

<decisions>
## Implementation Decisions

### 文件选取入口
- **D-01:** HomeScreen 右下角 FAB 作为主入口。点击直接弹出系统文件选择器，一步到位（不经过中间菜单）。
- **D-02:** 文件对话框使用智能过滤——显示"支持的题库文件"组，包含 `.doc` / `.docx` / `.pdf` / `.json` 四种格式。用户无需手动切换类型筛选。
- **D-03:** 桌面端（Windows/Linux）同时支持拖放导入——用户将文件拖到应用窗口任意位置即触发导入流程。与 FAB 入口并行。
- **D-04:** Android 端 FAB 仍然存在，但文件对话框仅显示 `.json` 过滤（Phase 5 实现 JSON 导入）。保持两端操作一致性（都是 FAB → 选文件），差异仅在文件类型过滤。

### 文件格式覆盖
- **D-05:** Phase 2 覆盖三种源文件格式：`.doc`（Word 97-2003 OLE2 二进制）、`.docx`（Office Open XML）、`.pdf`（文本层 PDF）。图片型/扫描型 PDF 不在此范围——明确报错提示。
- **D-06:** `.doc` 格式的处理策略由 researcher 调研后由 planner 决定——可能路径包括：命令行工具转换（pandoc / LibreOffice headless）、NPOI 封装、或纯 Dart 实现（如果 pub.dev 有可用库）。

### Claude's Discretion
- FAB 图标选择（Material Icons 中选 `file_open` 或类似图标）
- 拖放的视觉反馈样式（高亮边框、覆盖层提示等）
- 文件对话框的自定义文本标签
- 未讨论的灰色地带（预览编辑模型、解析进度 UX、解析失败处理）由 planner/researcher 自行决定——这些是实现细节，不影响阶段边界

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### 项目级上下文
- `.planning/PROJECT.md` — Core value, constraints, key decisions; 平台差异化的显式架构选择
- `.planning/REQUIREMENTS.md` — Phase 2 拥有 5 个需求：IMP-01 (.docx 导入), IMP-02 (.pdf 导入), IMP-04 (进度+失败+重试), QST-03 (单选/多选标识), UI-04 (平台分支导入页)
- `.planning/ROADMAP.md` §"Phase 2: Desktop File Import Pipeline" — 阶段目标、成功标准、8 个计划列表

### Phase 1 产物
- `.planning/phases/01-foundation-persistence/01-CONTEXT.md` — Phase 1 所有决策（项目结构、DB schema、PathResolver、主题系统）
- `lib/core/paths.dart` — PathResolver：cacheDir / tempDir / modelsDir 已就绪
- `lib/data/db/tables/parse_jobs.dart` — ParseJobs 表定义（id, sourcePath, status, progress, resultCount, errorMessage）
- `lib/data/db/tables/question_banks.dart` — QuestionBanks 表定义
- `lib/data/db/tables/questions.dart` — Questions 表定义（stem, options_json, correct_json, raw_text, type, bank_id）
- `lib/routing/router.dart` — `/import` 路由已存在 → `ImportScreen`（占位）
- `lib/features/import/presentation/import_screen.dart` — 当前占位："TODO — ImportScreen (Phase 2 实现桌面端 .docx/.pdf/.json; Phase 5 加 Android .json 入口)"

### 参考数据
- `doc/example/` — **必读**：4 份真实中国大学题库文件（`.doc` × 2, `.docx` × 1, `.pdf` × 1），用于测试和格式分析
  - `《纲要》选择题（2026年5月最新修订版）.pdf` (2.4 MB)
  - `《毛概》题库-2025-2026（二）(1).doc` (210 KB)
  - `思想道德与法治题库2026年1月版.doc` (161 KB)
  - `习近平新时代中国特色社会主义思想概论题库（2026年春季学期）5月28日修订.docx` (120 KB)

### 研究参考
- `.planning/research/PITFALLS.md` §PITFALL 6 (stem fragmentation — chunking 策略) + §PITFALL 1 (LLM JSON drift — heuristic parser 作为确定性 fallback)
- `.planning/research/STACK.md` — 技术栈：`file_picker`、`archive`、`xml`、`pdfx` 等依赖

### 外部（待定义）
- `doc/question-bank-json.md` — JSON 题库格式存根（Phase 5 实现，但 Phase 2 解析器产出的结构应对齐此格式）

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **PathResolver** (`lib/core/paths.dart`)：已提供 `cacheDir` / `tempDir`——解析过程中的临时文件存放 `tempDir`，导入缓存放 `cacheDir`
- **ParseJobs 表** (`lib/data/db/tables/parse_jobs.dart`)：状态机已定义（pending → running → succeeded/failed/cancelled），progress 0-1，errorMessage 字段
- **QuestionBanks 表**：source 字段可存源文件路径，question_count 由解析结果更新
- **Questions 表**：raw_text 字段存放原始文本供调试/重放，options_json + correct_json 存放解析出的结构化数据

### Established Patterns
- Riverpod `@riverpod` 代码生成——所有 provider 走此模式
- 按特性分层：`lib/features/import/` 下放 import 相关的 presentation / providers / widgets
- `Platform.isWindows || Platform.isLinux` 作为桌面端分支条件——ImportScreen 中照此模式分支
- Material 3 主题系统（`buildAppTheme` / `buildDynamicTheme`）——新页面直接使用 `Theme.of(context)`

### Integration Points
- FAB 集成到 `lib/features/home/presentation/home_screen.dart`（当前只有占位布局，无 FAB）
- 导入流程触发后导航到 `/import` 或新路由 `/import/preview`（planner 决定路由设计）
- ParseJob 写入由解析 provider 管理——planner 决定是在 `lib/data/` 下加 repository 还是直接在 feature 内操作 drift DAO
</code_context>

<specifics>
## Specific Ideas

- 用户在 `doc/example/` 放了 4 份真实题库文件作为参考和测试数据。这些文件的格式和结构应在 research 阶段被详细分析，规划阶段用它来验证解析器。
- 文件命名含中文和特殊字符（括号、书名号等）——文件选取和路径处理需支持 Unicode 文件名。
- `.doc` 格式的加入是用户基于自己真实文件做出的务实决定——如果调研发现 `.doc` 纯 Dart 解析不可行，fallback 方案（pandoc 转换等）是可接受的。

</specifics>

<deferred>
## Deferred Ideas

- **Android `.json` 导入**：Phase 5 实现。Phase 2 只在 Android 端留下 FAB + 空白 `.json` 对话框占位。
- **JSON 导出**：Phase 5 实现。Phase 2 解析出的题目先存 DB，暂不导出 JSON。
- **LLM 解析替换 heuristic parser**：Phase 3 实现。Phase 2 的 heuristic parser 是确定性基础，Phase 3 通过 `LlmClient` 替换/增强。
- **拖放功能的 Android 版本**：Android 不支持拖放文件到应用窗口（移动端无此交互模式）。桌面端独有。

</deferred>

---

*Phase: 02-desktop-file-import-pipeline*
*Context gathered: 2026-06-19*
