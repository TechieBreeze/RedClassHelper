# Phase 4 Discussion Log

**Phase:** 04-quiz-core-wrong-question-ledger
**Date:** 2026-06-20
**Areas discussed:** 4

---

## Area 1: 答题交互模式 (Quiz Interaction)

**Q:** 答题页展示方式？单题逐个 vs 列表滚动？
**A:** 单题逐个展示，提交后自动跳转下一题。一屏只显示一道题。

**Q:** 提交方式？点击选项即提交 vs 选中后点提交按钮？
**A:** 两种模式都支持，在设置中切换。默认点击选项即提交（`quiz_submit_mode: 'instant'`）。

**Q:** 自动跳转延迟？固定延迟 vs 手动翻题？
**A:** 两种模式都支持，在设置中切换。默认自动跳转延迟约 2 秒（`quiz_advance_mode: 'auto'`）。

**Q:** 答对/答错反馈形式？
**A:** 展示 ✔/✘ 图标 + 高亮正确答案 + 标记用户错误选项。选项以绿色（正确）/ 红色（错误）/ 默认色（未选）区分。

**Q:** 进度指示方式？
**A:** 顶部显示线性进度条 + 文字"第 3/20 题"。

**Q:** 桌面端键盘快捷键？
**A:** A/B/C/D 键选择选项，空格键提交，→ 键下一题。快捷键提示以半透明小字显示在选项区域下方。

**Q:** 设置页如何暴露答题设置？
**A:** 设置页（/settings）新增"答题设置" section，暴露 quiz_submit_mode 和 quiz_advance_mode 两个开关。使用 shared_preferences 持久化。

**User correction:** 默认值设为"选中后直接提交"而非"选中后确认"。D-02 更新为默认 'instant'。

---

## Area 2: 题库选择 (Bank Selection)

**Q:** 进入答题前是否需要题库选择？
**A:** 三种模式进入答题前都需要题库选择——每次都弹出独立全屏选择页，即使只有 1 个题库也显示。

**Q:** 题库选择页显示什么信息？
**A:** 每个题库的名称、题目总数、错题数。空题库显示"N/A"并置灰。

**Q:** 路由方案？
**A:** 主页 → `/quiz/pick/{mode}` → 题库选择页 → `/quiz/{bankId}/{mode}` → 答题页。GoRouter 新增 `/quiz/pick/:mode` 路由。

---

## Area 3: 完成流程 (Completion Flow)

**Q:** 一轮答题结束后显示什么？
**A:** 统计摘要页：正确率（百分比）、总用时、答错题数、错题本新增/已掌握数。

**Q:** 摘要页提供什么操作？
**A:** 两个行动按钮："再来一轮"（同题库 + 同模式重新开始）和"返回主页"。

**Q:** 错题复习全部掌握时？
**A:** 摘要页显示"🎉 全部掌握"提示，错题本为空。

---

## Area 4: 错题可见性与账本状态机 (Ledger Visibility & State Machine)

**Q:** 主页如何显示错题数？
**A:** "错题复习"和"错题抽查"卡片右上角显示错题数 badge（全局，WHERE mastered_at IS NULL）。错题数为 0 时隐藏 badge。

**Q:** 答题中答错时的实时反馈？
**A:** 反馈区域显示"已加入错题本" chip 标签（短暂出现，约 1.5 秒）。

**Q:** 错题账本状态变更如何保证一致性？
**A:** 所有账本状态变更通过单一 `LedgerRepository` 方法完成，每次变更包裹在 SQLite 事务中。

**Q:** LedgerRepository 接口？
**A:**
- `markWrong(questionId)`: INSERT OR REPLACE, timesWrong+1, lastWrongAt=now
- `markMastered(questionId)`: UPDATE masteredAt=now
- `getActiveCount()`: SELECT COUNT WHERE masteredAt IS NULL
- `getActiveByBank(bankId)`: JOIN Questions WHERE masteredAt IS NULL AND bankId=?

---

## Claude's Discretion (Not Discussed)

These were left to implementer judgment:
- 答题页具体布局（选项卡片排列、间距、反馈动画）
- 键盘快捷键提示的 UI 样式
- 统计摘要页的视觉设计
- 题库选择页的列表样式（沿用 Card+InkWell 模式）
- 进度条的具体颜色和动画
- 设置页两个开关的 UI 位置和样式
- 答题设置的 shared_preferences key 命名

---

*Discussion completed: 2026-06-20*
