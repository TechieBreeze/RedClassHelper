# Architecture Research — RedClass

**Domain:** Local Flutter desktop + Android exam review tool (closed-source, offline-first)
**Researched:** 2025-01
**Confidence:** HIGH (Flutter 3.x + Riverpod + drift + path_provider 都是该领域成熟组合；LLM 集成边界与解析流水线为项目特定设计)

## Standard Architecture

### System Overview

```
┌────────────────────────────────────────────────────────────────────────┐
│                            Presentation Layer                          │
│   ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────┐  │
│   │ BankList     │  │  QuizScreen  │  │ WrongReview  │  │  Stats   │  │
│   │  Screen      │  │  (3 modes)   │  │   Screen     │  │  Screen  │  │
│   └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  └────┬─────┘  │
│          │  ref.watch(Riverpod)   │                │              │    │
├──────────┴──────────────────────┴────────────────┴──────────────┴────┤
│                         Application Layer                              │
│   ┌────────────────┐  ┌─────────────────┐  ┌──────────────────┐       │
│   │ QuizSession    │  │ ParseOrchestr.  │  │ LedgerService    │       │
│   │ Controller     │  │ (ParseJob FSM)  │  │ (wrong → master) │       │
│   └────────┬───────┘  └─────────┬───────┘  └──────────┬───────┘       │
│            │                    │                       │              │
├────────────┴────────────────────┴───────────────────────┴──────────────┤
│                             Domain Layer                               │
│   ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────┐  │
│   │ Question │  │QuestionBank│ │Answer   │  │WrongQ    │  │ParseJob│  │
│   │ (entity) │  │ (entity)  │  │Attempt  │  │Ledger    │  │(entity)│  │
│   └──────────┘  └──────────┘  └──────────┘  └──────────┘  └────────┘  │
│            ▲                ▲                ▲              ▲          │
│            │ 纯 Dart 实体 + 不可变 + 业务校验 (freezed-style)           │
├────────────────────────────────────────────────────────────────────────┤
│                             Data Layer                                 │
│   ┌────────────────┐  ┌────────────────┐  ┌──────────────────┐         │
│   │ QuestionRepo   │  │ LedgerRepo     │  │ ParseJobRepo     │         │
│   └────────┬───────┘  └────────┬───────┘  └──────────┬───────┘         │
│            └─────────┬────────┴───────────┬───────────┘                │
│                      ▼                    ▼                            │
│   ┌─────────────────────┐    ┌────────────────────────┐                │
│   │   drift (SQLite)    │    │   LLM Client Boundary  │                │
│   │   DAOs + Migrations │    │  (interface LlmClient) │                │
│   └─────────────────────┘    └──────────┬─────────────┘                │
│                                         │  impl swap                   │
│   ┌────────────────────┐  ┌─────────────┴──┐  ┌──────────────────┐    │
│   │ StubLlmClient      │  │ LlamaCppClient │  │ HttpLlmClient    │    │
│   │ (canned JSON)      │  │ (FFI binding)  │  │ (local server)   │    │
│   └────────────────────┘  └────────────────┘  └──────────────────┘    │
└────────────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|------------------------|
| **Presentation (Screens/Widgets)** | 渲染、收集用户输入、调用 Controller；**不持有业务规则** | `ConsumerWidget` + `ref.watch` |
| **Application (Controllers / Services)** | 协调多个 Repo、执行业务用例（"答错入错题本"、"解析完成入库"）、持有会话级状态 | Riverpod `Notifier` / `AsyncNotifier` |
| **Domain (Entities)** | 不可变模型 + 业务校验（如 `Question.isCorrect(answer)`）；跨层共享 | Dart class + `==` / `copyWith`（可后期引入 freezed） |
| **Data (Repos + DAOs)** | 数据访问、缓存、SQL 拼装、文件 IO 封装 | drift 数据库 + 手写 Repository 包装 DAO |
| **LLM Boundary** | 抽象 `complete(prompt) → json` 行为；屏蔽推理细节 | `abstract class LlmClient` + 3 个实现 |
| **Platform (path_provider, file_picker)** | 平台特定的文件位置与权限 | 直接调用，无封装层（但路径解析在 `PathResolver` 中集中） |

## Recommended Project Structure

```
redclass/
├── pubspec.yaml                  # 依赖：flutter_riverpod, drift, drift_dev, path_provider,
│                                 #        file_picker, docx, pdfx 或 syncfusion_flutter_pdf,
│                                 #        sqlite3_flutter_libs, build_runner
├── assets/
│   └── models/                   # 打包的 GGUF / ONNX 小模型（首次启动检查解压到 AppSupport）
├── lib/
│   ├── main.dart                 # ProviderScope + runApp
│   ├── app.dart                  # MaterialApp.router + GoRouter 配置
│   │
│   ├── core/                     # 跨 feature 共享
│   │   ├── platform/
│   │   │   └── path_resolver.dart        # getApplicationSupportDirectory() → db / model 路径
│   │   ├── theme/
│   │   │   └── app_theme.dart            # Material 3 主题
│   │   └── result.dart                   # sealed class Result<T, E>
│   │
│   ├── data/                     # 数据层
│   │   ├── db/
│   │   │   ├── database.dart             # drift @DriftDatabase
│   │   │   ├── tables/
│   │   │   │   ├── question_banks.dart
│   │   │   │   ├── questions.dart
│   │   │   │   ├── answer_attempts.dart
│   │   │   │   ├── wrong_ledger.dart
│   │   │   │   ├── bookmarks.dart
│   │   │   │   └── parse_jobs.dart
│   │   │   └── migrations.dart           # MigrationStrategy + 版本演进
│   │   ├── llm/
│   │   │   ├── llm_client.dart           # abstract class LlmClient
│   │   │   ├── stub_llm_client.dart      # 单元测试 / 开发用固定 JSON
│   │   │   ├── http_llm_client.dart      # POST 到本地 llama.cpp server
│   │   │   └── llama_cpp_client.dart     # 后期：Fiddle / FFI 直绑
│   │   └── repos/
│   │       ├── question_repository.dart
│   │       ├── ledger_repository.dart
│   │       ├── bookmark_repository.dart
│   │       └── parse_job_repository.dart
│   │
│   ├── domain/                   # 纯 Dart 实体（无 Flutter 依赖）
│   │   ├── entities/
│   │   │   ├── question.dart
│   │   │   ├── question_bank.dart
│   │   │   ├── answer_attempt.dart
│   │   │   ├── wrong_ledger_entry.dart
│   │   │   ├── parse_job.dart
│   │   │   └── enums.dart                # QuestionType, ReviewMode
│   │   └── usecases/                     # 仅在跨 Repo 编排时抽出
│   │       └── record_attempt.dart       # 调 ledger + attempts 两表
│   │
│   ├── features/                 # 按业务功能切分
│   │   ├── bank_import/
│   │   │   ├── presentation/
│   │   │   │   ├── import_screen.dart   # file_picker + 上传进度
│   │   │   │   └── parse_progress_widget.dart
│   │   │   └── application/
│   │   │       └── parse_orchestrator.dart  # ParseJob 状态机
│   │   │
│   │   ├── quiz/
│   │   │   ├── presentation/
│   │   │   │   ├── quiz_screen.dart     # 三个模式共用
│   │   │   │   ├── question_card.dart
│   │   │   │   └── result_feedback.dart
│   │   │   └── application/
│   │   │       └── quiz_session_controller.dart  # AsyncNotifier<QuizState>
│   │   │
│   │   ├── ledger/               # 错题本（被 quiz 间接消费，独立查看页用）
│   │   │   ├── presentation/
│   │   │   │   ├── ledger_screen.dart
│   │   │   │   └── ledger_stats_widget.dart
│   │   │   └── application/
│   │   │       └── ledger_controller.dart     # AsyncNotifier<List<Question>>
│   │   │
│   │   ├── bookmarks/
│   │   │   └── presentation/bookmarks_screen.dart
│   │   │
│   │   └── stats/
│   │       └── presentation/stats_screen.dart
│   │
│   └── shared/                   # 通用 widgets
│       ├── async_value_widget.dart       # 处理 AsyncValue<T> 三态
│       └── empty_state.dart
│
├── test/                         # 镜像 lib/ 结构
│   ├── data/repos/question_repository_test.dart
│   ├── features/quiz/quiz_session_controller_test.dart
│   └── fixtures/
│       └── sample_questions.json         # StubLlmClient 用
│
└── integration_test/
    └── import_and_quiz_test.dart         # 选文件 → 解析 → 答题 → 错题入册 全链路
```

### Structure Rationale

- **`lib/core/platform/path_resolver.dart` 集中所有 `getApplicationSupportDirectory()` 调用**：避免到处散落路径字符串，方便 Android 升级 scoped storage 时只改一处。
- **`lib/data/llm/` 与 `lib/data/repos/` 平级**：LLM Client 是数据来源（解析题库），与 SQLite 同等地位，但用 interface 解耦，使 Repository 不直接 import 具体实现。
- **`lib/features/quiz/` 三模式共用一个 `QuizScreen` + 一个 `QuizSessionController`**：因为三模式差异仅在"题目来源"（`LedgerRepository` vs `QuestionRepository.randomSample`），渲染与判分逻辑完全一致；按模式拆文件会复制代码。
- **`lib/domain/entities/` 纯 Dart**：方便日后若要把领域逻辑搬到 shared library 或写纯 Dart 测试；不依赖 `flutter/material.dart`。
- **`lib/features/<x>/{presentation, application}/` 而非单一 `screens/`**：清晰区分"无状态渲染"和"状态编排"，符合 Clean Architecture lite。

## Architectural Patterns

### Pattern 1: Riverpod Notifier 包装 Repository（共享错题本状态）

**What:** `QuizSessionController` 与 `LedgerController` 都注入同一个 `LedgerRepository`；Repository 内部调用 `ref.invalidate(ledgerProvider)` 通知监听者刷新。这是三模式错题本互通的关键——任何写操作（`markWrong` / `markMastered`）都让所有屏幕的 `ref.watch(ledgerProvider)` 收到新值。

**When to use:** 同一领域数据被多个 feature 共享读写，且写入是低频原子操作。

**Trade-offs:**
- ✅ 天然解耦：UI 不需要知道谁触发了变更
- ✅ 易于测试：`LedgerRepository` 注入 mock，`ProviderScope.overrides` 替换
- ⚠️ Notifier 内部 state 与 DB 不一致风险——必须保证"先写 DB，再 invalidate"（见下方 `recordAttempt` 例子）
- ⚠️ 不适合高频实时同步（如协作编辑），本项目无此需求

**Example — 共享错题本控制器：**

```dart
// lib/features/ledger/application/ledger_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repos/ledger_repository.dart';
import '../../../domain/entities/question.dart';
import '../../../data/db/database.dart';

final ledgerRepositoryProvider = Provider<LedgerRepository>((ref) {
  return LedgerRepository(ref.watch(databaseProvider));
});

/// 错题本当前未掌握的题目列表（错题抽查 / 错题复习共用）
final wrongQuestionsProvider = AsyncNotifierProvider<WrongQuestionsController,
    List<Question>>(WrongQuestionsController.new);

class WrongQuestionsController
    extends AsyncNotifier<List<Question>> {
  @override
  Future<List<Question>> build() async {
    final repo = ref.watch(ledgerRepositoryProvider);
    return repo.getUnmastered();
  }

  /// 被 quiz_session 在判错时调用
  Future<void> markWrong(int questionId) async {
    final repo = ref.read(ledgerRepositoryProvider);
    await repo.upsertWrong(questionId);
    ref.invalidateSelf();              // 触发 build() 重新查询
  }

  /// 错题复习中答对时调用：移出 ledger（mastered_at = now）
  Future<void> markMastered(int questionId) async {
    final repo = ref.read(ledgerRepositoryProvider);
    await repo.markMastered(questionId);
    ref.invalidateSelf();
  }
}
```

**Example — QuizSession 判分时联动 ledger：**

```dart
// lib/features/quiz/application/quiz_session_controller.dart
class QuizSessionController extends FamilyAsyncNotifier<QuizState, ReviewMode> {
  @override
  Future<QuizState> build(ReviewMode mode) async {
    final questions = await _loadQuestionsForMode(mode);
    return QuizState(questions: questions, index: 0, results: const []);
  }

  Future<void> submitAnswer(List<int> chosen) async {
    final q = state.value!.currentQuestion;
    final correct = q.isCorrect(chosen);

    // 1. 永远写 attempt 表（统计用）
    await ref.read(attemptRepoProvider).insert(
      AnswerAttempt(questionId: q.id, mode: state.value!.mode,
                    givenAnswer: chosen, isCorrect: correct, timestamp: DateTime.now()),
    );

    // 2. ledger 联动（关键的三模式共享点）
    final ledger = ref.read(wrongQuestionsProvider.notifier);
    if (!correct) {
      await ledger.markWrong(q.id);
    } else if (state.value!.mode == ReviewMode.wrongReview) {
      await ledger.markMastered(q.id);   // 错题复习中答对 → 移出
    }
    // 乱序抽题答对 → 不动 ledger；错题抽查答对 → 不动 ledger

    state = AsyncData(state.value!.advance(correct));
  }
}
```

### Pattern 2: Repository 模式 + drift DAO 包装

**What:** 不在 Controller / UseCase 里直接写 `db.select(questions).get()`，而是把所有访问藏到 `QuestionRepository` / `LedgerRepository` 后面。Repository 接收 `AppDatabase`（drift），返回 domain entity 而非 drift row。

**When to use:** 任何会被多个 feature 访问的数据；尤其是需要做"复合查询"或"事务"的地方。

**Trade-offs:**
- ✅ Controller 测试可注入 mock repo，无需启动 in-memory SQLite
- ✅ Domain 实体不与 drift 耦合（drift 改动时不影响 UI）
- ⚠️ 多一层间接，CRUD 简单时显得啰嗦；本项目 5 张表尚可接受

**Example:**

```dart
// lib/data/repos/ledger_repository.dart
import '../db/database.dart';
import '../../domain/entities/question.dart';

class LedgerRepository {
  LedgerRepository(this._db);
  final AppDatabase _db;

  /// 错题本当前有效题目（未掌握）—— 给错题复习 / 错题抽查用
  Future<List<Question>> getUnmastered() async {
    final rows = await (_db.select(_db.questions).join([
      innerJoin(_db.wrongLedger,
        _db.wrongLedger.questionId.equalsExp(_db.questions.id)),
    ])
      ..where(_db.wrongLedger.masteredAt.isNull()))
      .get();

    return rows.map((r) => QuestionMapper.fromDb(r.readTable(_db.questions))).toList();
  }

  /// upsert 错题：已存在则 times_wrong++，否则插入
  Future<void> upsertWrong(int questionId) async {
    await _db.transaction(() async {
      final existing = await (_db.select(_db.wrongLedger)
            ..where((t) => t.questionId.equals(questionId)))
          .getSingleOrNull();
      if (existing == null) {
        await _db.into(_db.wrongLedger).insert(
          WrongLedgerCompanion.insert(questionId: questionId, timesWrong: 1,
              lastWrongAt: DateTime.now()),
        );
      } else {
        await (_db.update(_db.wrongLedger)
              ..where((t) => t.questionId.equals(questionId)))
            .write(WrongLedgerCompanion(
              timesWrong: Value(existing.timesWrong + 1),
              lastWrongAt: Value(DateTime.now()),
            ));
      }
    });
  }

  Future<void> markMastered(int questionId) async {
    await (_db.update(_db.wrongLedger)
          ..where((t) => t.questionId.equals(questionId)))
        .write(const WrongLedgerCompanion(masteredAt: Value.absent()))
        .catchError((_) async {
      // 若 ledger 还没该题（不可能发生在 wrongReview 模式但要兜底）
      await _db.into(_db.wrongLedger).insert(
        WrongLedgerCompanion.insert(questionId: questionId, timesWrong: 0,
            lastWrongAt: DateTime.now(), masteredAt: Value(DateTime.now())),
      );
    });
    // 实际：分两步更清晰 —— see Anti-Pattern "过度抽象" 提醒
    await (_db.update(_db.wrongLedger)
          ..where((t) => t.questionId.equals(questionId)))
        .write(const WrongLedgerCompanion(masteredAt: Value(DateTime.now())));
  }
}
```

### Pattern 3: LLM Client 抽象边界（关键架构接缝）

**What:** 所有 LLM 调用都经过 `abstract class LlmClient`；三个实现可热替换：
- `StubLlmClient` — 读取本地 JSON fixture，用于单元测试与"模型未下载时的离线开发"
- `HttpLlmClient` — POST 到 `http://localhost:8080/v1/completions`（llama.cpp / ollama server）
- `LlamaCppClient`（后期） — FFI 直接调用 `llama.cpp` 共享库

**Why this matters:** v1 我们可能用 HTTP server（最简单），v2 切 FFI（性能 + 完全离线 + 无需额外进程），Repository 不能感知。

**Example:**

```dart
// lib/data/llm/llm_client.dart
abstract class LlmClient {
  /// 接收 prompt，返回结构化 JSON 字符串；具体 schema 由调用方约定
  Future<String> complete({
    required String prompt,
    int maxTokens = 1024,
    double temperature = 0.1,
  });

  /// 是否已就绪（模型已加载、server 可达等）—— 给 UI 显示用
  Future<bool> isReady();

  /// 释放资源（关闭 FFI handle / HTTP 连接）
  Future<void> dispose();
}

/// 解析阶段的强类型包装
class ParseResult {
  final List<RawQuestion> questions;
  final int promptTokens;
  final int completionTokens;
  ParseResult(this.questions, this.promptTokens, this.completionTokens);
}

class RawQuestion {
  final String stem;
  final QuestionType type;       // single | multiple
  final List<String> options;    // ["A. xxx", "B. yyy", ...]
  final List<int> correctIndices; // [0, 2] 表示 A、C 正确
  final String? explanation;     // LLM 可选给出
  RawQuestion({/* ... */});
}
```

**Provider 注入（运行时切换）：**

```dart
// lib/data/llm/llm_providers.dart
final llmClientProvider = Provider<LlmClient>((ref) {
  final mode = ref.watch(llmModeProvider);   // stub | http | ffi
  switch (mode) {
    case LlmMode.stub:
      return StubLlmClient.fromFixture('assets/fixtures/sample.json');
    case LlmMode.http:
      return HttpLlmClient(baseUrl: 'http://127.0.0.1:8080');
    case LlmMode.ffi:
      return LlamaCppClient(modelPath: ref.watch(modelPathProvider));
  }
});
```

`ParseOrchestrator` 永远只 `ref.read(llmClientProvider).complete(...)`，**不感知**底层是 stub / HTTP / FFI。

## Data Flow

### Flow A — 导入并解析题库

```
[用户点击"导入题库"]
    ↓
[BankImportScreen] file_picker.pickFiles() → 选 .docx / .pdf
    ↓
[ParseOrchestrator.createJob(sourcePath)]
    ↓
[ParseJobRepo.insert()]  →  status=pending, progress=0
    ↓
[ParseOrchestrator.run()]  (后台 isolate 跑)
    │
    ├─ 1. ExtractTextUseCase
    │     ├─ .docx → dart docx 包解析段落
    │     └─ .pdf  → pdfx 提取文本页
    │  ↓
    ├─ 2. Chunker.split(text, ~2000 字/段)
    │  ↓
    ├─ 3. for each chunk:
    │     ├─ LlmClient.complete(prompt=system+chunk)
    │     ├─ JsonValidator.tryParse(rawJson)  → 失败则记到 ParseJob.errors
    │     └─ ProgressEmitter.emit(chunkIdx/total)
    │  ↓
    ├─ 4. DedupeService  (同 stem 相似度 > 0.9 合并)
    │  ↓
    └─ 5. QuestionRepo.bulkInsert(questions, bankId)  (单事务)
        ↓
[ParseJobRepo.update(status=done | failed)]
    ↓
[BankListScreen] ref.invalidate(bankListProvider) → 列表刷新
```

### Flow B — 一次答题的数据流

```
[QuizScreen] 显示题目 (来自 QuizSessionController.state.currentQuestion)
    ↓  [用户点击选项 → 提交]
[QuizSessionController.submitAnswer(chosen)]
    │
    ├─ 1. domain: q.isCorrect(chosen)  → 纯计算，无 IO
    │
    ├─ 2. AttemptRepo.insert(answerAttempt)
    │     (统计表，独立于 ledger)
    │
    ├─ 3. 模式相关 ledger 联动:
    │     ├─ 乱序抽题 + 错     → ledger.markWrong(qid)
    │     ├─ 错题复习 + 对     → ledger.markMastered(qid)
    │     ├─ 错题复习 + 错     → ledger.upsertWrong(qid) (times_wrong++)
    │     └─ 错题抽查          → 不动 ledger (只测不改)
    │
    └─ 4. state = state.advance(isCorrect)  → UI 自动 rebuild
    ↓
[ResultFeedback widget] 显示对错 + 正确答案
    ↓  [用户点击"下一题" 或自动]
[QuizSessionController.next()]
    ↓
[wrongQuestionsProvider 自动 invalidateSelf] → LedgerScreen 标题数字更新
```

### Flow C — 错题本状态机

```
                ┌──────────────────────────────────────┐
                │       WrongQuestionLedger FSM        │
                └──────────────────────────────────────┘

  (question 存在 questions 表) 
        │
        │  乱序抽题: 答错
        │  错题复习: 答错
        │  错题抽查: 答错 (注: 当前实现不动 ledger，备选)
        ▼
  ┌────────────┐   错题复习模式答对     ┌──────────────┐
  │  in_ledger │ ─────────────────────→ │   mastered   │
  │ (mastered  │                       │ (mastered_at │
  │  = null)   │ ←─────────────────────│  != null)    │
  └─────┬──────┘   任何模式再答错       └──────┬───────┘
        │                                     │
        │  错题复习/错题抽查范围:              │  从错题复习与
        │  ✓ in_ledger 全部                  │  错题抽查范围中
        │  ✗ mastered 排除                   │  排除
        ▼                                     ▼
   (参与 错题复习                              (仅作为历史保留，
    与 错题抽查)                                 可在统计页查看
                                                 "已掌握数量")

  删除/重置题库: ledger 中相关行 CASCADE 删除
  mastered 条目永不"复活"——避免"反复错又反复过"的虚假成就感；
  如需重新加入：手动从统计页"重置错题本"
```

## Parse Pipeline 详解

### 分阶段

| 阶段 | 做什么 | 用什么 | 失败处理 |
|------|--------|--------|----------|
| **1. 文本提取** | `.docx` 用 `docx` 包逐段取；`.pdf` 用 `pdfx` 或 `syncfusion_flutter_pdf` | `ExtractTextUseCase` | 文件损坏 → ParseJob.status=failed, error="corrupt file" |
| **2. 文本清洗** | 去页眉页脚、合并断行（"第 1\n 题" → "第 1 题"）、去除空行 | 纯函数 `TextCleaner` | 不会失败 |
| **3. 分块** | 按 ~2000 字 / 100 行切，避免 LLM 上下文溢出；保留块序号 | `Chunker.split()` | 不会失败 |
| **4. LLM 解析** | 每块构造 prompt：system（输出 JSON schema 约束）+ user（chunk 文本） | `LlmClient.complete()` | 单块失败 → 记到 `ParseJob.errors[]`，继续下一块 |
| **5. JSON 校验** | 解析返回的 JSON，校验 `questions` 数组、`options` 长度、`correctIndices` 范围 | `JsonValidator.tryParse()` | 失败块 → 跳过；最终报告"成功 N/M 块" |
| **6. 去重** | stem 相似度 > 0.9（编辑距离 / trigram）合并，答案取出现频率最高的 | `DedupeService` | 不会失败 |
| **7. 入库** | 单事务批量 insert 到 `questions` 表，`source_bank_id` 关联 | `QuestionRepo.bulkInsert()` | DB 错误 → 整体回滚，ParseJob.status=failed |

### 进度上报

ParseJob 表存 `progress` 字段（0.0~1.0），`ParseOrchestrator` 在每阶段更新：

```dart
// lib/features/bank_import/application/parse_orchestrator.dart
class ParseOrchestrator {
  ParseOrchestrator(this._ref);
  final Ref _ref;

  Future<void> run(String jobId) async {
    final jobRepo = _ref.read(parseJobRepoProvider);
    final llm = _ref.read(llmClientProvider);

    final job = await jobRepo.getById(jobId);
    await jobRepo.updateProgress(jobId, 0.0, status: ParseStatus.extracting);

    final rawText = await ExtractTextUseCase().call(job.sourceFilePath);
    final chunks = Chunker().split(rawText);
    final total = chunks.length;

    await jobRepo.updateProgress(jobId, 0.1, status: ParseStatus.parsing);
    final allRaw = <RawQuestion>[];
    final errors = <String>[];

    for (var i = 0; i < total; i++) {
      try {
        final prompt = PromptBuilder.forChunk(chunks[i], i, total);
        final json = await llm.complete(prompt: prompt);
        final parsed = JsonValidator.tryParse(json);
        if (parsed != null) allRaw.addAll(parsed);
      } catch (e) {
        errors.add('chunk $i: $e');
      }
      // 0.1 ~ 0.9 映射到 LLM 解析阶段
      await jobRepo.updateProgress(jobId, 0.1 + 0.8 * (i + 1) / total);
    }

    final deduped = DedupeService().dedupe(allRaw);
    await jobRepo.updateProgress(jobId, 0.95, status: ParseStatus.inserting);
    await _ref.read(questionRepoProvider).bulkInsert(
        deduped, bankId: job.bankId);

    await jobRepo.updateProgress(jobId, 1.0, status: ParseStatus.done,
        errors: errors);
  }
}
```

`ImportScreen` 用 `ref.watch(parseJobProvider(jobId))` 订阅进度条；用户可离开页面，解析在隔离 `Isolate` / `compute()` 中继续。

### 隔离与取消

- 长解析任务用 `Isolate.run()` 或 `compute()` 跑，避免阻塞 UI（drift 也跑在 background isolate）
- 保存 `JobHandle`，用户点"取消"时调用 `Isolate.kill()` 并 `ParseJobRepo.update(status=cancelled)`

## Cross-Platform File Paths

### 路径策略

**全部数据放 `getApplicationSupportDirectory()`，不放 `getApplicationDocumentsDirectory()`：**

| 平台 | AppSupport 路径 | 原因 |
|------|----------------|------|
| Windows | `%APPDATA%\RedClass\` | 用户文档目录会进 OneDrive 同步；AppSupport 不会；卸载时按惯例可保留 |
| Android | `/data/data/<pkg>/files/` 或 `getApplicationSupportDirectory()` 返回值 | Android scoped storage 推荐；放外部 storage 需要权限且不稳定 |

**`PathResolver` 集中所有路径：**

```dart
// lib/core/platform/path_resolver.dart
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class PathResolver {
  static Future<Directory> _appSupport() async =>
      getApplicationSupportDirectory();

  /// SQLite db 文件：redclass.db
  static Future<File> dbFile() async {
    final dir = await _appSupport();
    return File(p.join(dir.path, 'redclass.db'));
  }

  /// LLM 模型文件：从 assets 解压到此处，避免每次启动重读 assets
  static Future<File> modelFile(String filename) async {
    final dir = await _appSupport();
    final sub = Directory(p.join(dir.path, 'models'));
    if (!await sub.exists()) await sub.create(recursive: true);
    return File(p.join(sub.path, filename));
  }

  /// 导入的原始题库文件副本（保留原文以便重解析）
  static Future<Directory> importedFilesDir() async {
    final dir = await _appSupport();
    final sub = Directory(p.join(dir.path, 'imports'));
    if (!await sub.exists()) await sub.create(recursive: true);
    return sub;
  }
}
```

**启动时初始化（在 `main()`）：**

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dbFile = await PathResolver.dbFile();
  runApp(ProviderScope(
    overrides: [databaseProvider.overrideWith((ref) => AppDatabase(dbFile))],
    child: const RedClassApp(),
  ));
}
```

## LLM Integration Boundary（详细）

### 为什么必须有这层

- **测试**：CI 跑单元测试时无 GPU、无 4GB 模型，需要 `StubLlmClient`
- **开发**：开发者本机没装 llama.cpp server 时也能跑通"导入 → 解析"全链路（用 fixture）
- **生产切换**：v1 HTTP / v2 FFI 不动业务代码
- **可观测**：所有 `complete()` 调用经过一处，便于加 retry / metrics / mock

### 实现选择

| 阶段 | 客户端 | 模型大小 | 备注 |
|------|--------|----------|------|
| v1 (MVP) | `HttpLlmClient` → llama.cpp server | 1-3B Q4 | 用户需自己跑 server；最简 |
| v1.1 | `LlamaCppClient` (FFI) | 1-3B Q4 | 性能更好、无需额外进程；Windows 容易，Android 需打包 .so |
| 测试 | `StubLlmClient` | — | fixtures/sample_questions.json |

### Prompt Schema（v1 草案）

```
SYSTEM:
你是题目解析助手。输入是一段题库文本，输出严格 JSON：
{
  "questions": [
    {
      "stem": "题干原文",
      "type": "single" | "multiple",
      "options": ["A. ...", "B. ...", ...],
      "correct_indices": [0, 2],   // 0-based
      "explanation": "可选"
    }
  ]
}
不要输出任何 JSON 之外的文字。

USER:
<chunk 文本>
```

### 健壮性

- 单 chunk LLM 调用失败 → 不终止整批，记到 `ParseJob.errors[]`
- JSON 解析失败 → 尝试从返回中抽取 `{}` 块；仍失败则跳过
- 整批成功率 < 50% → 标记 `ParseJob.status = needs_review`，UI 提示用户检查
- 用户可对失败 chunk 单点重试（v1.1）

## Schema Migration Strategy

### 工具选择

使用 `drift` 的 `MigrationStrategy`：

```dart
// lib/data/db/migrations.dart
import 'package:drift/drift.dart';

class AppMigrations {
  static final strategy = MigrationStrategy(
    onCreate: (m) async => m.createAll(),
    onUpgrade: (m, from, to) async {
      // 严格按 from→to 顺序写 if / else if 链
      if (from < 2) {
        await m.addColumn(questions, questions.difficulty);
      }
      if (from < 3) {
        await m.createTable(parseJobs);
      }
    },
  );
}
```

### 规则

1. **永远只加列 / 加表，不删列**——避免破坏用户数据
2. **每个 migration 用 if (from < N)** 包裹，**不可变**：新用户从 0 开始，升级用户从 from → N；写过的 if 不能改
3. **schema_version 存 `PRAGMA user_version`**，drift 自动管理
4. **复杂迁移**（如 split table）写数据迁移 SQL：旧表 → 新表，事务包裹
5. **备份优先**：启动时若 `onUpgrade` 失败，先 `File(path).copy('${path}.bak')` 再尝试；失败可恢复
6. **dev 阶段**：重置数据库比写迁移更省事——`PathResolver.dbFile().delete()` 即可；**仅 dev**

### 版本号策略

`pubspec.yaml` 版本不直接当 schema 版本；在 `database.dart` 中独立维护：

```dart
const int currentSchemaVersion = 1;   // 改 schema 时 +1
```

## Anti-Patterns to Avoid

### 1. 业务逻辑写在 Widget 里

**What people do:** 在 `QuizScreen` 的 `onPressed` 里直接判断对错、写入 DB。
**Why wrong:** 难测试、难复用——日后想加"自动下一题"、"快捷键答题"就要复制粘贴判分逻辑。
**Do this instead:** 判分与 DB 写在 `QuizSessionController.submitAnswer()`，Widget 只 `ref.read(controller.notifier).submitAnswer(chosen)`。

### 2. 不抽象 LLM Client

**What people do:** `import 'package:llama_cpp/llama_cpp.dart'` 直接在 `ParseOrchestrator` 调 `Llama.complete(...)`。
**Why wrong:** CI 跑不起来；想换实现要全项目搜索替换；无法注入 mock 测。
**Do this instead:** `LlmClient` 抽象（见 Pattern 3），通过 Provider 注入。

### 3. 导航与数据获取混在 `build()` 里

**What people do:** `Navigator.push(context, MaterialPageRoute(builder: (_) => FutureBuilder(...)));`
**Why wrong:** FutureBuilder 每次 build 重建；错误处理不统一；失去路由可观测性。
**Do this instead:** `go_router` + 目标屏幕的 `AsyncNotifier`；导航时只传 ID，不传 Future。

### 4. SQLite 放在 Documents Directory

**What people do:** `getApplicationDocumentsDirectory()` 存 db。
**Why wrong:**
- Windows：`Documents` 默认被 OneDrive 同步 → 频繁 IO 冲突 + 隐私泄露
- Android 11+ scoped storage 限制访问 documents；卸载可能清掉
**Do this instead:** `getApplicationDocumentsDirectory()` **不放** db；用 `getApplicationSupportDirectory()`（如本文档 §"Cross-Platform File Paths"）。

### 5. 把 Riverpod Notifier 内部的 ephemeral state 提升到全局

**What people do:** 用 `Provider<QuizState>` 全局共享当前正在答的题目。
**Why wrong:** 用户在 `QuizScreen` 答第 5 题时切到 `LedgerScreen` 看了下，再切回——状态被覆盖或污染。
**Do this instead:** 会话级 ephemeral state 用 `StateProvider` / `Notifier` 但限制 scope；或用 `AutoDispose`（`AsyncNotifierProvider.autoDispose`）让离开屏幕时自动销毁。

### 6. 在 LLM prompt 里放敏感数据

**What people do:** 直接把用户整本 PDF 文本塞 prompt。
**Why wrong:** 即使本地 LLM，单 chunk 过大直接 OOM 或超出 context window；且 `docx` 里可能含个人元数据（作者名等）。
**Do this instead:** 文本清洗阶段去除元数据；分块限制字数；LTM prompt 只放 chunk 文本 + 必要指令。

### 7. mastered 条目不"软删除"

**What people do:** 答对后直接从 `wrong_ledger` 表 DELETE。
**Why wrong:** 丢失"曾错过"的历史；统计页无法展示"已掌握 N 道"；重置错题本困难。
**Do this instead:** 永远 soft delete——`mastered_at` 字段置 `now()`，查询时 `.where(masteredAt.isNull())` 过滤（本文档 FSM 已规范）。

### 8. 解析时同步阻塞 UI

**What people do:** `main() async { final q = await llm.complete(...); runApp(...); }` 或在 onPressed 里同步等解析完再 setState。
**Why wrong:** 解析可能 30s+，UI 卡死甚至 ANR。
**Do this instead:** 解析跑在 `Isolate.run()` 或 `compute()`；通过 `ParseJob.progress` 流式上报；UI 用 `ref.watch` 订阅进度。

## Integration Points

### External Services / Native

| 集成 | 方式 | 关键包 / 风险 |
|------|------|---------------|
| **本地 SQLite** | `drift` (含 `sqlite3_flutter_libs` 自动链接 native lib) | Windows / Android 都 OK；不要自己拼 SQL 字符串，用 drift DSL 防注入 |
| **文件选择** | `file_picker` | Windows 需 `pickFiles(allowMultiple: false)`；Android 13+ 用 SAF (`useMaterialSaveDelegate: true`) |
| **`.docx` 解析** | `docx` (纯 Dart) 或 `archive + xml` | 纯 Dart，跨平台一致；慢但 OK |
| **`.pdf` 解析** | `pdfx` (渲染 + 文本) 或 `syncfusion_flutter_pdf` (商用) | 扫描版 PDF（图片）无解——v1 不做 OCR |
| **LLM HTTP** | `package:http` → `http://127.0.0.1:8080/v1/completions` (llama.cpp server) | 用户需启动 server；APK 体积可控 |
| **LLM FFI** (v2) | `ffi: ^2.0` 调用 `llama.cpp` 编译产物 | Android 需 NDK 编译 `.so` 多 ABI（arm64-v8a / armeabi-v7a / x86_64） |

### Internal Boundaries

| 边界 | 通信方式 | 备注 |
|------|----------|------|
| **UI ↔ Controller** | Riverpod `ref.watch` / `ref.read` | Notifier 内部状态变化触发 UI rebuild |
| **Controller ↔ Repository** | 直接方法调用 | Repository 是普通 Dart class，由 Provider 注入 |
| **Repository ↔ DAO / DB** | drift API | 单 `AppDatabase` 实例（Provider 单例），避免多实例写冲突 |
| **ParseOrchestrator ↔ LLM** | `LlmClient` 接口 | **唯一**允许 LLM 调用的层；不让 UI / Controller 直接调 |
| **错题本 ↔ 三模式 Quiz** | `wrongQuestionsProvider`（AsyncNotifier） | 三模式共享读；三模式中两种会写 |

## Sources

- Flutter 官方文档：`flutter.dev/docs`（path_provider, file_picker）
- drift 官方文档：`drift.simonbinder.eu`（migrations, transactions）
- Riverpod 官方文档：`riverpod.dev`（AsyncNotifier, FamilyAsyncNotifier, ref.invalidate）
- llama.cpp：`github.com/ggerganov/llama.cpp`（HTTP server 模式与 FFI 绑定）
- Material 3 设计规范：`m3.material.io`（UI 主题基线，与 `ui-ux-pro-max` skill 对齐）
- 项目背景：`.planning/PROJECT.md`（需求、约束、Out of Scope）

---

*Architecture research for: RedClass (红课复习) — local Flutter exam review tool*
*Researched: 2025-01*
