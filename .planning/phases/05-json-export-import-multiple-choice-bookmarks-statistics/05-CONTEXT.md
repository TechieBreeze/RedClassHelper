# Phase 5: JSON Export/Import + Multiple-Choice + Statistics - Context

**Gathered:** 2026-06-20
**Status:** Ready for planning

<domain>
## Phase Boundary

实现 JSON 导出/导入（桌面端题库传输协议）、多选题判分（精确匹配）、统计页（每题题库 + 各模式正确率）、主页题库列表（替换占位卡片）。仅桌面端（Windows/Linux）。

**本阶段不实现**：收藏（已从 Phase 5 移出，用户明确）、UX 打磨（Phase 6）、暗色主题（Phase 6）、session 恢复（Phase 6）。

</domain>

<decisions>
## Implementation Decisions

### JSON 格式设计
- **D-01:** JSON 格式对齐用户提供的真实题库格式。题目为编号对象（非数组），每题包含：`question`（题干，含题号前缀）、`answer`（`{"A":"...", ...}` 选项映射）、`key`（拼接答案字符串，如 `"B"` / `"ABC"`）、`answer_type`（`0`=单选, `1`=多选）。
- **D-02:** 题库级元数据：仅 `name` + `version`（schema version，初始 `"1.0"`）。不导出 timestamps 或原始 UUID。

### JSON 导出 UX
- **D-03:** 导出入口：题库详情页（bank detail page）内的"导出 JSON"按钮。非右键菜单。
- **D-04:** 导出时弹出系统原生文件保存对话框，用户选择保存路径。

### JSON 导入 UX
- **D-05:** JSON 导入集成到现有导入流程：导入页选 `.json` → 文件选择器 → 直接解析提交入库（不走预览编辑页，因为 JSON 格式已是精确数据）。
- **D-06:** 同名题库处理：替换已有题库（按题库名匹配）。不弹出确认对话框。

### 多选题判分
- **D-07:** 精确匹配判分 —— 用户必须选中全部正确选项且不多选任何错误选项才算正确。`["A","C"]` 选 `["A"]` 或 `["A","C","D"]` 均为错误。
- **D-08:** 多选题提交流程：复选框 + 确认按钮（QuizScreen 已有此逻辑，`isMultiChoice = correctKeys.length > 1` 时选项切换 + 必须点确认提交）。

### 统计页
- **D-09:** 每题题库统计卡片：总题数、总答题次数、正确率、错题本活跃错题数。
- **D-10:** 每题题库展开显示各模式正确率：乱序抽题 / 错题复习 / 错题抽查。
- **D-11:** 纯文字 + 数字展示，不使用图表。复用 `Card` + `InkWell` 模式。

### 主页题库列表
- **D-12:** 移除"还没有题库"占位卡片，接入真实题库列表（已有 `questionBanksProvider`）。
- **D-13:** 题库卡片显示：题库名、题数、来源文件名。点击进入题库详情页（bank detail）。
- **D-14:** 题库详情页提供"导出 JSON"按钮 + "开始复习"入口。

### 收藏
- **D-15:** 收藏功能从 Phase 5 移出（用户明确"不需要收藏"）。已存在的 `Bookmarks` 表保留但不使用。主页不添加收藏入口。QuizScreen 不添加星标按钮。

### Claude's Discretion
- 题库详情页（BankDetailScreen）具体布局
- JSON 转换层实现（DB schema `optionsJson`/`correctJson` ↔ 用户 JSON 格式 `answer`/`key`）
- 统计页视觉布局（卡片 per bank，展开/per-mode 分解，无图表）
- 文件保存/打开对话框集成
- 主页题库卡片设计

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### 项目级上下文
- `.planning/PROJECT.md` — Core value, constraints, key decisions；v1 仅桌面端；JSON 公开格式
- `.planning/REQUIREMENTS.md` — IMP-06 (JSON 导出), IMP-07 (JSON 导入), QST-02 (多选题), STAT-02 (统计), BMK-01/BMK-02 (收藏 → 已从 Phase 5 移出)
- `.planning/ROADMAP.md` §"Phase 5: JSON Export/Import + Multiple-Choice + Bookmarks + Statistics" — 阶段目标、成功标准

### 前序阶段产物
- `.planning/phases/04-quiz-core-wrong-question-ledger/04-CONTEXT.md` — 答题循环、三模式复习、错题账本状态机、QuizScreen 现有逻辑
- `.planning/phases/02-desktop-file-import-pipeline/02-CONTEXT.md` — 导入管道架构 (ImportNotifier/ImportPhase)、文件选择器集成
- `.planning/phases/01-foundation-persistence/01-CONTEXT.md` — DB schema (Questions/QuestionBanks/AnswerAttempts 表)、PathResolver、GoRouter、Material 3 主题

### 现有代码
- `lib/data/db/tables/questions.dart` — Questions 表（type 字段已支持 'multiple'，optionsJson/correctJson 列）
- `lib/data/db/tables/question_banks.dart` — QuestionBanks 表（name, source, questionCount）
- `lib/data/db/tables/answer_attempts.dart` — AnswerAttempts 表（mode, isCorrect, elapsedMs）
- `lib/data/db/tables/bookmarks.dart` — Bookmarks 表（已存在但不使用；Phase 5 不实现收藏）
- `lib/features/quiz/presentation/quiz_screen.dart` — QuizScreen 现有多选逻辑（isMultiChoice、toggle、confirm submit）
- `lib/features/quiz/providers/quiz_session_controller.dart` — 答题控制器（submitAnswer grade 逻辑需扩展多选题精确匹配）
- `lib/features/import/presentation/import_screen.dart` — 导入页（已有 .json 入口占位）
- `lib/features/import/providers/import_notifier.dart` — 导入管道 Notifier（JSON 分支的集成点）
- `lib/features/stats/presentation/stats_screen.dart` — StatsScreen 占位（TODO Phase 5）
- `lib/features/bank_detail/presentation/bank_detail_screen.dart` — BankDetailScreen 占位（TODO）
- `lib/features/home/presentation/home_screen.dart` — 主页（_BankEmptyStateCard 需替换为真实题库列表）
- `lib/routing/router.dart` — GoRouter（/bank/:id, /stats, /import 路由已存在）
- `lib/core/paths.dart` — PathResolver（jsonImportDir/jsonExportDir 预留）

### 代码规范
- `.planning/codebase/CONVENTIONS.md` — Card+InkWell 模式、LayoutBuilder 响应式布局、Riverpod ConsumerWidget、const constructors

### 用户提供的参考格式
- 用户提供了真实题库 JSON 文件样例（159 题，含单选/多选/判断题）—— 此格式为 JSON 导出/导入的目标格式。

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **QuizScreen 多选逻辑**：`isMultiChoice = correctKeys.length > 1`、选项 toggle（Set<String>）、确认提交按钮 —— 多选题判分只需扩展 `_gradeSingleChoice()` 逻辑
- **ImportNotifier 管道**：7 个 ImportPhase 已定义 —— JSON 导入只需新增一个快速提交路径（跳过 editing 阶段）
- **Card+InkWell 模式**：所有可交互卡片沿用此模式 —— 统计页卡片和题库列表卡片可复用
- **LayoutBuilder + ConstrainedBox (720px)**：已有响应式布局模式 —— 统计页和 bank detail 页复用
- **questionBanksProvider**：已存在的题库列表 provider（Phase 1）—— 主页直接接入

### Established Patterns
- **Riverpod ConsumerWidget**：所有屏幕都是 StatelessWidget + ConsumerWidget
- **GoRouter 唯一导航 API**：禁止 Navigator.push
- **Platform 分支**：`Platform.isWindows || Platform.isLinux` 守卫
- **@Riverpod(keepAlive: true)** for singletons
- **DB transaction wrapping**：LedgerRepository 模式 —— 数据一致性

### Integration Points
- **ImportNotifier**：JSON 导入需在 `extractAndParse()` 或新增方法中处理 JSON 文件解析
- **QuizSessionController**：`submitAnswer()` 的 grade 逻辑需区分单选/多选（精确匹配）
- **BankDetailScreen**：占位页面需完整实现（题库信息 + 导出按钮 + 复习入口）
- **HomeScreen**：`_BankEmptyStateCard` 需替换为 `Consumer` + `questionBanksProvider`
- **StatsScreen**：占位页面需完整实现（per-bank 聚合查询 + per-mode breakdown）
- **GoRouter**：/bank/:id 路由已存在，无需新增路由

</code_context>

<specifics>
## Specific Ideas

- JSON 格式对齐用户提供的真实样例 —— 题目编号 object、`answer` 选项 map、`key` 拼接字符串、`answer_type` 0/1。这是用户实际使用的格式，不做改动。
- 用户反馈主页"永远显示没有题库"的问题 —— Phase 5 一并修复，让导入的题库在主页可见且可点击进入详情。
- 统计页不需要图表 —— 数字 + 百分比文字即可，保持简洁。

</specifics>

<deferred>
## Deferred Ideas

- **收藏功能** — 用户明确"不需要收藏"。`Bookmarks` 表保留但不在 Phase 5 实现。如未来需要可重新纳入。
- **暗色/浅色主题切换** — Phase 6
- **答题页动画打磨** — Phase 6
- **session state 恢复** — Phase 6
- **统计图表**（趋势图、错题分布图）— v2

</deferred>

---

*Phase: 05-json-export-import-multiple-choice-bookmarks-statistics*
*Context gathered: 2026-06-20*
