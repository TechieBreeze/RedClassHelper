# Research: Phase 2 — Desktop File Import Pipeline

**Researched:** 2026-06-19
**Confidence:** HIGH (文件格式分析、文本提取策略、正则解析器设计) / MEDIUM (.doc 二进制格式处理路径选择)

---

## 1. 样本文件格式分析

### 1.1 样本清单 (`doc/example/`)

| 文件 | 格式 | 大小 | 编码 |
|------|------|------|------|
| `习近平新时代中国特色社会主义思想概论题库（2026年春季学期）5月28日修订.docx` | OOXML (.docx) | 120 KB | UTF-8 (WordprocessingML) |
| `《纲要》选择题（2026年5月最新修订版）.pdf` | PDF | 2.4 MB | 文本层 PDF (非扫描件) |
| `《毛概》题库-2025-2026（二）(1).doc` | Word 97-2003 二进制 (.doc) | 210 KB | OLE2 Compound Document |
| `思想道德与法治题库2026年1月版.doc` | Word 97-2003 二进制 (.doc) | 161 KB | OLE2 Compound Document |

### 1.2 .docx 格式分析（已实际解包验证）

**结构**: ZIP 容器，核心内容在 `word/document.xml`。

**题目格式**（从实际样本提取）：
```
1. 题干文字内容……是（D）
A. 选项一
B. 选项二
C. 选项三
D. 选项四
```

**关键特征**:
- 题号：数字 + `.` 开头（`1.`、`2.`...），连续递增
- 题干：以 `（X）` 结尾，括号内为正确答案字母
- 选项：`A.` / `B.` / `C.` / `D.` 开头（注意是英文句点 `.` 不是中文顿号 `、`）
- 选项之间无换行符——在 WordprocessingML 中以 `<w:r>` 元素序列表示（同段落）
- 题目之间**没有**显式段落分隔——连续 `<w:p>` 元素，每段可以是一道题
- 样本为纯文本，无图片、表格、公式

**WordprocessingML 遍历要点**:
- `<w:p>` = 段落 → 映射到一道题或一个题干+选项块
- `<w:r>` / `<w:t>` = 文本运行 → 实际文字内容
- 需要处理 `<w:rPr>` 中的格式标记（加粗、字号等），但对文本提取来说可忽略
- `xml:space="preserve"` 属性保留空格
- 段落内可能有多个 `<w:r>` 元素（如题干一部分加粗、一部分正常）

### 1.3 .pdf 格式分析

**样本特征**: 文本层 PDF（非扫描件），2.4 MB，内容可被直接提取。

**pdfx 提取策略**:
- `pdfx` 通过 PDFium 逐页提取文本
- `PdfDocument.openFile(path)` → `document.pages` → `page.text` 获取每页文本
- 文本保持原始排版（空格、换行），但不保留段落结构
- 可能出现：选项 `A.` 和选项文本被换行分隔、题号单独成行

**PDF 文本后处理需求**:
- 合并被 PDF 换行截断的行（检测行尾是否以 `A.`-`D.` 或数字开头来判断连续）
- 题干可能跨多行
- 答案标记可能在题干末尾或独立一行

### 1.4 .doc 格式分析与处理路径

**.doc 格式本质**: OLE2 Compound Document Binary (CFB)。这是 Microsoft 专有的二进制复合文档格式。

**处理路径评估**:

| 路径 | 可行性 | 复杂度 | 推荐度 |
|------|--------|--------|--------|
| **Path A: pandoc CLI 转换** | ✅ 高 | 低 | ★★★★★ 推荐 |
| **Path B: LibreOffice headless** | ✅ 高 | 中 | ★★★★ 备选 |
| **Path C: 纯 Dart OLE2 解析** | ❌ 不可行 | 极高 | ☆ 不推荐 |
| **Path D: NPOI 封装 (.NET)** | ⚠️ Windows Only | 高 | ★ 仅限极端情况 |

**推荐路径: pandoc CLI (Path A)**

原因：
1. `pandoc` 是事实标准的文档转换工具，支持 `.doc` → `.docx` / `.txt` / `.md` 转换
2. Windows / Linux 均有预编译二进制
3. 命令行调用简单：`pandoc input.doc -t plain -o output.txt`
4. 通过 `Process.run()` 在 Dart 中调用，无需 FFI
5. 转换后的纯文本可用与 `.docx` 相同的正则解析器处理

**pandoc 部署方案**:
- Windows: 打包时附带 `pandoc.exe`（~50 MB，可用精简版 ~20 MB）
- Linux: 要求用户安装 `pandoc`（`apt install pandoc` / `dnf install pandoc`）
- 应用启动时检测 `pandoc --version`，不可用时提示安装
- 备选：pandoc 不可用时提示用户手动将 `.doc` 另存为 `.docx`

**备选路径: LibreOffice headless (Path B)**:
- `soffice --headless --convert-to txt input.doc`
- Linux 上 LibreOffice 通常已安装；Windows 需用户自行安装
- 转换质量与 pandoc 相当，但启动开销更大（~3-5秒冷启动）

**.doc → 统一管道**:
```
.doc 文件 → pandoc → 纯文本 → 与 .docx/.pdf 相同的正则解析器管道
```

---

## 2. 文本提取策略（按格式）

### 2.1 .docx 文本提取：`archive` + `xml`

```
.docx (ZIP)
  → archive.ZipDecoder().decodeBytes(bytes)
  → 定位 word/document.xml entry
  → xml.XmlDocument.parse(xmlString)
  → 遍历 <w:p> 元素
  → 每个 <w:p> 内收集所有 <w:t> 文本
  → 输出: List<String> (每段一个字符串)
```

**注意事项**:
- 使用 `archive` 4.0.9 的同步 API（`ZipDecoder().decodeBytes()`）
- `xml` 6.5.0 使用 DOM 解析（小文件）或 `XmlPullParser`（大文件）
- 120KB 的 .docx 用 DOM 完全足够；若遇到 5MB+ 文件可切流式
- 忽略 `<w:instrText>`（域代码/公式）、`<w:delText>`（修订删除文本）
- `<w:br/>` 和 `<w:cr/>` 映射为换行符
- 软回车 (`<w:br w:type="textWrapping"/>`) vs 硬回车：两者都映射为 `\n`

### 2.2 .pdf 文本提取：`pdfx` + PDFium

```
pdf 文件
  → PdfDocument.openFile(filePath)
  → for page in document.pages:
       page.text → 追加到全文
  → 输出: String (全文)
```

**pdfx 安装步骤（一次性）**:
```bash
flutter pub add pdfx
flutter pub run pdfx:install_windows  # 自动修改 CMakeLists.txt
```

**PDF 文本后处理**:
- 合并跨页断行（上一页最后一行 + 下一页第一行 → 检查是否属于同一题）
- 规范化空白（多个空格 → 单个空格）
- 检测扫描件：若 `document.pages.length > 0` 但所有 `page.text` 都为空 → 报错"PDF 为扫描件，不支持 OCR"

### 2.3 .doc 文本提取：pandoc CLI

```dart
final result = await Process.run('pandoc', [
  inputPath,
  '-f', 'doc',      // 或 auto-detect: 省略 -f
  '-t', 'plain',    // 输出纯文本
  '-o', outputPath, // 临时文件
]);
```

**pandoc 检测**:
```dart
Future<bool> get isPandocAvailable async {
  try {
    final result = await Process.run('pandoc', ['--version']);
    return result.exitCode == 0;
  } catch (_) {
    return false;
  }
}
```

### 2.4 通用文本提取接口设计

```dart
/// 文件 → 纯文本的抽象
abstract class TextExtractor {
  /// 从文件路径提取纯文本，返回段落列表
  Future<ExtractResult> extract(String filePath);
}

class ExtractResult {
  final String fullText;
  final List<String> paragraphs;
  final String detectedEncoding;
  final Duration elapsed;
}
```

三种实现：`DocxExtractor`、`PdfExtractor`、`DocExtractor`（通过 pandoc）

---

## 3. 启发式正则解析器设计

### 3.1 题目结构模型（从实际样本归纳）

```
[题号]. [题干内容]……（[正确答案]）
A. [选项A文本]
B. [选项B文本]
C. [选项C文本]
D. [选项D文本]
```

### 3.2 正则表达式设计

**Step 1: 题目分块** — 按题号切分原文

```dart
// 匹配题号开头：数字 + . 或 、
final questionSplitter = RegExp(
  r'(?:^|\n)\s*(\d+)[.、]\s*',
  multiLine: true,
);
```

**Step 2: 题干 + 答案提取** — 从题块中提取题干和嵌入式答案

```dart
// 匹配题干末尾的答案标记: （X）或 (X) 其中 X 为 A-D 单字母或多字母
final answerInStem = RegExp(
  r'[（(]\s*([A-D]+)\s*[）)]\s*$',
  multiLine: true,
);
```

**Step 3: 选项提取** — 从题块中提取选项

```dart
// 匹配选项行: A. 或 A、 或 (A) 开头
final optionLine = RegExp(
  r'^\s*[A-D][.、）)]\s*(.+)$',
  multiLine: true,
);
```

**Step 4: 答案独立行检测** — 处理"答案：X"模式

```dart
// 匹配独立答案行
final answerLine = RegExp(
  r'^\s*答案[：:]\s*([A-D]+)\s*$',
  multiLine: true,
);
```

### 3.3 解析流程（完整 pipeline）

```
纯文本
  → Step 1: 按题号切分为 List<String>（每块一道题）
  → Step 2: 对每块：
       a. 移除题号前缀
       b. 尝试从题干末尾提取 （X） → correct_answer
       c. 若无嵌入答案，尝试独立"答案：X"行
       d. 提取 A/B/C/D 选项行
       e. 剩余文本为题干 stem
  → Step 3: 验证
       a. options 数量 ∈ {3,4,5,6}（支持A-D/A-E/A-F）
       b. correct_answer 每个字母 ∈ options 的 key 集合
       c. stem 非空
       d. 题型判定：correct_answer.length == 1 → 'single'；> 1 → 'multiple'
  → Step 4: 输出 List<ParsedQuestion>
```

### 3.4 ParsedQuestion 数据结构

```dart
class ParsedQuestion {
  final int orderIndex;          // 在原文中的顺序
  final String stem;             // 题干纯文本
  final List<Option> options;    // 选项列表
  final List<String> correct;    // 正确答案字母列表 ["A"] 或 ["A","C"]
  final String type;             // 'single' | 'multiple'
  final String rawText;          // 原始题块文本（用于调试/重放）
  final String? parseWarning;    // 解析警告（非致命问题）
}

class Option {
  final String key;   // "A" / "B" / "C" / "D"
  final String text;  // 选项文本（去掉"A."前缀）
}
```

### 3.5 边界情况处理

| 场景 | 策略 |
|------|------|
| 题号后有空格/换行 | `trim()` + multiline regex |
| 选项跨行（PDF 常见） | 预处理：检测非选项开头的行，合并到上一选项 |
| 题干含 `（` 但不是答案 | 检测 `（X）` 仅限于行尾，且 X 是 A-D |
| 只有选项无题干 | 标 `parseWarning: "题干缺失"`，用户可编辑 |
| 无法检测答案 | 标 `type='unknown'`，解析完成后让用户手动标注 |
| 选项数量异常（<2或>8） | 标 `parseWarning`，仍保留让用户判断 |
| 超长选项文本（>2000字） | 截断前 500 字符预览，`parseWarning` |
| 题目中有嵌套编号 | 先用 `questionSplitter` 粗切，再用 `optionLine` 细分 |
| 多选答案（AB、ABC）| `correct = "AB".split('').toList()` → `["A","B"]` |

### 3.6 预期准确率

基于实际样本分析：
- **题干提取**: ~95%+ — 中文数字题号 + 选项结构清晰
- **答案提取（嵌入式）**: ~90%+ — `（X）` 模式高度一致
- **答案提取（独立行）**: ~85%+ — "答案：X" 变体较少
- **选项提取**: ~95%+ — A./B./C./D. 格式稳定
- **综合端到端**: ~70-85%（与 ROADMAP 中 70% 目标一致）

不准确的主要来源：
1. 题干中存在干扰性 `（X）` 模式（如"以下哪项是（A）TCP的特点"）
2. PDF 换行导致题干/选项错位
3. 选项中出现罗马数字/嵌套编号
4. `.doc` 通过 pandoc 转换后的格式变形

---

## 4. Isolate 解析管道设计

### 4.1 架构

```
UI isolate                    Background isolate
──────────                    ─────────────────
ImportProvider                ParseIsolate
  │                              │
  │── startParse(filePath) ──→   │── TextExtractor.extract()
  │                              │── QuestionParser.parse()
  │←── progress stream ──────   │── ParseJob status update
  │←── result stream ────────   │
  │                              │
```

### 4.2 通信协议

使用 `Isolate.spawn` + `SendPort` / `ReceivePort`:

```dart
// 主 isolate → 工作 isolate
class ParseRequest {
  final String filePath;
  final String jobId;
  final SendPort progressPort;
}

// 工作 isolate → 主 isolate
sealed class ParseMessage {}
class ParseProgress extends ParseMessage {
  final double progress;   // 0.0 - 1.0
  final int parsedCount;
  final int totalEstimate;
}
class ParseComplete extends ParseMessage {
  final List<ParsedQuestion> questions;
  final ParseStats stats;
}
class ParseError extends ParseMessage {
  final String error;
  final bool isRetryable;
}
```

### 4.3 进度估算

- 文本提取阶段：10% 进度（1-2秒 for 120KB .docx）
- 解析阶段：80% 进度（按题号估算总数，每题 0.01-0.05 秒）
- 验证阶段：10% 进度

50k 字符的导入预计总耗时 < 5 秒（满足 ROADMAP "不超过一帧"的要求）

### 4.4 取消机制

```dart
class ParseIsolate {
  final CancellationToken _cancelToken = CancellationToken();
  
  void cancel() {
    _cancelToken.cancel();
    // 更新 ParseJob.status = 'cancelled'
  }
  
  Future<void> parse(ParseRequest req) async {
    for (final chunk in chunks) {
      if (_cancelToken.isCancelled) return;
      // ... parse chunk
    }
  }
}
```

---

## 5. UI 流程设计

### 5.1 屏幕清单

| 屏幕 | 路由 | 用途 |
|------|------|------|
| ImportScreen（重构） | `/import` | 平台分支入口（桌面：.docx/.pdf/.doc/.json；Android：.json only） |
| ImportProgressScreen | `/import/progress` | 解析进度显示 |
| ImportPreviewScreen | `/import/preview` | 解析结果预览、编辑、删除 |
| ImportSummaryScreen | `/import/summary` | 导入完成总结 |

### 5.2 ImportScreen 平台分支

```
桌面端 (Windows/Linux)            Android
┌─────────────────────┐      ┌─────────────────────┐
│ 导入题库             │      │ 导入题库             │
│                     │      │                     │
│ 📄 .docx 题库       │      │ 📄 .json 题库       │
│ 📄 .doc 题库        │      │  (Phase 5 实现)     │
│ 📕 .pdf 题库        │      │                     │
│ 📋 .json 题库       │      │                     │
│                     │      │                     │
│ 或拖放文件到窗口     │      │                     │
└─────────────────────┘      └─────────────────────┘
```

**分支判断**: `Platform.isWindows || Platform.isLinux`

### 5.3 ImportPreviewScreen 设计

```
┌─────────────────────────────┐
│ ← 返回    预览 (47/120)    │
├─────────────────────────────┤
│ 题库名称: [自动填充文件名]   │
│                             │
│ ┌─ 题目 #1 ─────────[✕]─┐  │
│ │ 单选 [✓] 多选 [ ]      │  │
│ │ 题干: [可编辑]          │  │
│ │ A. [可编辑]            │  │
│ │ B. [可编辑]            │  │
│ │ C. [可编辑]            │  │
│ │ D. [可编辑]            │  │
│ │ 答案: [A] [B] [C] [D]  │  │
│ └─────────────────────────┘  │
│                             │
│ [全部保留]  [仅保留有效题目]  │
│ [提交到题库]                 │
└─────────────────────────────┘
```

### 5.4 ImportSummaryScreen 设计

```
┌───────────────────────────────┐
│ ✓ 导入完成                    │
├───────────────────────────────┤
│ 题库: 2026思修题库             │
│                               │
│ ✅ 成功导入: 118 题            │
│ ⚠ 跳过: 2 题                 │
│    #47: 答案格式异常           │
│       [重试] [手动编辑]       │
│    #83: 题干缺失              │
│       [重试] [手动编辑]       │
│                               │
│ [开始复习]  [返回首页]        │
└───────────────────────────────┘
```

### 5.5 拖放支持（桌面端）

```dart
// 使用 DragTarget widget 包裹整个 ImportScreen
DragTarget<String>(
  onAcceptWithDetails: (details) {
    final filePath = details.data;
    // 验证扩展名
    if (isValidImportFile(filePath)) {
      _startImport(filePath);
    }
  },
  builder: (context, candidateData, rejectedData) {
    // 拖放悬停时显示视觉反馈（高亮边框 + "释放以导入"提示）
    return AnimatedContainer(
      decoration: candidateData.isNotEmpty
        ? BoxDecoration(border: Border.all(color: theme.colorScheme.primary, width: 2))
        : null,
      child: /* ImportScreen body */,
    );
  },
)
```

**Windows 文件拖放注册**: Flutter 桌面端 `DragTarget` 原生支持文件拖放，无需额外平台通道。

---

## 6. 集成点：Phase 1 现有代码

### 6.1 已就绪的资源

| 资源 | 路径 | 用途 |
|------|------|------|
| PathResolver | `lib/core/paths.dart` | `cacheDir` 存 pandoc 临时文件；`tempDir` 存解析中临时文件 |
| ParseJobs 表 | `lib/data/db/tables/parse_jobs.dart` | 解析任务状态机（pending→running→succeeded/failed/cancelled） |
| QuestionBanks 表 | `lib/data/db/tables/question_banks.dart` | 存储导入的题库元数据 |
| Questions 表 | `lib/data/db/tables/questions.dart` | 存储解析后的题目（stem, options_json, correct_json, raw_text, type） |
| AppDatabase | `lib/data/db/database.dart` | drift ORM，含 `appDatabaseProvider` Riverpod provider |
| GoRouter | `lib/routing/router.dart` | `/import` 路由 → ImportScreen |
| ImportScreen 占位 | `lib/features/import/presentation/import_screen.dart` | 需要完整重写 |
| HomeScreen | `lib/features/home/presentation/home_screen.dart` | 含 FAB 占位、`_BankEmptyStateCard`（Card tap → `/import`） |
| Material 3 主题 | `lib/core/theme.dart` | `buildAppTheme` / `buildDynamicTheme` |

### 6.2 需要创建的新文件

```
lib/features/import/
├── presentation/
│   ├── import_screen.dart          (重写：平台分支入口)
│   ├── import_progress_screen.dart (新建：解析进度)
│   ├── import_preview_screen.dart  (新建：预览编辑)
│   └── import_summary_screen.dart  (新建：导入总结)
├── providers/
│   ├── import_provider.dart        (新建：导入流程状态管理)
│   └── import_provider.g.dart
├── widgets/
│   ├── question_edit_card.dart     (新建：单题编辑卡片)
│   └── file_format_tile.dart       (新建：文件类型入口卡片)
├── domain/
│   ├── text_extractor.dart         (新建：TextExtractor 接口)
│   ├── docx_extractor.dart         (新建：archive + xml)
│   ├── pdf_extractor.dart          (新建：pdfx)
│   ├── doc_extractor.dart          (新建：pandoc CLI)
│   ├── question_parser.dart        (新建：正则解析器)
│   └── parsed_question.dart        (新建：ParsedQuestion 模型)
└── services/
    └── parse_isolate.dart           (新建：Isolate 管理)
```

### 6.3 数据库操作

导入完成后的数据库写入需要一个 **Repository** 层来管理事务：

```dart
class ImportRepository {
  final AppDatabase _db;
  
  Future<QuestionBank> commitImport({
    required String name,
    required String sourcePath,
    required List<ParsedQuestion> questions,
    required String parseJobId,
  }) async {
    return await _db.transaction(() async {
      // 1. 创建 QuestionBank
      final bankId = await _db.into(_db.questionBanks).insert(...);
      // 2. 批量创建 Questions
      await _db.batch((batch) {
        for (final q in questions) {
          batch.insert(_db.questions, QuestionsCompanion(...));
        }
      });
      // 3. 更新 ParseJob 状态
      await _db.update(_db.parseJobs).replace(...);
      return bank;
    });
  }
}
```

**批量插入性能**: drift 的 `batch` API 可在单个事务中批量插入。120 道题的批量写入预计 < 50ms（SQLite WAL 模式）。

### 6.4 路由设计

```dart
// 新增路由
GoRoute(
  path: '/import/preview/:jobId',
  builder: (context, state) => ImportPreviewScreen(
    jobId: state.pathParameters['jobId']!,
  ),
),
GoRoute(
  path: '/import/summary/:bankId',
  builder: (context, state) => ImportSummaryScreen(
    bankId: state.pathParameters['bankId']!,
  ),
),
```

---

## 7. 错误处理矩阵

| 错误条件 | 检测方式 | 处理 |
|----------|----------|------|
| 文件不存在 | `File.exists()` | Toast "文件已被移动或删除" |
| 文件大小为 0 | `File.length()` | Toast "文件为空" |
| 不支持的文件类型 | 扩展名检查 | Toast "不支持的文件格式，请选择 .doc/.docx/.pdf/.json" |
| .docx 损坏（非ZIP）| `ZipDecoder` 异常 | "文件已损坏，无法打开" |
| .docx 无 document.xml | entry 缺失 | "文件结构不完整" |
| PDF 为扫描件 | `page.text` 全部为空 | "此 PDF 为扫描件，v1 暂不支持 OCR。请使用文字型 PDF" |
| PDF 加密 | pdfx `PdfDocument.openFile` 抛异常 | "PDF 已加密，请先解密" |
| pandoc 不可用 (.doc) | `Process.run` 失败 | "需要安装 pandoc 来导入 .doc 文件。下载地址：pandoc.org" + 备选：提示用户另存为 .docx |
| pandoc 转换失败 | exitCode ≠ 0 | "文件转换失败，请尝试将 .doc 另存为 .docx 后导入" |
| 解析出 0 题 | `questions.isEmpty` | "未能从文件中识别出题目，可能格式不匹配" |
| 解析部分失败 | `questions.where(warn != null)` | 预览页标黄，导入总结页列出 |
| Isolate 崩溃 | `ReceivePort` 关闭 / 超时 | "解析进程异常终止，请重试" |
| 磁盘空间不足 | `FileSystemException` | "磁盘空间不足，无法完成导入" |
| 文件名含特殊字符 | 路径规范化 | 使用 `path` 包的 `basenameWithoutExtension` 提取题库名 |
| 超大文件（>50MB） | 文件大小预检 | "文件过大，建议拆分为多个文件后导入" |

---

## 8. 测试策略

### 8.1 单元测试

| 测试目标 | 测试内容 | 数据来源 |
|----------|----------|----------|
| `QuestionParser` | 用真实样本的文本片段验证解析准确率 | `doc/example/` 中提取的文本 |
| `DocxExtractor` | 验证能从 .docx 提取完整段落列表 | `doc/example/` 中的 .docx |
| `PdfExtractor` | 验证能从 PDF 提取文本 | `doc/example/` 中的 .pdf |
| `DocExtractor` | 验证 pandoc 检测逻辑（模拟 pandoc 可用/不可用） | mock `Process.run` |
| `ParseIsolate` | 验证 Isolate 通信（progress/completion/error 消息） | 合成数据 |
| `ImportRepository` | 验证事务写入（bank + questions 原子性） | 合成 ParsedQuestion 列表 |

### 8.2 Widget 测试

| Widget | 测试 |
|--------|------|
| `ImportScreen` | 桌面/Android 入口分支正确渲染 |
| `ImportPreviewScreen` | 编辑/删除/全部保留/提交按钮交互 |
| `ImportSummaryScreen` | 成功/跳过统计显示正确 |
| `QuestionEditCard` | stem/options/correct 可编辑 |
| `FileFormatTile` | 各格式入口 onTap 触发文件选择 |

### 8.3 集成测试

- 端到端：选文件 → 提取文本 → 解析 → 预览 → 提交 → DB 验证
- 跨平台：Windows / Linux 上各跑一次完整流程
- 中文路径：文件名含中文/括号/空格时流程正常

---

## 9. 依赖清单

### 9.1 新增 pub 依赖

```yaml
dependencies:
  archive: ^4.0.9     # ZIP 解压 (.docx)
  xml: ^6.5.0          # WordprocessingML 解析
  pdfx: ^2.9.2         # PDF 文本提取 (PDFium)
  # file_picker 已存在于现有 pubspec.yaml
  
dev_dependencies:
  # 现有依赖足够，无需新增
```

### 9.2 系统依赖

| 依赖 | 平台 | 用途 | 部署方式 |
|------|------|------|----------|
| PDFium | Windows | pdfx 的 PDF 渲染引擎 | `flutter pub run pdfx:install_windows`（自动修改 CMakeLists） |
| pandoc | Windows/Linux | .doc 格式转换 | Windows: 打包附带；Linux: 文档提示安装 |

---

## 10. 风险与缓解

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|----------|
| `.doc` pandoc 转换质量不稳定 | 中 | 解析准确率下降 | 备选：提示用户手动另存为 .docx；支持手动粘贴纯文本 |
| PDF 文本层格式变异（跨行断题） | 中 | 题干/选项错位 | 预览编辑界面允许手动修正；保留 raw_text 供重解析 |
| 中文题号格式多样（一、/ 1./ 1、/ (1)）| 高 | 默认 regex 漏题 | 支持多种题号模式，提供可扩展的题号检测器 |
| 大文件内存峰值 | 低 | 低端设备 OOM | 流式处理 + 文件大小预检（>50MB 警告）|
| Isolate 通信复杂度过高 | 低 | 开发周期延长 | 先从简单的 `compute()` 开始，确有需要再升级完整 Isolate |

---

## 11. 开放决策（供 Planner 处理）

以下问题在 Research 阶段识别为需要 Planner 决策：

1. **ImportRepository 位置**：放在 `lib/data/repositories/` 还是 `lib/features/import/domain/`？CONTEXT.md 建议"planner 决定是在 `lib/data/` 下加 repository 还是直接在 feature 内操作 drift DAO"

2. **路由设计**：`/import/preview` 是嵌套在 `/import` 下还是独立路由？状态如何跨路由传递（jobId 通过 URL 参数 vs provider 共享）？

3. **FAB 图标选择**：CONTEXT.md D-01 将 FAB 作为主入口，但 Claude's Discretion 允许选择图标。Material Icons 中 `upload_file` / `file_open` / `add` 等候选

4. **拖放视觉反馈**：CONTEXT.md 要求桌面端支持拖放，但未指定具体视觉样式

5. **pandoc 打包策略**：Windows 打包时 pandoc 是内嵌（打包体积 +20MB）还是提示用户自行安装？

6. **Android 导入页占位**：Phase 2 只在 Android 端放 FAB + `.json` 占位入口；Phase 5 实现 JSON 导入。Android 的 `.json` 入口的 UI 细节（list tile 样式、禁用态 etc.）

---

## 12. 面向 Planner 的 Plan 推荐

基于以上研究，推荐以下 Plan 结构（与 ROADMAP 的 8 个计划对齐但细化实现策略）：

1. **02-01: 文件选取入口 + FAB 集成** — HomeScreen FAB，系统文件选择器，扩展名过滤，拖放支持
2. **02-02: .docx 文本提取** — `archive` + `xml` WordprocessingML 遍历器 + 单元测试（用真实 .docx 样本）
3. **02-03: .pdf 文本提取** — `pdfx` PDFium 集成，扫描件检测，pdfx:install_windows
4. **02-04: .doc 文本提取 (pandoc)** — pandoc 可用性检测，`Process.run` 封装，转换管道
5. **02-05: 启发式正则解析器** — 题号切分、答案提取、选项提取、题型判定、验证层
6. **02-06: Isolate 解析管道 + DB 持久化** — `ParseIsolate` 封装，progress stream，`ImportRepository` 事务写入
7. **02-07: 导入预览/编辑界面** — 题目列表、编辑/删除、批量操作、提交确认
8. **02-08: 平台条件导入页 + 导入总结** — 平台分支渲染、Android 占位、导入总结屏幕

---

## 13. 验证架构（Nyquist Dimension 8）

### 13.1 关键验证点

| 验证维度 | 验证方法 | 通过标准 |
|----------|----------|----------|
| 文本提取完整性 | 对 4 份样本文件各运行提取器，对比提取字符数与原文 | 提取字符数 ≥ 原文有效字符的 95% |
| 解析准确率 | 对 4 份样本各运行解析器，人工核验 | 端到端准确率 ≥ 70%（ROADMAP 目标） |
| Isolate 不阻塞 UI | 50k 字符文件导入时监控 UI 帧率 | UI 不掉帧（每帧 < 16ms） |
| 事务原子性 | 模拟写入中途崩溃，重启检查 DB | 零脏数据 |
| 平台分支正确 | 桌面端/Android 端导入页渲染检查 | 桌面端显示 4 个入口，Android 显示 1 个 |

### 13.2 样本文件测试矩阵

| 样本文件 | 格式 | 预期题数（预估） | 解析器测试 | 提取器测试 |
|----------|------|------------------|-----------|-----------|
| 习近平思想题库.docx | .docx | ~50 题 | ✅ | ✅ |
| 纲要选择题.pdf | .pdf | ~100 题 | ✅ | ✅ |
| 毛概题库.doc | .doc | ~80 题 | ✅ | ✅ |
| 思修题库.doc | .doc | ~60 题 | ✅ | ✅ |

---

*Research complete: Phase 02 — Desktop File Import Pipeline*
*Researched: 2026-06-19*
