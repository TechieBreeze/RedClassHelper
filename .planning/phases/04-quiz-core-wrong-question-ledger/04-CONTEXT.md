# Phase 4: Quiz Core & Wrong-Question Ledger - Context

**Gathered:** 2026-06-20
**Status:** Ready for planning

<domain>
## Phase Boundary

实现答题循环（单选） + 三种复习模式（乱序抽题 / 错题复习 / 错题抽查）+ 共享错题账本状态机。仅桌面端（Windows/Linux）。

**本阶段不实现**：多选题（Phase 5）、JSON 导入/导出（Phase 5）、收藏（Phase 5）、统计页完整实现（Phase 5）、UX 打磨（Phase 6）。本阶段只产出"可完整走通三模式答题 + 错题账本原子写入 + 答题记录持久化"的核心循环。

</domain>

<decisions>
## Implementation Decisions

### 答题交互模式
- **D-01:** 单题逐个展示，提交后自动跳转下一题。一屏只显示一道题的题干 + 选项。
- **D-02:** 默认提交方式为"点击选项即提交"。设置页提供开关切换为"选中后点提交确认"（quiz_submit_mode: 'instant' | 'confirm'，默认 'instant'）。
- **D-03:** 默认自动跳转延迟约 2 秒，期间展示对错反馈。设置页提供开关切换为"手动翻题"（quiz_advance_mode: 'auto' | 'manual'，默认 'auto'）。
- **D-04:** 答对/答错反馈：展示 ✔/✘ 图标 + 高亮正确答案 + 标记用户错误选项。选项以绿色（正确）/ 红色（错误）/ 默认色（未选）区分。
- **D-05:** 进度指示：顶部显示线性进度条 + 文字"第 3/20 题"。
- **D-06:** 桌面端键盘快捷键支持：A/B/C/D 键选择选项，空格键提交，→ 键下一题。快捷键提示以半透明小字显示在选项区域下方。
- **D-07:** 设置页（/settings）新增"答题设置" section，暴露 quiz_submit_mode 和 quiz_advance_mode 两个开关。使用 shared_preferences 持久化。

### 题库选择
- **D-08:** 三种模式进入答题前都需要题库选择——每次都弹出独立全屏选择页，即使只有 1 个题库也显示。
- **D-09:** 题库选择页显示每个题库的名称、题目总数、错题数（来自 WrongLedgerEntries + Questions JOIN WHERE mastered_at IS NULL）。空题库显示"N/A"并置灰。
- **D-10:** 路由方案：主页 → `/quiz/pick/{mode}` → 题库选择页 → `/quiz/{bankId}/{mode}` → 答题页。GoRouter 新增 `/quiz/pick/:mode` 路由。

### 完成流程
- **D-11:** 一轮答题结束后显示统计摘要页：正确率（百分比）、总用时、答错题数、错题本新增/已掌握数。
- **D-12:** 摘要页提供两个行动按钮："再来一轮"（同题库 + 同模式重新开始）和"返回主页"。
- **D-13:** 错题复习中所有错题已掌握时，摘要页显示"🎉 全部掌握"提示，错题本为空。

### 错题可见性
- **D-14:** 主页的"错题复习"和"错题抽查"卡片右上角显示错题数 badge（全局，WHERE mastered_at IS NULL）。错题数为 0 时隐藏 badge。
- **D-15:** 答题中答错时，反馈区域显示"已加入错题本"chip 标签（短暂出现，约 1.5 秒），给予实时反馈。

### 错题账本状态机
- **D-16:** 所有账本状态变更（markWrong / markMastered）通过单一 `LedgerRepository` 方法完成，每次变更包裹在 SQLite 事务中。接口见 ROADMAP §Phase 4。
- **D-17:** `markWrong(questionId)`: INSERT OR REPLACE into WrongLedgerEntries, timesWrong+1, lastWrongAt=now。`markMastered(questionId)`: UPDATE masteredAt=now。`getActiveCount()`: SELECT COUNT WHERE masteredAt IS NULL。`getActiveByBank(bankId)`: JOIN Questions WHERE masteredAt IS NULL AND bankId=?。

### Claude's Discretion
- 答题页（QuizScreen）具体布局——选项卡片排列（竖排 vs 横排）、间距、反馈动画
- 键盘快捷键提示的 UI 样式（半透明 overlay vs tooltip vs 底部固定条）
- 统计摘要页的视觉设计（布局、图表、颜色）
- 题库选择页的列表样式（沿用已有 Card+InkWell 模式）
- 进度条的具体颜色和动画
- 设置页两个开关的 UI 位置和样式
- 答题设置的 shared_preferences key 命名

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### 项目级上下文
- `.planning/PROJECT.md` — Core value, constraints, key decisions；v1 仅桌面端
- `.planning/REQUIREMENTS.md` — QST-01 (单选), REV-01~06 (三模式复习), STAT-01 (答题记录), UI-03 (答题界面)
- `.planning/ROADMAP.md` §"Phase 4: Quiz Core & Wrong-Question Ledger" — 阶段目标、成功标准、8 个计划列表

### 前序阶段产物
- `.planning/phases/01-foundation-persistence/01-CONTEXT.md` — DB schema (Questions/WrongLedgerEntries/AnswerAttempts 表)、PathResolver、项目分层结构、Material 3 主题
- `.planning/phases/03-desktop-llm-integration-parse-quality/03-CONTEXT.md` — 解析管道集成（Phase 3 产出题目数据供 Phase 4 消费）

### 现有代码
- `lib/data/db/tables/questions.dart` — Questions 表 schema（type, stem, optionsJson, correctJson）
- `lib/data/db/tables/wrong_ledger_entries.dart` — WrongLedgerEntries 表 schema（UNIQUE question_id, timesWrong, masteredAt）
- `lib/data/db/tables/answer_attempts.dart` — AnswerAttempts 表 schema（questionId, givenAnswerJson, isCorrect, mode, elapsedMs）
- `lib/features/home/presentation/home_screen.dart` — 主页 3 个模式入口（_ModeTile → /quiz/new/{mode}）
- `lib/features/quiz/presentation/quiz_screen.dart` — 当前占位 QuizScreen（TODO Phase 4）
- `lib/routing/router.dart` — GoRouter 配置（/quiz/:bankId/:mode 路由已存在）

### 代码规范
- `.planning/codebase/CONVENTIONS.md` — Card+InkWell 模式、LayoutBuilder 响应式布局、Riverpod ConsumerWidget、const constructors

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **Card+InkWell 模式**：所有可交互卡片沿用此模式（CONVENTIONS.md）——题库选择页的 bank card 可复用
- **LayoutBuilder 响应式布局**：HomeScreen 的 3 断点布局（<600 / <840 / ≥840）——答题页和选择页可复用
- **_SectionHeader**：HomeScreen 的 section 标题组件模式——题库选择页的"选择一个题库"标题可复用
- **Chip**：ModelManagementScreen 中已使用 Chip（"已安装"/"推荐"/"快速"/"实验"）——错题 badge 可参考

### Established Patterns
- **Riverpod ConsumerWidget**：所有屏幕都是 StatelessWidget + ConsumerWidget
- **@Riverpod(keepAlive: true)** for singletons, **@riverpod** for regular providers
- **GoRouter 唯一导航 API**：禁止 Navigator.push，所有页面跳转走 GoRouter
- **LayoutBuilder + ConstrainedBox** 居中限制最大宽度 (720px)
- **Platform 分支**：`Platform.isWindows || Platform.isLinux` 守卫（Phase 4 全部功能仅桌面端）

### Integration Points
- **DB 已就绪**：Questions / WrongLedgerEntries / AnswerAttempts 三张表已定义，AppDatabase 已注册
- **Router 已有路由**：`/quiz/:bankId/:mode` 已注册
- **HomeScreen 已有入口**：3 个 _ModeTile 指向 `/quiz/new/{mode}`
- **设置页已存在**：SettingsScreen 在 `/settings`，可扩展"答题设置" section
- **shared_preferences**：Phase 6 会引入，Phase 4 提前用于答题设置持久化

</code_context>

<specifics>
## Specific Ideas

- 选项用 A/B/C/D 字母标识，点击或按键选中高亮后提交
- 正确选项绿底 + ✔，错误选项红底 + ✘，用户误选标记为红色边框
- "已加入错题本" chip 出现时带轻微动画，不打断答题节奏
- 统计摘要页不一定需要图表——文字数字 + 简单百分比展示即可（图表留给 Phase 5）

</specifics>

<deferred>
## Deferred Ideas

- **多选题渲染与判分** — Phase 5
- **答题统计页完整实现** — Phase 5（Phase 4 只有摘要，不做持久化统计页）
- **收藏功能** — Phase 5
- **JSON 导出/导入** — Phase 5
- **暗色/浅色主题切换** — Phase 6
- **答题页动画打磨** — Phase 6
- **session state 恢复（杀应用重开回到题目）** — Phase 6

</deferred>

---

*Phase: 04-quiz-core-wrong-question-ledger*
*Context gathered: 2026-06-20*
