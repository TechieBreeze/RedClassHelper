# RedClass 移动端迁移设计

**日期**: 2026-06-25
**状态**: 草稿（待用户审阅）
**作者**: 头脑风暴会话产物

## 目标

将 RedClass（红课复习，本地化大学课程复习工具）从当前桌面/网页为主扩展到 **Android 平台**，保持桌面端零回归。

## 范围与决策

| 决策点 | 选定 |
|--------|------|
| LLM 范围 | 现状是壳子（含桌面端），不在迁移范围 |
| UI 适配 | 全平台响应式 UI（LayoutBuilder + 断点） |
| 文件导入 | 抽象为 `FilePickerService` 平台适配层 |
| 模型管理 | 页面保留，操作按钮在 Android 上禁用 |
| 质量标准 | 80%+ 单元测试覆盖、Widget/集成测试、CI 全通过 |

## 架构

三层结构：

1. **表现层**（`features/*/presentation/`）：Screen 接收 `PlatformInfo`，使用 `ResponsiveBuilder` / `AdaptiveLayout` 决定布局变体
2. **平台适配层**（新增 `core/platform/` + `data/file_picker/`）：平台检测、响应式原语、文件选择抽象、平台门控
3. **领域层**（`features/*` 业务逻辑 + `data/db` + `data/repositories`）：与平台无关，保持不变

## 新增模块

### 1. `lib/core/platform/`
- `platform_info.dart`：平台枚举 + FormFactor（compact < 600dp / medium < 840dp / expanded ≥ 840dp）+ 派生属性（`isMobile`、`isDesktop`、`supportsLlm`）
- `responsive.dart`：`ResponsiveBuilder`、`AdaptiveLayout`（三分支，降级到 compact）
- `platform_guard.dart`：`AndroidOnlyGuard`、`DesktopOnlyGuard`、`UnsupportedFeatureGuard(feature)` — 替代散落的 `if (Platform.isAndroid)` 模式
- 平台检测用 `dart:io.Platform`（仅在数据层实现中用），UI 层只读 `PlatformInfo.fromContext(context)`

### 2. `lib/data/file_picker/`
- `file_picker_service.dart`：`abstract interface class FilePickerService` + `pickFile(allowedExtensions)` + `pickFromDroppedPath(path)`（后者桌面端 only）
- `file_picker_models.dart`：`PickedFile` sealed class，**两个变体**：
  - `PickedPathFile`：有文件系统路径（桌面拖放、桌面 file_picker）
  - `PickedBytesFile`：仅内存字节（Android SAF，URI 转 bytes）
  - 两者都实现 `Stream<Uint8List> openRead()` — 上游 PDF/DOCX 提取不感知差异
- `file_picker_errors.dart`：`FilePickerError` sealed class（`Cancelled` / `PermissionDenied` / `UnsupportedMethod` / `FileReadError` / `Unknown`）
- `file_picker_providers.dart`：`filePickerServiceProvider` 按平台返回实现
- 实现：
  - `MobileFilePickerService`（Android/iOS）：调 `file_picker` 包的 mobile API，SAF 返回 content URI → 读 bytes → `PickedBytesFile`
  - `DesktopFilePickerService`（Windows/Linux/macOS）：现有 `file_picker` + `desktop_drop` 组合

### 3. `lib/core/widgets/`
- `adaptive_scaffold.dart`：紧凑形态用 AppBar+Drawer+BottomNav，扩展形态用 NavigationRail+侧边栏

## 改造模块

### 现有 Widget 改造（按阶段）

| 阶段 | Screen | 改动 |
|------|--------|------|
| 1 | `HomeScreen` | 紧凑模式用 Drawer，扩展模式保留侧栏 |
| 2 | `ImportScreen` | 用 `FilePickerService` 替代直接调 `file_picker` |
| 3 | `QuizScreen`、`BankDetailScreen`、`StatsScreen` | 响应式布局 |
| 4 | `BookmarksScreen`、`ImportPreviewScreen`、`ImportProgressScreen`、`ImportSummaryScreen`、`SettingsScreen` | 响应式布局 |
| 5 | `ModelManagementScreen` | Android 上禁用按钮 + 显示说明 |

### LLM 在移动端策略

- `llmClientProvider` 的现有 Android 抛 `UnsupportedError` 行为**保留**（防御性）
- 移动端导入流程**默认走启发式解析器**（`heuristic_parser.dart`），跳过 LLM 规范化
- 新增 `LlmUnsupportedBanner` 组件：用户在 Android 上进入解析页/设置页时显示
- 设置页 LLM 模式选择：Android 上禁用并显示说明

### ImportNotifier 改造

- **接口**改为接收 `PickedFile`（sealed class）而非 `String path`
- 内部 `stream.openRead()` 统一处理两种变体
- 现有 PDF/DOCX 提取器、解析器、Drift 持久化**不变**

## 数据流

```
ImportScreen.onTapPickFile
  → ref.read(filePickerServiceProvider).pickFile(extensions)
    → MobileFilePickerService: file_picker → SAF → bytes → PickedBytesFile
    → DesktopFilePickerService: file_picker → path → PickedPathFile
  → ImportNotifier.receiveFile(PickedFile)
    → PickedFile.openRead() (统一)
    → PDF/DOCX 提取器
    → heuristic_parser
    → Drift DB
```

## 错误处理

| 错误 | 处理位置 |
|------|---------|
| `FilePickerError` | `FilePickerService` 实现内映射；UI 层 `switch` 穷尽显示 SnackBar |
| `UnsupportedError`（LLM Android 调用） | UI 层根据 `PlatformInfo.supportsLlm` 避免触发；万一触发，UI 友好提示 |
| PDF/DOCX 损坏 | 现有 `ImportFailure` 路径 |
| 数据库错误 | 现有 Drift 错误处理 |

## 测试策略

### 单元测试（80%+ 覆盖）

- `PlatformInfo` 断点计算、平台检测
- `FilePickerService` Fake + Provider 切换
- `MobileFilePickerService` / `DesktopFilePickerService`（mocktail mock `file_picker`）
- `ImportNotifier` 接收 `PickedFile` 两种变体

### Widget 测试

- `ResponsiveBuilder` / `AdaptiveLayout` 三断点
- `AdaptiveScaffold` compact vs expanded
- `PlatformGuard` 禁用 fallback
- `HomeScreen` / `ImportScreen` / `ModelManagementScreen` 各形态

### 集成测试

- `integration_test/mobile_import_flow_test.dart`：选文件 → 解析 → 入库（mobile 模拟器）
- `integration_test/desktop_import_flow_test.dart`：拖放 → 解析 → 入库（桌面）
- 现有 `test/widget_test.dart` 改造支持 mobile 尺寸

## 实施阶段

5 阶段，每阶段独立可发布、桌面端零回归：

1. **地基**：PlatformInfo + Responsive + AdaptiveScaffold + PlatformGuard + Home 渲染切换
2. **文件选择抽象**：FilePickerService 接口 + Fake + Provider + 双端实现 + ImportScreen 接入
3. **核心屏响应式**：QuizScreen、BankDetailScreen、StatsScreen
4. **次要屏响应式**：BookmarksScreen、Import* 流程、SettingsScreen
5. **边缘**：ModelManagementScreen 平台门控 + LLM banner + 集成测试

## 关键不变量

1. 领域层（features + data/db + data/repositories）零平台感知
2. `ImportNotifier` 只接 `PickedFile` 抽象，不感知 SAF vs path
3. 测试中 `filePickerServiceProvider` 可被 Fake 覆盖
4. `Platform.isAndroid` 仅出现在平台适配层内部
5. 现有桌面端流程、测试、CI 不回归

## 风险与缓解

| 风险 | 缓解 |
|------|------|
| file_picker 包对 Android SAF 的兼容性 | 阶段 2 早期在模拟器验证 |
| 响应式原语粒度不对，每个屏都要重写 | 阶段 1 完成后立即用 HomeScreen 验证；不合适则扩展原语 |
| 80% 覆盖率目标 | 平台适配层纯逻辑易达 95%+；UI widget 测试覆盖主要分支 |
| 现有 `test/widget_test.dart` 失败 | 阶段 1 早期跑全套测试，建立回归基线 |
