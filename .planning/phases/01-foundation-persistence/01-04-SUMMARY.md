---
phase: 01-foundation-persistence
plan: 04
subsystem: routing
tags: [go_router, navigation, placeholder-screens]
requires: ["01-01", "01-02", "01-03"]
provides: [appRouter, HomeScreen, 5 placeholder screens]
affects: [lib/main.dart, lib/routing/, lib/features/*/presentation/]
tech-stack:
  added: []
  patterns: [GoRouter 6-route config, MaterialApp.router wiring]
key-files:
  created:
    - lib/routing/router.dart
    - lib/features/home/presentation/home_screen.dart
    - lib/features/bank_detail/presentation/bank_detail_screen.dart
    - lib/features/quiz/presentation/quiz_screen.dart
    - lib/features/stats/presentation/stats_screen.dart
    - lib/features/bookmarks/presentation/bookmarks_screen.dart
    - lib/features/import/presentation/import_screen.dart
    - test/routing/router_test.dart
  modified:
    - lib/main.dart
decisions:
  - GoRouter 配置使用 6 条 GoRoute,无 ShellRoute (StatefulShellRoute 推迟到 Phase 5)
  - 初始位置测试改用 widget test (GoRouter 未挂载到 widget 树时 currentConfiguration 为空)
  - 5 个占位屏幕使用 Scaffold + AppBar + Center(Text('TODO')) 模式
  - go_router 是唯一导航 API — 静态 grep 确认 lib/ 中无 Navigator.push 调用
metrics:
  duration: 4min 12s
  completed_date: "2026-06-19T10:04:34Z"
---

# Phase 01 Plan 04: GoRouter Configuration & Navigation Skeleton — Summary

**One-liner:** GoRouter 6-route 导航骨架落地 — MaterialApp.router 替换 MaterialApp,8 个路由冒烟测试全部通过

## Tasks Completed

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 | Create 6 placeholder screens | `3d433e6` | 6 screen files under `lib/features/*/presentation/` |
| 2 | Create GoRouter config | `eb40549` | `lib/routing/router.dart` |
| 3 | Wire MaterialApp.router | `f654b37` | `lib/main.dart` |
| 4 | Write router smoke tests | `33a91fd` | `test/routing/router_test.dart` |

## Verification

- [x] `flutter analyze` — No issues found
- [x] `flutter test` — 19/19 passing (6 PathResolver + 5 DB + 8 Router)
- [x] `grep -rn "Navigator.push" lib/` — 0 lines (go_router sole nav API)
- [x] 6 `GoRoute` paths: `/`, `/bank/:id`, `/quiz/:bankId/:mode`, `/stats`, `/bookmarks`, `/import`
- [x] `errorBuilder` configured with "Route not found" message
- [x] `MaterialApp.router(routerConfig: appRouter)` in main.dart with `ThemeMode.system` and `Locale('zh', 'CN')`
- [x] 8 router tests cover: initial render, 6 route paths, error route

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Missing import] go_router 类型未在测试文件中导入**
- **发现于:** Task 4 (router_test.dart)
- **问题:** 测试文件使用 `GoRoute` 类型和 `.whereType<GoRoute>()` 但未导入 `package:go_router/go_router.dart`
- **修复:** 添加 `import 'package:go_router/go_router.dart';`
- **文件修改:** `test/routing/router_test.dart`
- **提交:** `33a91fd`

**2. [Rule 1 - Bug] 初始位置单元测试在纯 Dart 测试中失败**
- **发现于:** Task 4 (router_test.dart)
- **问题:** `appRouter.routerDelegate.currentConfiguration.uri.path` 返回空字符串而非 `/`——GoRouter 未挂载到 widget 树时 `initialLocation` 尚未解析
- **修复:** 将纯单元测试改为 widget 测试,验证初始渲染显示 HomeScreen (`find.text('红课复习')`)
- **文件修改:** `test/routing/router_test.dart`
- **提交:** `33a91fd`

## Known Stubs

| 文件 | 行 | 描述 | 后继计划 |
|------|-----|------|----------|
| `lib/features/home/presentation/home_screen.dart` | 19 | "Home — 占位,完整布局在 01-05" | Plan 01-05 (theme + full home layout) |
| `lib/features/bank_detail/presentation/bank_detail_screen.dart` | 13 | "TODO — BankDetailScreen (完整实现见 Phase 4)" | Phase 4 |
| `lib/features/quiz/presentation/quiz_screen.dart` | 14 | "TODO — QuizScreen (完整实现见 Phase 4)" | Phase 4 |
| `lib/features/stats/presentation/stats_screen.dart` | 11 | "TODO — StatsScreen (完整实现见 Phase 5)" | Phase 5 |
| `lib/features/bookmarks/presentation/bookmarks_screen.dart` | 11 | "TODO — BookmarksScreen (完整实现见 Phase 5)" | Phase 5 |
| `lib/features/import/presentation/import_screen.dart` | 11 | "TODO — ImportScreen (Phase 2/5)" | Phase 2 + Phase 5 |

所有 stub 均为计划中明确标注的占位实现，后继计划将替换为完整 UI。

## Threat Flags

| Flag | File | Description |
|------|------|-------------|
| threat_flag: path-params | `lib/routing/router.dart` | `bankId` 和 `mode` 路径参数来自 URL,Phase 4+ 需在 DB 查询前验证 (T-04-01) |

## Self-Check

验证 SUMMARY.md 中声明的所有文件存在且已提交：

- [x] `lib/routing/router.dart` — FOUND
- [x] `lib/features/home/presentation/home_screen.dart` — FOUND
- [x] `lib/features/bank_detail/presentation/bank_detail_screen.dart` — FOUND
- [x] `lib/features/quiz/presentation/quiz_screen.dart` — FOUND
- [x] `lib/features/stats/presentation/stats_screen.dart` — FOUND
- [x] `lib/features/bookmarks/presentation/bookmarks_screen.dart` — FOUND
- [x] `lib/features/import/presentation/import_screen.dart` — FOUND
- [x] `test/routing/router_test.dart` — FOUND
- [x] `3d433e6` (feat: 6 screens) — FOUND
- [x] `eb40549` (feat: router config) — FOUND
- [x] `f654b37` (feat: MaterialApp.router) — FOUND
- [x] `33a91fd` (test: router tests) — FOUND

## Self-Check: PASSED
