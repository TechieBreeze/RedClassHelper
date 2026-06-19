---
phase: 03-desktop-llm-integration-parse-quality
plan: 06
subsystem: model-management-ui
tags: [ui, model-management, settings, routing, desktop-only]
requires: ["03-05"]
provides: [model-card, download-progress, add-model-dialog, settings-screen, model-management-screen, settings-route]
affects: ["03-07", "03-08"]
tech-stack:
  added: [file_picker, gguf-validator]
  patterns: [ConsumerWidget, StatefulWidget (dialog), GoRoute, LayoutBuilder-responsive]
key-files:
  created:
    - lib/features/models/presentation/settings_screen.dart
    - lib/features/models/presentation/model_management_screen.dart
    - lib/features/models/widgets/model_card.dart
    - lib/features/models/widgets/download_progress.dart
    - lib/features/models/widgets/add_model_dialog.dart
    - test/features/models/presentation/model_management_screen_test.dart
  modified:
    - lib/routing/router.dart
    - test/routing/router_test.dart
decisions:
  - "AddModelDialog uses StatefulWidget (plan exception to all-StatelessWidget convention) for local tab/text state"
  - "ModelCard consumes providers directly (ConsumerWidget) rather than accepting callbacks — consistent with Riverpod architecture"
  - "Installed model cards in section 1 remain inline private widgets (not ModelCard) since they have different layout requirements"
  - "Delete model functionality is UI-stubbed (dialog shows but no file deletion performed) — deferred to download pipeline completion"
metrics:
  duration: 21 min
  completed_date: "2026-06-20"
---

# Phase 3 Plan 6: Model Management UI Summary

One-liner: Built desktop-only model management UI with SettingsScreen, ModelManagementScreen (3-section layout), ModelCard (6 download states), DownloadProgress, and AddModelDialog (URL + local file tabs) — 6 new Dart files, 2 modified files, 3 commits.

## Task Summary

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 | SettingsScreen + ModelManagementScreen | b5caf66 | 3 created (settings_screen.dart, model_management_screen.dart, test file) |
| 2 | ModelCard, DownloadProgress, AddModelDialog | 1db42f8 | 3 created (model_card.dart, download_progress.dart, add_model_dialog.dart) + 2 updated |
| 3 | GoRouter /settings + /settings/models | dfdf0ba | 2 modified (router.dart, router_test.dart) |

## What Was Built

### SettingsScreen (`/settings`)
- AppBar "设置" + single ListTile "模型管理" (desktop-gated via `Platform.isWindows || Platform.isLinux`)
- Subtitle: "查看已安装模型、下载推荐模型" per UI-SPEC copywriting contract
- LayoutBuilder 3-breakpoint responsive (compact/medium/expanded) following existing HomeScreen pattern

### ModelManagementScreen (`/settings/models`)
- AppBar "模型管理" with 3 sections: 已安装模型, 推荐模型, 自定义模型
- Section 1: watches `installedModelsProvider` — empty state "尚未安装模型" with guidance text, or installed model cards with "已安装" green chip
- Section 2: watches `modelCatalogProvider` + `installedModelsProvider` + `modelDownloadProvider` — renders ModelCard widgets for 3 preset tiers
- Section 3: "添加模型" tappable card + custom model list (installed but not in catalog)
- Desktop-gated: Android renders "模型管理仅在桌面端可用" placeholder
- All copy matches UI-SPEC exactly

### ModelCard Widget
- ConsumerWidget receiving `ModelInfo`, `isInstalled`, `ActiveDownload?`
- Tier badge (_TierBadge): 推荐 (primaryContainer), 快速 (green.shade100), 实验 (deepOrange.shade100) — 2dp border radius, 6dp horizontal padding
- 6 action-area states:
  - **idle**: FilledButton.icon "下载" (calls `startDownload(model)`)
  - **another-downloading**: disabled "等待中" button
  - **downloading**: DownloadProgressWidget + "取消" TextButton
  - **verifying**: CircularProgressIndicator(16) + "校验中…"
  - **installed**: green Chip "已安装" + error-colored "删除" TextButton
  - **error**: error message + OutlinedButton "重新下载"
- Delete confirmation dialog: "删除模型" / "模型文件将被删除，需要时可重新下载"

### DownloadProgressWidget
- StatelessWidget receiving `DownloadProgress`
- Renders: "下载中 {percent}%" + LinearProgressIndicator + "{speed} MB/s"
- Speed converted from bytes/sec to MB/s (divide by 1048576)

### AddModelDialog
- StatefulWidget returned via `showAddModelDialog()` (returns `ModelInfo?`)
- TabBar with 2 tabs: "从 URL 下载" / "选择本地文件"
- URL tab: TextField with label, validation for HTTPS scheme and .gguf extension
  - Non-HTTPS: "请输入有效的 HTTPS URL"
  - Non-.gguf: "该地址不指向 .gguf 文件"
- Local file tab: "浏览…" OutlinedButton using `file_picker` 11.x API
  - Wrong extension: "仅支持 .gguf 文件"
  - Invalid magic number: "文件格式无效，无法识别为 GGUF 模型" (via `GgufValidator`)
  - Valid: shows file path + size
- Submit creates ModelInfo with tier=ModelTier.custom, returns via Navigator.pop

### Routes
- `/settings` → SettingsScreen (GoRoute, builder)
- `/settings/models` → ModelManagementScreen (GoRoute, builder)
- Router test updated from 6→11 paths, includes all Phase 2+3 routes

## Threat Model Verification

| Threat ID | Status | Implementation |
|-----------|--------|---------------|
| T-03-06-01 (URL tampering) | mitigated | URL validated for HTTPS + .gguf extension with inline errors |
| T-03-06-02 (Local file tampering) | mitigated | Extension check + GgufValidator magic number check |
| T-03-06-03 (Installed badge spoofing) | accepted | Badge is informational, based on file existence |
| T-03-06-04 (Concurrent download DoS) | mitigated | Single download enforced by ModelDownloadNotifier; UI shows "等待中" |
| T-03-06-05 (Info disclosure) | accepted | Settings shows model names/sizes only, no PII |

## Deviations from Plan

### Toolchain Unavailability

**1. [Rule 3 - Blocking] Dart/Flutter SDK not available in execution environment**
- **Found during:** All tasks (verification step)
- **Issue:** `dart analyze` and `flutter test` could not be executed — Flutter SDK path from STATE.md (`C:\Users\Lenovo\flutter`) does not exist or is not accessible from git-bash in this worktree
- **Fix:** Code written following all established patterns (CONVENTIONS.md, existing codebase), Riverpod conventions, and plan specifications exactly. Manual review confirmed:
  - All imports reference existing files with correct paths
  - Provider names match generated Riverpod conventions (`modelDownloadProvider` for `ModelDownloadNotifier`)
  - Widget structure follows CONVENTIONS.md patterns (Scaffold, LayoutBuilder, ConstrainedBox, Card+InkWell)
  - All copy strings match UI-SPEC copywriting contract
  - Test assertions reference correct widgets and text
- **Impact:** Verification commands deferred to developer's local environment
- **Files affected:** All 8 files

## Known Stubs

| Stub | File | Line(s) | Reason |
|------|------|---------|--------|
| Model file deletion (catalog) | widgets/model_card.dart | `_showDeleteDialog` | Dialog shows but file deletion not implemented — pending Phase 3 download pipeline wiring |
| Model file deletion (custom) | presentation/model_management_screen.dart | `_showCustomDeleteDialog` | Same as above — file deletion deferred |
| URL import model size | widgets/add_model_dialog.dart | `_submit` (URL branch) | Size unknown until downloaded; set to `sizeBytes: 0`, `sizeDisplay: '未知大小'` |
| Download integration | model_management_screen.dart + model_card.dart | `startDownload` calls | ModelDownloader from 03-05 requires a running server; UI is wired but download won't succeed without infrastructure |

## Self-Check: PASSED

- [x] `lib/features/models/presentation/settings_screen.dart` exists
- [x] `lib/features/models/presentation/model_management_screen.dart` exists
- [x] `lib/features/models/widgets/model_card.dart` exists
- [x] `lib/features/models/widgets/download_progress.dart` exists
- [x] `lib/features/models/widgets/add_model_dialog.dart` exists
- [x] `test/features/models/presentation/model_management_screen_test.dart` exists
- [x] Commit b5caf66 exists: `feat(03-06): create SettingsScreen + ModelManagementScreen with 3-section layout`
- [x] Commit 1db42f8 exists: `feat(03-06): create ModelCard, DownloadProgressWidget, and AddModelDialog widgets`
- [x] Commit dfdf0ba exists: `feat(03-06): add /settings and /settings/models routes to GoRouter`
