# Phase 1: Foundation & Persistence - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2025-01-14
**Phase:** 01-foundation-persistence
**Areas discussed:** 项目初始化粒度, DB schema 表设计, 路径分层, Material 3 主题种子

---

## 项目初始化粒度

| Option | Description | Selected |
|--------|-------------|----------|
| `com.redclass` | 与项目名 RedClass 一致；三端产物名统一 | ✓ |
| `io.github.redclass` | 预留后续以个人账号发布到 pub.dev / GitHub Releases | |
| `io.github.<用户名>` | 以个人账号发布 | |

| Option | Description | Selected |
|--------|-------------|----------|
| 按特性分层（lib/core、lib/data、lib/domain、lib/features） | 与 research 推荐的架构一致 | ✓ |
| 按层划分（lib/data、lib/ui、lib/services） | 传统 MVP 风格 | |
| 简化的两目录 | 全部集中在 lib/ | |

| Option | Description | Selected |
|--------|-------------|----------|
| 启用 `@riverpod` + `build_runner` | Provider 更简洁可读；与 drift/freezed 工具链统一 | ✓ |
| 不启用 | 手写 final Provider/AsyncNotifier；减少构建依赖 | |

| Option | Description | Selected |
|--------|-------------|----------|
| AppImage 优先 | 跨发行版，单文件可运行 | ✓ |
| `.deb` 优先 | Debian/Ubuntu 系主流 | |
| Arch Linux (pacman) 优先 | 仅适合 Arch 同学 | |

**User's choice:** com.redclass + 按特性分层 + 启用 codegen + AppImage
**Notes:** 用户在初始化阶段已明确这些取舍。"启用 codegen"是为了与 drift/freezed 统一工具链，少一次 build step 切换。

---

## DB schema 表设计

| Option | Description | Selected |
|--------|-------------|----------|
| 基本元数据：id/name/source/question_count/created_at/updated_at | 极简，不冗余 | ✓ |
| 额外加 import_source_type / parse_job_id / last_attempt_at | 为 Phase 2/3 预留字段 | |

| Option | Description | Selected |
|--------|-------------|----------|
| 极简 + raw_text | id/bank_id/type/stem/options_json/correct_json/raw_text/created_at | ✓ |
| 丰富 + 多个预留字段 | 额外加 explanation/tags/difficulty/order_index | |

| Option | Description | Selected |
|--------|-------------|----------|
| 独立表 `WrongLedgerEntry` | 状态机清晰，避免 bool 字段组合爆炸 | ✓ |
| 在 Question 表加字段 | 表少，但与状态机描述不匹配 | |

| Option | Description | Selected |
|--------|-------------|----------|
| 基本：id/question_id/given_answer_json/is_correct/mode/elapsed_ms/created_at | 够用 | ✓ |
| 全面：+session_id/+bank_id/+confidence | 冗余更多数据 | |

| Option | Description | Selected |
|--------|-------------|----------|
| 独立表 `Bookmark(question_id, created_at)` | Phase 5 完整实现，Phase 1 占位 | ✓ (隐含) |

| Option | Description | Selected |
|--------|-------------|----------|
| 独立表 `ParseJob` | Phase 2 完整实现，Phase 1 占位 | ✓ (隐含) |

| Option | Description | Selected |
|--------|-------------|----------|
| 独立表 `ParseLog` | Phase 6 完整实现，Phase 1 占位 | ✓ (隐含) |

**User's choice:** 全选极简+独立错题本表。
**Notes:** 用户在 Question 表坚持保留 `raw_text`——这与 research 的"闭源+无遥测时 raw_text 可重放"建议一致。

---

## 路径分层

| Option | Description | Selected |
|--------|-------------|----------|
| 3 层分层：DB 在 support/、模型与缓存副本在 documents/、临时文件在 temp/ | 结构清晰 | ✓ |
| 全部放 support/ | 简单但模型备份麻烦 | |

| Option | Description | Selected |
|--------|-------------|----------|
| `documents/models/*.gguf` | Windows 用户可手动管理 | ✓ |
| `support/models/*.gguf` | 用户不可见，备份需手动找路径 | |

| Option | Description | Selected |
|--------|-------------|----------|
| `documents/cache/` + `documents/diagnostics/` | 用户可见但不手动看；可手动清理 | ✓ |
| 全部在 support/cache/ | 不向用户暴露 | |

**User's choice:** 3 层分层 + documents/models + documents/cache + documents/diagnostics
**Notes:** 决策与 PITFALLS §3 的"OneDrive 同步会污染 documents/"的警告直接相关——DB 必须放 support/。用户接受模型和缓存放 documents/，因为它们的损坏不会让用户数据丢失（可重新下载/重新解析）。

---

## Material 3 主题种子

| Option | Description | Selected |
|--------|-------------|----------|
| Material You dynamic_color | Android 12+ / Windows 11 自动取系统壁纸色 | ✓ |
| 固定静态色 | 应用指定一个静态主色 | |
| 深色品牌色（近红/砖红） | 与 RedClass 品牌呼应 | |

| Option | Description | Selected |
|--------|-------------|----------|
| ThemeMode.system | 跟随系统 | ✓ |
| 默认亮色 | 固定亮色 | |
| 默认深色 | 固定深色 | |

| Option | Description | Selected |
|--------|-------------|----------|
| 手写 ThemeData + ColorScheme.fromSeed | 少一个依赖 | ✓ |
| 用 flex_color_scheme 包装 | 包装好，但多一个依赖 | |

**User's choice:** 动态颜色 + 跟系统 + 手写 ThemeData
**Notes:** 用户没在主题色上与"红"做强绑定——选择 Material You dynamic_color 的理由是"专业、克制、跟着用户的系统走"比"强行刷品牌色"更符合"专注刷题"的核心价值。

---

## Claude's Discretion

- `pubspec.yaml` 的 SDK/Flutter 版本范围（基于 `flutter create` 默认值）
- drift `DatabaseConnection` 选型（无 web 目标，确定为 `NativeDatabase`）
- `lib/core/` 内部如何组织（paths/theme/utils/constants 各一文件即可）
- 是否在 Phase 1 引入 `intl`（倾向于 Phase 5 统计页引入）
- `go_router` 路由 path 命名细节（保持与 ROADMAP 列出的 6 个路由一致）

---

## Deferred Ideas

- GitHub Actions / CI 流水线（用户明确"小范围分享"不需要）
- 主题切换 UI（v1 Out of Scope，Phase 6 可补）
- `intl` 包引入时机（Phase 5 统计页引入更合适）
- Drift schema v2 升级路径（v1 不预留 v2 字段）
- 任何对 "Phase 2 才需要的字段（import_source_type / parse_job_id）"的预留
