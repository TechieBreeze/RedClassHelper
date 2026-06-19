---
phase: "02-desktop-file-import-pipeline"
verified: "2026-06-19T22:30:00Z"
status: gaps_found
score: 10/16 must-haves verified
re_verification: false
gaps:
  - truth: "编译可用——代码生成缺失"
    status: failed
    reason: "import_notifier.g.dart 文件缺失。import_notifier.dart 通过 @riverpod 注解要求代码生成（part 'import_notifier.g.dart'），但该文件不存在。Blocking——代码无法通过编译。"
    artifacts:
      - path: "lib/features/import/providers/import_notifier.dart"
        issue: "第20行引用不存在的 part 文件 import_notifier.g.dart"
      - path: "lib/features/import/providers/import_notifier.g.dart"
        issue: "文件缺失——需运行 dart run build_runner build"
    missing:
      - "运行 dart run build_runner build --delete-conflicting-outputs 生成 import_notifier.g.dart"
  - truth: "用户可编辑题库名称，含CJK感知的20字符限制（D-18）"
    status: failed
    reason: "导入预览页（ImportPreviewScreen）缺少题库名称 TextField。当前 bankName 仅由文件名自动推导（_deriveBankName），用户无法编辑，也未实现中文字符=2、ASCII=1的20字符限制。"
    artifacts:
      - path: "lib/features/import/presentation/import_preview_screen.dart"
        issue: "缺少题库名称编辑 TextField——PLAN 明确要求 'Top section: Bank name TextField (pre-filled from filename, max 20 chars with CJK mapping)'"
    missing:
      - "在 ImportPreviewScreen 顶部添加题库名称 TextField"
      - "实现 CJK 感知字符计数：中文/全角=2，ASCII=1，上限20"
      - "空名称验证：'请输入题库名称'"
  - truth: "导入总结页展示跳过题目及重试选项（D-09）"
    status: failed
    reason: "ImportSummaryScreen 仅展示成功计数和题型分布，未展示因警告被跳过的题目列表及其重试/手动编辑按钮。PLAN 明确要求 'ListView of ListTile rows: ⚠ #{index}: {reason} + 重试 TextButton + 手动编辑 TextButton'。"
    artifacts:
      - path: "lib/features/import/presentation/import_summary_screen.dart"
        issue: "缺少 skipped items 区域——无跳过题目列表、无重试按钮、无手动编辑按钮"
    missing:
      - "在 ImportSummaryScreen 添加跳过题目列表区域"
      - "为每条跳过项添加'重试'按钮（重新解析）和'手动编辑'按钮（返回预览页）"
      - "当无跳过项时隐藏该区域"
  - truth: "深链接到过期 jobId 时重定向到首页"
    status: failed
    reason: "路由守卫未实现。PLAN 要求 '/import/preview/:jobId 和 /import/summary/:jobId 在没有活跃解析任务时应重定向到 /'。当前路由无 redirect 逻辑，ImportSummaryScreen 虽有 useEffect 检查但 ImportPreviewScreen 无此防护。"
    artifacts:
      - path: "lib/routing/router.dart"
        issue: "路由重定向未实现——访问过期 /import/preview/:jobId 或 /import/summary/:jobId 不会重定向到 /"
      - path: "lib/features/import/presentation/import_preview_screen.dart"
        issue: "缺少 jobId 有效性检查——若刷新页面或直接访问此路由不会重定向"
    missing:
      - "在 router.dart 中添加 GoRouter redirect 逻辑"
      - "或在 ImportPreviewScreen 的 initState 中添加 jobId 有效性检查"
  - truth: "拖放操作提供视觉反馈覆盖层（D-03）"
    status: partial
    reason: "desktop_drop 包已集成，基本拖放功能可用。但 onDragEntered/onDragExited 为空操作回调——未实现 AnimatedContainer 虚线边框 + '释放以导入' 文字覆盖层。SUMMARY 文档承认此为已知 stub。"
    artifacts:
      - path: "lib/features/import/presentation/import_screen.dart"
        issue: "第59-62行 onDragEntered/onDragExited 为空回调——拖放悬停时无视觉反馈覆盖层"
    missing:
      - "在 DropTarget builder 中实现拖放悬停覆盖层（AnimatedContainer 虚线边框 + '释放以导入' 提示）"
  - truth: "进度页回退到格式选择页而非首页"
    status: partial
    reason: "ImportScreen 使用 context.go('/import/progress') 导航，这会替换 /import 路由而非推入。PLAN 要求 '/import/progress 推入到 /import 之上（不替换——用户可取消并返回选择其他格式）'。使用 context.push 可解决。"
    artifacts:
      - path: "lib/features/import/presentation/import_screen.dart"
        issue: "第211行 context.go() 替换了 /import 路由——应使用 context.push()"
    missing:
      - "将 ImportScreen._navigateToProgress 中的 context.go() 改为 context.push()"
      - "调整 ImportProgressScreen 取消逻辑以 pop 回 /import 而非 go('/')"
---

# Phase 02：桌面文件导入管道 验证报告

**Phase 目标：** 实现桌面端 .doc/.docx/.pdf 文件导入管线——包括文本提取、启发式解析、预览编辑、入库的完整流程。
**验证时间：** 2026-06-19T22:30:00Z
**状态：** gaps_found (6 个差距)
**验证类型：** 初次验证

---

## 目标达成情况

### 可观察真理

| # | 真理 | 状态 | 证据 |
|---|------|------|------|
| 1 | IMP-01: 桌面端选择 .docx → 解析 → 预览 → 提交 → 题库出现 | ✓ VERIFIED | docx_extractor (ZIP+XML) → heuristic_parser → ImportPreviewScreen → ImportNotifier.commitToDatabase() → drift DB 写入完整 |
| 2 | IMP-02: 桌面端选择 .pdf（文字型）→ 解析 → 预览 → 提交 | ✓ VERIFIED | pdf_extractor (pdfrx/PDFium) + ScannedPdfException/EncryptedPdfException 检测 → 与 .docx 共用解析管道 |
| 3 | IMP-01（范围外扩）：.doc 通过 pandoc 桥接 | ✓ VERIFIED | doc_extractor: pandoc CLI → 临时 .docx → docx_extractor 委托；PandocNotFoundException 含下载链接 |
| 4 | IMP-04: 解析进度 + 失败原因 + 重试 | ✓ VERIFIED | ImportProgressScreen: LinearProgressIndicator + 10秒卡住检测 + 取消确认对话框 + 错误重试；ImportState 跟踪完整状态机 |
| 5 | QST-03: 单选/多选自动检测 + 用户可覆盖 | ✓ VERIFIED | HeuristicParser: 检测答案长度（>1字母→多选）+ 判断题（✓✗×√）+ 简答题关键词；CandidateCard: SegmentedButton 允许用户切换类型 |
| 6 | UI-04: 平台分支导入页——桌面3图块、Android仅.json（禁用） | ✓ VERIFIED | ImportScreen: Platform.isWindows\|\|Platform.isLinux 分支；桌面：Word+PDF+JSON 图块；Android：仅 JSON（enabled=false, onTap: (){}） |
| 7 | 桌面端拖放支持 | ⚠️ PARTIAL | DropTarget 已集成，基本拖放有效。但悬停视觉反馈为空操作回调（已知stub） |
| 8 | 扫描/加密 PDF → 优雅错误 | ✓ VERIFIED | pdf_extractor: isEncrypted→EncryptedPdfException；逐页空文本检测→ScannedPdfException |
| 9 | 解析期间取消 → 返回首页，无残留数据 | ✓ VERIFIED | ImportProgressScreen: PopScope + AlertDialog 确认 → ImportNotifier.reset() → context.go('/') |
| 10 | 启发式解析器正确处理样本文件 | ✓ VERIFIED | heuristic_parser: 9步管道（规范化→按题号分块→题干提取→嵌入式答案→独立答案行→选项提取→类型检测→警告→过滤空题）；pipeline_integration_test 验证真实样本 |
| 11 | 完整审核往返：导入→预览→编辑→提交→计数正确 | ✓ VERIFIED | ImportPreviewScreen: CandidateCard（题型选择器+选项编辑+答案编辑+确认复选框）+ 全选/取消全选 + 题型筛选芯片；ImportSummaryScreen: 成功计数 + 题型分布 |
| 12 | 解析进度显示有意义的步骤 | ✓ VERIFIED | ImportProgressScreen: 文件图标+文件名+LinearProgressIndicator+阶段标签（"提取文本中…"/"解析中…"）+10秒"仍在处理…"提示 |
| 13 | 错误状态正确渲染 | ✓ VERIFIED | ImportProgressScreen: 错误图标+错误信息+重试/返回按钮；ImportScreen: SnackBar 提示不支持格式 |
| 14 | 题库名称默认 = 文件名 | ✓ VERIFIED | ImportNotifier._deriveBankName(): 使用 path.basenameWithoutExtension + 移除学期/修订日期后缀 |
| 15 | 编译可用 | ✗ FAILED | import_notifier.g.dart 缺失——@riverpod 代码生成未执行（详见差距） |
| 16 | 导入总结含跳过项及重试 | ✗ FAILED | ImportSummaryScreen 缺少跳过项列表（详见差距） |

**得分：** 10/16 真理已验证通过（存在部分扣分的真理按失败计算）

---

### 必要工件

| 工件 | 预期 | 状态 | 详情 |
|------|------|------|------|
| `lib/features/import/extraction/docx_extractor.dart` | .docx ZIP+XML 文本提取器 | ✓ VERIFIED | 完整实现：ZIP解压→word/document.xml→w:p/w:r/w:t遍历→过滤修订标记/域代码/空段落→段落拼接 |
| `lib/features/import/extraction/doc_extractor.dart` | .doc pandoc 桥接提取器 | ✓ VERIFIED | 完整实现：pandoc解析→临时.docx转换→docx_extractor委托→临时文件清理；PandocNotFoundException处理 |
| `lib/features/import/extraction/pdf_extractor.dart` | .pdf PDFium 文本提取器 | ✓ VERIFIED | 完整实现：pdfrx→逐页加载文本→加密检测→扫描件检测→文本拼接 |
| `lib/features/import/extraction/text_extractor.dart` | 格式路由分发器 | ✓ VERIFIED | 按扩展名分发 + UnsupportedFormatException + ArgumentError守卫 |
| `lib/features/import/parsing/heuristic_parser.dart` | 正则解析管道 | ✓ VERIFIED | 9步管道 + 5种题型检测 + 置信度评分 + 扩展文本查找 |
| `lib/features/import/parsing/parse_candidate.dart` | 解析候选模型 | ✓ VERIFIED | CandidateType枚举 + @JsonSerializable + copyWith + 元数据 |
| `lib/features/import/parsing/parse_candidate.g.dart` | JSON序列化代码生成 | ✓ VERIFIED | 完整生成的 fromJson/toJson |
| `lib/features/import/providers/import_state.dart` | 管道状态模型 | ✓ VERIFIED | 8阶段ImportPhase枚举 + ImportFile + ImportState(copyWith+便捷getter) |
| `lib/features/import/providers/import_notifier.dart` | 管道状态管理 | ✓ VERIFIED | @riverpod Notifier + 完整生命周期 + 编辑方法 + commitToDatabase |
| `lib/features/import/providers/import_notifier.g.dart` | Riverpod 代码生成 | ✗ MISSING | **文件缺失——无法编译** |
| `lib/features/import/presentation/import_screen.dart` | 平台分支入口页 | ⚠️ ORPHANED（部分） | 完整实现但拖放反馈存根 + go() push()不匹配 |
| `lib/features/import/presentation/import_progress_screen.dart` | 解析进度页 | ✓ VERIFIED | 进度条+取消+错误+10秒卡住+自动导航 |
| `lib/features/import/presentation/import_preview_screen.dart` | 预览编辑页 | ⚠️ PARTIAL | 缺少题库名称TextField + 缺少jobId有效性守卫 |
| `lib/features/import/presentation/import_summary_screen.dart` | 导入总结页 | ⚠️ PARTIAL | 缺少跳过项列表+重试按钮+手动编辑按钮 |
| `lib/features/import/widgets/file_format_tile.dart` | 文件格式图块 | ✓ VERIFIED | 可复用Card+InkWell+enabled/disabled状态 |
| `lib/features/import/widgets/candidate_card.dart` | 候选题编辑卡片 | ✓ VERIFIED | 可展开+题型SegmentedButton+选项TextFormField+答案编辑器+判断题ChoiceChip |
| `lib/core/paths.dart` | PathResolver 扩展 | ✓ VERIFIED | pandoc getter（PATH→常见路径→异常）+ tempImportDir getter |
| `lib/features/home/presentation/home_screen.dart` | 首页FAB集成 | ✓ VERIFIED | 桌面端FAB+导入题库CTA已启用+平台分支 |
| `lib/routing/router.dart` | 路由更新 | ✓ VERIFIED | 4条导入路由已注册（含:jobId参数）+ GoRouter错误构建器 |

---

### 关键链接验证

| 来源 | 目标 | 方式 | 状态 | 详情 |
|------|------|------|------|------|
| ImportScreen | FilePicker | `FilePicker.platform.pickFiles()` | ✓ WIRED | 3个格式处理器各调用正确的allowedExtensions |
| ImportScreen | ImportProgressScreen | `context.go('/import/progress')` | ⚠️ PARTIAL | 已连线但使用 go()（替换）而非 push()（推入） |
| ImportProgressScreen | ImportNotifier | `ref.read(importNotifierProvider.notifier)` | ✓ WIRED | pickFiles→extractAndParse完整调用链 |
| ImportNotifier | TextExtractor | `extractText(filePath, fileExtension:)` | ✓ WIRED | pandocResolver + tempImportDirResolver已注入 |
| ImportNotifier | HeuristicParser | `_parser.parse(allText)` | ✓ WIRED | 解析器输出填充 state.candidates |
| ImportNotifier | AppDatabase | `db.into(db.questionBanks).insert()` | ✓ WIRED | ParseJob+QuestionBank+Questions三者写入 |
| ImportPreviewScreen | CandidateCard | `CandidateCard(onToggleConfirm:, onTypeChanged:…)` | ✓ WIRED | 所有回调正确连线到ImportNotifier |
| ImportPreviewScreen | ImportSummaryScreen | `context.go('/import/summary/${state.jobId}')` | ✓ WIRED | 保存完成后自动导航 |
| HomeScreen FAB | ImportScreen | `context.go('/import')` | ✓ WIRED | FAB + 空状态CTA均已启用 |
| doc_extractor | docx_extractor | `extractDocxText(tempDocxPath)` | ✓ WIRED | pandoc转换后委托.docx提取器 |
| PandocNotFoundException | ImportNotifier | `on PandocNotFoundException` catch | ✓ WIRED | 错误信息含 pandoc.org 下载链接 |
| DropTarget | ImportScreen | `onDragDone: (details)` | ✓ WIRED | 拖放验证+导航已连线 |

---

### 数据流追踪（第4级）

| 工件 | 数据变量 | 来源 | 是否产生真实数据 | 状态 |
|------|----------|------|------------------|------|
| ImportPreviewScreen | candidates | ImportNotifier.extractAndParse()→HeuristicParser.parse()→text_extractor | ✓ FLOWING | 真实文件→真实文本→解析→渲染候选。完整数据流。 |
| ImportSummaryScreen | state.committedCount | ImportNotifier.commitToDatabase()→drift INSERT计数 | ✓ FLOWING | DB写入返回确认数量。 |
| ImportProgressScreen | state.progress | ImportNotifier.extractAndParse()→进度更新（0→0.5→0.6→1.0） | ✓ FLOWING | 分阶段真实进度值。 |
| CandidateCard | candidate (props) | ImportPreviewScreen→ImportNotifier state.candidates[index] | ✓ FLOWING | 完整候选数据通过props传入。 |

---

### 行为点检

| 行为 | 命令 | 结果 | 状态 |
|------|------|------|------|
| 提取器模块导入 | `dart analyze lib/features/import/extraction/` | 需完整构建——跳过 | ? SKIP |
| 解析器模块导入 | `dart analyze lib/features/import/parsing/` | 需完整构建——跳过 | ? SKIP |
| pubspec依赖声明 | `grep -c "archive:\|xml:\|pdfrx:\|file_picker:\|desktop_drop:\|uuid:" pubspec.yaml` | 6/6 依赖存在 | ✓ PASS |
| 样本文件就位 | `ls doc/example/*.docx doc/example/*.doc doc/example/*.pdf` | 全部4个样本存在 | ✓ PASS |

> **注意：** 由于 `import_notifier.g.dart` 缺失，无法运行 `flutter analyze` 或 `flutter test`。完整点检需在代码生成修复后执行。

---

### 需求覆盖率

| 需求ID | 来源计划 | 描述 | 状态 | 证据 |
|--------|----------|------|------|------|
| IMP-01 | PLAN L22 | 桌面端 .docx 导入 | ✓ SATISFIED | docx_extractor + heuristic_parser + ImportPreviewScreen + commitToDatabase |
| IMP-02 | PLAN L23 | 桌面端 .pdf 导入 | ✓ SATISFIED | pdf_extractor(pdfrx) + ScannedPdfException + EncryptedPdfException |
| IMP-04 | PLAN L24 | 解析进度 + 失败原因 + 重试 | ✓ SATISFIED | ImportProgressScreen(进度+取消+错误重试) + ImportState 完整状态机 |
| QST-03 | PLAN L25 | 单选/多选标识 | ✓ SATISFIED | HeuristicParser 自动检测 + CandidateCard SegmentedButton 用户覆盖 |
| UI-04 | PLAN L26 | 平台分支导入页 | ✓ SATISFIED | ImportScreen 桌面3图块 + Android仅.json(禁用) + FAB平台条件渲染 |

**覆盖率：** 5/5 需求已满足 ✅

---

### 反模式扫描

| 文件 | 行 | 模式 | 严重级别 | 影响 |
|------|-----|------|----------|------|
| `import_screen.dart` | 59-62 | `onDragEntered: (_) {}`, `onDragExited: (_) {}` — 空回调存根 | ⚠️ 警告 | 拖放无视觉反馈；已在SUMMARY中记录为已知存根 |
| `import_screen.dart` | 155 | `onTap: () {}` — Android .json 图块禁用 | ℹ️ 信息 | 符合 Phase 5 延迟策略的预期存根 |
| `import_screen.dart` | 211 | `context.go()` 代替 `context.push()` — 导航栈被替换 | ⚠️ 警告 | 用户取消后无法返回格式选择页（见差距 #6） |
| `import_notifier.dart` | 20 | `part 'import_notifier.g.dart'` 引用缺失文件 | 🛑 阻断 | **阻断——代码无法编译**（见差距 #1） |
| `doc_extractor.dart` | 58 | `Process.run(…, runInShell: true)` — shell执行 | ⚠️ 警告 | SUMMARY 已标记为 threat_flag: process-exec；Phase 3 修复 |
| `import_progress_screen.dart` | 54 | `File.statSync()` — 同步文件IO | ⚠️ 警告 | SUMMARY 已标记为 threat_flag: file-access；大文件可能阻塞UI |

---

### 需人工验证

| # | 测试 | 预期 | 为何需人工 |
|---|------|------|-----------|
| 1 | **文件选择器原生对话框** | 点击桌面端 Word/PDF/JSON 图块 → 系统文件对话框打开，过滤正确（.docx,.doc / .pdf / .json） | file_picker 使用平台通道，widget测试无法模拟 |
| 2 | **从 Windows 资源管理器拖放** | 将 .docx 拖入应用窗口 → 覆盖层出现（虚线边框+"释放以导入"）→ 释放 → 解析开始 | desktop_drop 平台通道无法在 widget 测试中完整模拟 |
| 3 | **Pandoc 安装检测** | pandoc 已安装：.doc 图块正常工作。pandoc 未安装：显示下载链接错误信息 | pandoc 是否存在取决于开发环境 |
| 4 | **扫描 PDF 优雅错误** | 选择扫描 PDF（纯图片无文字层）→ 显示"此 PDF 为扫描件，v1 暂不支持 OCR" | 需真实扫描 PDF 文件进行测试 |
| 5 | **加密 PDF 优雅错误** | 选择有密码保护的 PDF → 显示"PDF 已加密，请先解密后再导入" | 需真实加密 PDF 文件进行测试 |
| 6 | **导入期间 UI 响应性** | 50k 字符文件导入期间 UI 不掉帧（每帧 < 16ms） | 需以发布模式运行并肉眼观察/使用性能叠加层 |
| 7 | **中文文件名支持** | 文件名含中文/括号/书名号时整个管道正常工作 | 样本文件已含此类文件名，但需在真实应用中端到端验证 |
| 8 | **Android .json 图块禁用状态** | Android 设备上 ImportScreen 仅显示.json图块，灰显且不可交互 | 需 Android 设备或模拟器进行验证 |

---

### 差距摘要

发现 **6 个差距**，其中 **1 个阻断级**，**3 个功能缺失**，**2 个部分实现**：

1. **🛑 阻断：import_notifier.g.dart 缺失** — `@riverpod` 注解要求代码生成，但生成文件不存在。项目无法编译。**修复：** 运行 `dart run build_runner build --delete-conflicting-outputs`。

2. **功能缺失：题库名称编辑 + CJK 20字符限制（D-18）** — ImportPreviewScreen 不提供题库名称 TextField。用户无法编辑自动推导的名称，也未实现中文字符=2字符的20字符限制。

3. **功能缺失：导入总结跳过项（D-09）** — ImportSummaryScreen 不展示因警告被跳过的题目，也无重试/手动编辑按钮。

4. **功能缺失：路由守卫** — 访问过期 `/import/preview/:jobId` 或 `/import/summary/:jobId` 时不会重定向到首页。

5. **部分实现：拖放视觉反馈** — 拖放悬停时的覆盖层视觉反馈仅为空操作存根。

6. **部分实现：导航栈管理** — ImportScreen 使用 `context.go()`（替换）而非 `context.push()`（推入），用户取消后无法返回格式选择页。

---

*验证完成：2026-06-19T22:30:00Z*
*验证者：Claude (gsd-verifier)*
