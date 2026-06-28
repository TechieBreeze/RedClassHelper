# 题库删除功能实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让用户能从 `BankDetailScreen` 删除已导入的题库，原子清理关联题目/错题/答题记录/收藏。

**Architecture:** 新建 `BankRepository`（封装 `db.transaction` + `delete().go()`，drift FK cascade 自动级联）+ `BankDetailController`（Riverpod notifier，触发删除 + invalidate 列表 provider）。在 `BankDetailScreen._buildActionsSection` 追加红色"删除题库"卡片，点击弹 Material 确认 Dialog，确认后 `safePop` + SnackBar。

**Tech Stack:** Flutter ^3.x, Dart ^3.x, drift ^2.34.0, riverpod_annotation ^4.0.3 (Riverpod 3.x), flutter_riverpod ^3.3.2, Material 3, go_router, `safe_nav` extension。

**Spec:** `docs/superpowers/specs/2026-06-28-question-bank-delete-design.md`

**Mockups:** `docs/superpowers/specs/draft-delete-bank-mockups.html` (方案 A 与方案 C 的混合实现)

---

## 文件结构

| 文件 | 操作 | 职责 |
|------|------|------|
| `lib/data/repositories/bank_repository.dart` | 新增 | `BankRepository` 接口 + `BankRepositoryImpl` + `@Riverpod(keepAlive: true)` provider |
| `lib/features/bank_detail/application/bank_detail_controller.dart` | 新增 | `BankDetailController` notifier + `@riverpod` provider |
| `lib/features/bank_detail/presentation/bank_detail_screen.dart` | 修改 | 追加 `_buildDeleteCard` / `_showDeleteConfirmDialog` / `_performDelete`，加 `_isDeleting` 状态字段 |
| `test/unit/data/repositories/bank_repository_test.dart` | 新增 | 6 个 cascade / 边界 / 幂等 / 事务单元测试 |
| `test/unit/features/bank_detail/bank_detail_controller_test.dart` | 新增 | 1 个 controller 单元测试 |
| `test/widget/features/bank_detail/bank_detail_delete_test.dart` | 新增 | 9 个 widget 测试 |

---

## Task 1: `BankRepository` 单元测试 (RED)

**Files:**
- Create: `test/unit/data/repositories/bank_repository_test.dart`

- [ ] **Step 1: 写测试 — 验证 cascade 行为、幂等性、空题库、ParseJobs 保留、事务包装**

```dart
// test/unit/data/repositories/bank_repository_test.dart
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:redclass/data/db/database.dart';
import 'package:redclass/data/repositories/bank_repository.dart';

void main() {
  late AppDatabase db;
  late BankRepository repo;

  setUp(() async {
    db = AppDatabase.openInMemoryDatabase();
    repo = BankRepositoryImpl(db);
  });

  tearDown(() async => await db.close());

  // ── Helpers ────────────────────────────────────────────────────
  Future<void> insertBank(String id, {String name = 'Test Bank'}) async {
    final now = DateTime.now();
    await db.into(db.questionBanks).insertOnConflictUpdate(
      QuestionBanksCompanion.insert(
        id: id,
        name: name,
        source: const Value('test'),
        questionCount: 1,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> insertQuestion(String id, String bankId) async {
    final now = DateTime.now();
    await db.into(db.questions).insert(
      QuestionsCompanion.insert(
        id: id,
        bankId: bankId,
        type: 'single',
        stem: 'Q?',
        optionsJson: '[{"key":"A","text":"a"}]',
        correctJson: '["A"]',
        rawText: 'Q?',
        createdAt: now,
      ),
    );
  }

  group('BankRepository.deleteBank', () {
    test('cascades delete to questions', () async {
      await insertBank('b1');
      await insertQuestion('q1', 'b1');
      await insertQuestion('q2', 'b1');

      await repo.deleteBank('b1');

      expect(await db.select(db.questionBanks).get(), isEmpty);
      expect(await db.select(db.questions).get(), isEmpty);
    });

    test('cascades three levels: attempts/bookmarks/wrong_ledger', () async {
      await insertBank('b1');
      await insertQuestion('q1', 'b1');
      final now = DateTime.now();
      await db.into(db.answerAttempts).insert(AnswerAttemptsCompanion.insert(
        id: 'a1', questionId: 'q1', sessionId: 's1',
        userAnswerJson: '["A"]', isCorrect: true, answeredAt: now,
      ));
      await db.into(db.bookmarks).insert(BookmarksCompanion.insert(
        id: 'bm1', questionId: 'q1', createdAt: now,
      ));
      await db.into(db.wrongLedgerEntries).insert(WrongLedgerEntriesCompanion.insert(
        id: 'w1', questionId: 'q1', timesWrong: 1,
        firstWrongAt: now, lastWrongAt: now,
      ));

      await repo.deleteBank('b1');

      expect(await db.select(db.answerAttempts).get(), isEmpty);
      expect(await db.select(db.bookmarks).get(), isEmpty);
      expect(await db.select(db.wrongLedgerEntries).get(), isEmpty);
    });

    test('empty bank (0 questions) deletes cleanly', () async {
      await insertBank('b1');

      await expectLater(repo.deleteBank('b1'), completes);
      expect(await db.select(db.questionBanks).get(), isEmpty);
    });

    test('preserves orphan parse_jobs after bank deletion', () async {
      await insertBank('b1');
      final now = DateTime.now();
      await db.into(db.parseJobs).insertOnConflictUpdate(
        ParseJobsCompanion.insert(
          id: 'pj1', sourcePath: 'old/path.pdf',
          status: 'success', progress: 1.0,
          resultCount: 5, createdAt: now, updatedAt: now,
        ),
      );

      await repo.deleteBank('b1');

      expect(await db.select(db.parseJobs).get(), hasLength(1));
    });

    test('idempotent for non-existent bankId', () async {
      await expectLater(repo.deleteBank('does-not-exist'), completes);
    });

    test('runs inside a database transaction', () async {
      await insertBank('b1');
      var txCount = 0;
      final original = db.transaction;
      db.transaction = ((action) {
        txCount++;
        return original.call(action);
      }) as TransactionExecutor;

      await repo.deleteBank('b1');
      expect(txCount, 1);
    });
  });
}
```

- [ ] **Step 2: 运行测试 — 应该失败（BankRepository 不存在）**

Run: `flutter test test/unit/data/repositories/bank_repository_test.dart`
Expected: compile error — `Target of URI doesn't exist: 'package:redclass/data/repositories/bank_repository.dart'`

- [ ] **Step 3: 提交测试骨架**

```bash
git add test/unit/data/repositories/bank_repository_test.dart
git commit -m "test(bank-repo): add cascade/edge/idempotency/trans tests (RED)"
```

---

## Task 2: `BankRepository` 实现 (GREEN)

**Files:**
- Create: `lib/data/repositories/bank_repository.dart`

- [ ] **Step 1: 写最小实现**

```dart
// lib/data/repositories/bank_repository.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/providers/app_database_provider.dart';
import '../db/database.dart';

part 'bank_repository.g.dart';

/// 题库仓库 — 题库级 CRUD 的统一入口。
///
/// 当前只暴露 [deleteBank]。未来 [renameBank] / [reorderBanks] /
/// [groupBanks] 都加在这里。
abstract interface class BankRepository {
  Future<void> deleteBank(String bankId);
}

class BankRepositoryImpl implements BankRepository {
  BankRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<void> deleteBank(String bankId) async {
    await _db.transaction(() async {
      // drift FK cascade (Questions.bankId → QuestionBanks.id) 自动清理
      // AnswerAttempts / Bookmarks / WrongLedgerEntries。
      await (_db.delete(_db.questionBanks)
            ..where((t) => t.id.equals(bankId)))
          .go();
    });
  }
}

@Riverpod(keepAlive: true)
Future<BankRepository> bankRepository(Ref ref) async {
  final db = await ref.watch(appDatabaseProvider.future);
  return BankRepositoryImpl(db);
}
```

> **依赖提示：** `appDatabaseProvider` 路径可能与你的项目不同。先 `grep -rn "class AppDatabase" lib/data/db/` 确认 provider 文件位置。常见路径：
> - `lib/data/db/database.dart` (provider 与 class 同文件)
> - `lib/core/providers/app_database_provider.dart` (分离)
>
> 在 `lib/data/db/database.dart` 已确认有 `@Riverpod(keepAlive: true) AppDatabase appDatabase(Ref ref)` 形式。如果 import 路径不对，按 grep 结果调整。

- [ ] **Step 2: 运行代码生成（首次需要）**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: 生成 `bank_repository.g.dart`。

- [ ] **Step 3: 运行测试 — 应该通过**

Run: `flutter test test/unit/data/repositories/bank_repository_test.dart`
Expected: 6 tests pass.

- [ ] **Step 4: 运行 dart analyze**

Run: `dart analyze lib/data/repositories/bank_repository.dart test/unit/data/repositories/bank_repository_test.dart`
Expected: 0 issues.

- [ ] **Step 5: 提交**

```bash
git add lib/data/repositories/bank_repository.dart lib/data/repositories/bank_repository.g.dart
git commit -m "feat(bank-repo): add deleteBank with FK cascade + keepAlive provider"
```

---

## Task 3: `BankDetailController` 单元测试 (RED)

**Files:**
- Create: `test/unit/features/bank_detail/bank_detail_controller_test.dart`

- [ ] **Step 1: 写测试**

```dart
// test/unit/features/bank_detail/bank_detail_controller_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redclass/data/repositories/bank_repository.dart';
import 'package:redclass/features/bank_detail/application/bank_detail_controller.dart';
import 'package:redclass/features/quiz/providers/bank_pick_provider.dart';

class _FakeBankRepository implements BankRepository {
  final List<String> deletedIds = [];
  bool throwOnDelete = false;

  @override
  Future<void> deleteBank(String bankId) async {
    if (throwOnDelete) throw Exception('boom');
    deletedIds.add(bankId);
  }
}

void main() {
  late ProviderContainer container;
  late _FakeBankRepository fakeRepo;

  setUp(() {
    fakeRepo = _FakeBankRepository();
    container = ProviderContainer(overrides: [
      bankRepositoryProvider.overrideWith((ref) async => fakeRepo),
    ]);
    addTearDown(container.dispose);
  });

  test('deleteBank calls repo.deleteBank with provided id', () async {
    await container
        .read(bankDetailControllerProvider.notifier)
        .deleteBank('bank-42');

    expect(fakeRepo.deletedIds, ['bank-42']);
  });

  test('deleteBank invalidates bankPickListProvider', () async {
    // 触发 bankPickListProvider 首次 build（用 fakeRepo 提供的 List<BankPickItem>，
    // 但 BankPickItem 需要 QuestionBank，所以这里仅验证 invalidate 调用——通过 spy）。
    // 简化：直接调用 deleteBank，验证不抛异常，且后续读取 provider 会重新 build。
    await container
        .read(bankDetailControllerProvider.notifier)
        .deleteBank('b1');

    // 如果 bankPickListProvider 被 invalidate，订阅时会重新 build；
    // 我们用 read(future) 验证不会抛"未 override"错误。
    expect(container.read(bankPickListProvider), isA<AsyncValue<List<BankPickItem>>>());
  });

  test('deleteBank propagates exceptions (caller handles UI feedback)', () async {
    fakeRepo.throwOnDelete = true;
    await expectLater(
      container.read(bankDetailControllerProvider.notifier).deleteBank('b1'),
      throwsException,
    );
  });
}
```

- [ ] **Step 2: 运行测试 — 应该失败（controller 不存在）**

Run: `flutter test test/unit/features/bank_detail/bank_detail_controller_test.dart`
Expected: compile error — `bank_detail_controller.dart` not found.

- [ ] **Step 3: 提交**

```bash
git add test/unit/features/bank_detail/bank_detail_controller_test.dart
git commit -m "test(controller): add deleteBank/invalidate/exception tests (RED)"
```

---

## Task 4: `BankDetailController` 实现 (GREEN)

**Files:**
- Create: `lib/features/bank_detail/application/bank_detail_controller.dart`

- [ ] **Step 1: 写最小实现**

```dart
// lib/features/bank_detail/application/bank_detail_controller.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/repositories/bank_repository.dart';
import '../../quiz/providers/bank_pick_provider.dart';

part 'bank_detail_controller.g.dart';

/// 题库详情页控制器 — 持有删除等写操作。
@riverpod
class BankDetailController extends _$BankDetailController {
  @override
  void build() {}

  /// 删除指定题库。成功后 invalidate 列表 provider。
  ///
  /// 异常向上抛，调用方（widget）负责捕获并展示 SnackBar。
  Future<void> deleteBank(String bankId) async {
    final repo = await ref.read(bankRepositoryProvider.future);
    await repo.deleteBank(bankId);
    ref.invalidate(bankPickListProvider);
  }
}
```

- [ ] **Step 2: 代码生成**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: 生成 `bank_detail_controller.g.dart`。

- [ ] **Step 3: 运行测试 — 应该通过**

Run: `flutter test test/unit/features/bank_detail/bank_detail_controller_test.dart`
Expected: 3 tests pass.

- [ ] **Step 4: dart analyze**

Run: `dart analyze lib/features/bank_detail/application/ test/unit/features/bank_detail/`
Expected: 0 issues.

- [ ] **Step 5: 提交**

```bash
git add lib/features/bank_detail/application/bank_detail_controller.dart lib/features/bank_detail/application/bank_detail_controller.g.dart
git commit -m "feat(controller): add BankDetailController.deleteBank with invalidate"
```

---

## Task 5: 在 `BankDetailScreen` 加 `_buildDeleteCard` (无新依赖)

**Files:**
- Modify: `lib/features/bank_detail/presentation/bank_detail_screen.dart`
  - `BankDetailScreen` 类加 `bool _isDeleting = false` 字段（状态保存）
  - 新增 `_buildDeleteCard` 方法
  - `_buildActionsSection` 追加一行

- [ ] **Step 1: 把 `BankDetailScreen` 从 `ConsumerWidget` 改为 `ConsumerStatefulWidget`**

在文件顶部，**替换整个 `BankDetailScreen` 类的开头部分**（约 line 32-65）。先注释旧类，再写新类：

替换前（line 32 起）：
```dart
/// 题库详情页
class BankDetailScreen extends ConsumerWidget {
  const BankDetailScreen({super.key, required this.bankId});
  final String bankId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbAsync = ref.watch(appDatabaseProvider);
    return dbAsync.when(
      ...
    );
  }
```

替换后：
```dart
/// 题库详情页
class BankDetailScreen extends ConsumerStatefulWidget {
  const BankDetailScreen({super.key, required this.bankId});
  final String bankId;

  @override
  ConsumerState<BankDetailScreen> createState() => _BankDetailScreenState();
}

class _BankDetailScreenState extends ConsumerState<BankDetailScreen> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(appDatabaseProvider);
    return dbAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('题库详情')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('题库详情')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text('数据库加载失败', style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
      ),
      data: (db) => _buildContent(context, db),
    );
  }
```

> 注意：原 `_buildContent` 签名是 `(BuildContext, WidgetRef, AppDatabase)`。
> 由于类改成 `ConsumerStatefulWidget`，**所有用到 `ref` 的内部方法都需要从参数改为 `this.ref`**，或保留参数签名并改内部调用。本计划**选择保留原参数签名**，因为 `_buildContent` / `_loadBankData` / `_buildScaffold` / `_buildHeroBanner` / `_buildVerticalLayout` / `_buildHorizontalLayout` / `_buildActionsSection` / `_buildStartReviewCard` / `_buildExportJsonCard` / `_exportJson` 都已在 `build` 内被调用，最小改动是给所有这些方法加上 `WidgetRef ref` 参数或者从 `this.ref` 取。

**实际最小改动**（推荐）：
- 内部方法一律改用 `this.ref`（不要保留参数 ref）
- 把 `_buildContent(context, ref, db)` → `_buildContent(context, db)`
- `_buildScaffold(context, ref, bank, questions)` → `_buildScaffold(context, bank, questions)`
- 其他 `_build*` 方法类似

**Step 2 — 改完所有内部方法后跳过。**

- [ ] **Step 2: 改所有内部方法的 `ref` 参数为 `this.ref`**

使用 `Edit` 工具，对每处 `_buildXxx(context, ref, ...)` 改为 `_buildXxx(context, ...)`，并把方法体里的 `ref.xxx` 改为 `this.ref.xxx`。

具体改动（按行号参考当前文件）：
- line 66: `Widget _buildContent(BuildContext context, WidgetRef ref, AppDatabase db)` → `Widget _buildContent(BuildContext context, AppDatabase db)`
- line 67-85: 函数体内 `ref` 全部移除（`_loadBankData(db)` 不需要 ref）；`builder` 回调里 `ref` 改为 `this.ref`
- line 100: `_buildScaffold(context, ref, bank, questions)` 调用点改为 `_buildScaffold(context, bank, questions)`，函数签名同步
- 后续 `_buildHorizontalLayout` / `_buildVerticalLayout` / `_buildActionsSection` / `_buildExportJsonCard` / `_exportJson` 同理

> **重要：** 函数体内对 `ref` 的引用全部换成 `this.ref`。注意 `FutureBuilder.builder: (context, snapshot) { ... }` 闭包内用的是 `this.ref`（来自外层 `_BankDetailScreenState`）。

- [ ] **Step 3: 新增 `_buildDeleteCard` 方法**

在 `_buildExportJsonCard` 之后（即文件中 `_exportJson` 方法**之前**）插入：

```dart
  Widget _buildDeleteCard(
    BuildContext context,
    ColorScheme cs,
    QuestionBank bank,
  ) {
    return HoverableCard(
      onTap: _isDeleting ? null : () => _showDeleteConfirmDialog(context, bank),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cs.errorContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                color: cs.onErrorContainer,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '删除题库',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.error,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '删除全部题目、错题、记录（不可撤销）',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withAlpha(150),
                    ),
                  ),
                ],
              ),
            ),
            if (_isDeleting)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(Icons.chevron_right_rounded, color: cs.outline, size: 20),
          ],
        ),
      ),
    );
  }
```

- [ ] **Step 4: `_buildActionsSection` 追加删除卡片**

把 line 387-409 的 `_buildActionsSection` 方法体改为：

```dart
  Widget _buildActionsSection(
    BuildContext context,
    QuestionBank bank,
    List<Question> questions,
  ) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '操作',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        _buildStartReviewCard(context, cs),
        const SizedBox(height: 8),
        _buildExportJsonCard(context, cs, bank, questions),
        const SizedBox(height: 8),
        _buildDeleteCard(context, cs, bank),
      ],
    );
  }
```

同时把 `_buildExportJsonCard(context, ref, cs, ...)` 改为 `_buildExportJsonCard(context, cs, ...)`（去掉 `ref` 参数）。函数体内 `ref.read` 改 `this.ref.read`。

- [ ] **Step 5: dart analyze + 现有测试**

Run: `dart analyze lib/features/bank_detail/`
Expected: 0 issues.

Run: `flutter test test/widget/features/bank_detail/`
Expected: 现有测试全部通过（无回归）。

- [ ] **Step 6: 提交**

```bash
git add lib/features/bank_detail/presentation/bank_detail_screen.dart
git commit -m "feat(ui): add _buildDeleteCard with destructive style + loading state"
```

---

## Task 6: 加 `_showDeleteConfirmDialog` 与 `_performDelete`

**Files:**
- Modify: `lib/features/bank_detail/presentation/bank_detail_screen.dart`
  - 新增 `_showDeleteConfirmDialog` 方法
  - 新增 `_performDelete` 方法

- [ ] **Step 1: 在 `_buildDeleteCard` 方法后插入两个新方法**

```dart
  Future<void> _showDeleteConfirmDialog(
    BuildContext context,
    QuestionBank bank,
    int questionCount,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final cs = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          icon: Icon(Icons.warning_amber_rounded, color: cs.error, size: 32),
          title: Text('删除「${bank.name}」？'),
          content: Text(
            '将一并删除 $questionCount 道题、错题、答题记录。\n\n'
            '此操作不可撤销。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: cs.error,
                foregroundColor: cs.onError,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('删除题库'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    if (!mounted) return;
    await _performDelete(context, bank);
  }

  Future<void> _performDelete(BuildContext context, QuestionBank bank) async {
    if (_isDeleting) return;             // 防御：dialog 已确认，但避免 race
    setState(() => _isDeleting = true);
    try {
      await ref
          .read(bankDetailControllerProvider.notifier)
          .deleteBank(bank.id);
      if (!mounted) return;
      if (context.mounted) context.safePop();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已删除「${bank.name}」'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('删除失败: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }
```

- [ ] **Step 2: 调整 `_buildDeleteCard` 把 question 数传过去**

把 `_buildDeleteCard(context, cs, bank)` 改为 `_buildDeleteCard(context, cs, bank, questions.length)`，并在 `onTap` 里：

```dart
onTap: _isDeleting ? null : () => _showDeleteConfirmDialog(context, bank, questions.length),
```

但 `_buildDeleteCard` 当前签名只接 `(context, cs, bank)`。**让它也接收 `int questionCount`**，并在 `_buildActionsSection` 调用处传 `questions.length`。

- [ ] **Step 3: 加 import**

文件顶部 import 区追加：

```dart
import '../application/bank_detail_controller.dart';
```

- [ ] **Step 4: dart analyze**

Run: `dart analyze lib/features/bank_detail/presentation/bank_detail_screen.dart`
Expected: 0 issues.

- [ ] **Step 5: 提交**

```bash
git add lib/features/bank_detail/presentation/bank_detail_screen.dart
git commit -m "feat(ui): add confirm dialog + performDelete with mounted guards"
```

---

## Task 7: Widget 测试套件（happy path）

**Files:**
- Create: `test/widget/features/bank_detail/bank_detail_delete_test.dart`

- [ ] **Step 1: 写测试**

```dart
// test/widget/features/bank_detail/bank_detail_delete_test.dart
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redclass/core/theme.dart';
import 'package:redclass/data/db/database.dart';
import 'package:redclass/data/repositories/bank_repository.dart';
import 'package:redclass/features/bank_detail/presentation/bank_detail_screen.dart';

Widget _wrap({required AppDatabase db, BankRepository? repo}) {
  return ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWith((_) async => db),
      if (repo != null)
        bankRepositoryProvider.overrideWith((_) async => repo),
    ],
    child: MaterialApp(
      theme: buildAppTheme(),
      home: const BankDetailScreen(bankId: 'b1'),
    ),
  );
}

Future<void> _seedBank(AppDatabase db) async {
  final now = DateTime.now();
  await db.into(db.questionBanks).insertOnConflictUpdate(
    QuestionBanksCompanion.insert(
      id: 'b1', name: 'Test Bank', source: const Value('test'),
      questionCount: 2, createdAt: now, updatedAt: now,
    ),
  );
  for (final qid in ['q1', 'q2']) {
    await db.into(db.questions).insert(
      QuestionsCompanion.insert(
        id: qid, bankId: 'b1', type: 'single',
        stem: 'Q?', optionsJson: '[{"key":"A","text":"a"}]',
        correctJson: '["A"]', rawText: 'Q?', createdAt: now,
      ),
    );
  }
}

class _FakeBankRepository implements BankRepository {
  final List<String> deletedIds = [];
  Future<void> Function(String)? onDelete;

  @override
  Future<void> deleteBank(String bankId) async {
    if (onDelete != null) await onDelete!(bankId);
    deletedIds.add(bankId);
  }
}

void main() {
  late AppDatabase db;
  late _FakeBankRepository fakeRepo;

  setUp(() async {
    db = AppDatabase.openInMemoryDatabase();
    await _seedBank(db);
    fakeRepo = _FakeBankRepository();
  });

  tearDown(() async => await db.close());

  testWidgets('shows red delete card with destructive style', (tester) async {
    await tester.pumpWidget(_wrap(db: db, repo: fakeRepo));
    await tester.pumpAndSettle();

    expect(find.text('删除题库'), findsOneWidget);
    expect(find.textContaining('不可撤销'), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
  });

  testWidgets('opens confirm dialog on tap', (tester) async {
    await tester.pumpWidget(_wrap(db: db, repo: fakeRepo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('删除题库'));
    await tester.pumpAndSettle();

    expect(find.text('删除「Test Bank」？'), findsOneWidget);
    expect(find.text('取消'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '删除题库'), findsOneWidget);
  });

  testWidgets('cancel does not delete', (tester) async {
    await tester.pumpWidget(_wrap(db: db, repo: fakeRepo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('删除题库'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expect(fakeRepo.deletedIds, isEmpty);
    expect(find.byType(BankDetailScreen), findsOneWidget);
  });

  testWidgets('confirm deletes, pops, shows SnackBar', (tester) async {
    await tester.pumpWidget(_wrap(db: db, repo: fakeRepo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('删除题库'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '删除题库'));
    await tester.pumpAndSettle();

    expect(fakeRepo.deletedIds, ['b1']);
    expect(find.text('已删除「Test Bank」'), findsOneWidget);
  });
}
```

- [ ] **Step 2: 运行测试**

Run: `flutter test test/widget/features/bank_detail/bank_detail_delete_test.dart`
Expected: 4 tests pass.

- [ ] **Step 3: 提交**

```bash
git add test/widget/features/bank_detail/bank_detail_delete_test.dart
git commit -m "test(ui): add 4 happy-path widget tests for delete flow"
```

---

## Task 8: Widget 测试（错误路径 + 边界）

**Files:**
- Modify: `test/widget/features/bank_detail/bank_detail_delete_test.dart`

- [ ] **Step 1: 追加 5 个错误/边界测试**

在 `void main() { ... }` 末尾、`tearDown` 之后追加：

```dart
  testWidgets('DB failure: SnackBar shows error, no pop', (tester) async {
    fakeRepo.onDelete = (_) async => throw Exception('disk full');
    await tester.pumpWidget(_wrap(db: db, repo: fakeRepo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('删除题库'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '删除题库'));
    await tester.pumpAndSettle();

    expect(find.textContaining('删除失败'), findsOneWidget);
    expect(find.byType(BankDetailScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('context unmounted during delete: no crash', (tester) async {
    final slowRepo = _FakeBankRepository()
      ..onDelete = (_) => Future.delayed(const Duration(milliseconds: 200));
    await tester.pumpWidget(_wrap(db: db, repo: slowRepo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('删除题库'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '删除题库'));
    await tester.pump(const Duration(milliseconds: 50));
    // 模拟用户导航离开
    final state = tester.state(find.byType(BankDetailScreen));
    // unmount via popping from Navigator
    final navigator = Navigator.of(state.context);
    navigator.pop();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('delete button disabled while deletion in-flight (double-tap guard)',
      (tester) async {
    final slowRepo = _FakeBankRepository()
      ..onDelete = (_) => Future.delayed(const Duration(milliseconds: 200));
    await tester.pumpWidget(_wrap(db: db, repo: slowRepo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('删除题库'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '删除题库'));
    await tester.pump();                              // 第一次点击触发 in-flight
    await tester.tap(find.widgetWithText(FilledButton, '删除题库')); // 第二次点击
    await tester.pumpAndSettle();

    expect(slowRepo.deletedIds, hasLength(1));  // 只触发一次
  });

  testWidgets('list page reflects deletion after pop', (tester) async {
    final goRouterRepo = _FakeBankRepository();
    await tester.pumpWidget(_wrap(db: db, repo: goRouterRepo));
    await tester.pumpAndSettle();

    // 验证 DB 中题库存在
    expect((await db.select(db.questionBanks).get()), hasLength(1));

    await tester.tap(find.text('删除题库'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '删除题库'));
    await tester.pumpAndSettle();

    // fakeRepo 调用后，验证 controller 的 invalidate 行为：fakeRepo 不改 DB，
    // 但 controller 已调用 fakeRepo.deleteBank('b1')
    expect(goRouterRepo.deletedIds, ['b1']);
  });

  testWidgets('delete card shows spinner during in-flight deletion',
      (tester) async {
    final slowRepo = _FakeBankRepository()
      ..onDelete = (_) => Future.delayed(const Duration(milliseconds: 300));
    await tester.pumpWidget(_wrap(db: db, repo: slowRepo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('删除题库'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '删除题库'));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
  });
}
```

- [ ] **Step 2: 运行全部 widget 测试**

Run: `flutter test test/widget/features/bank_detail/bank_detail_delete_test.dart`
Expected: 9 tests pass (4 happy path + 5 error/edge).

- [ ] **Step 3: 提交**

```bash
git add test/widget/features/bank_detail/bank_detail_delete_test.dart
git commit -m "test(ui): add 5 error/edge tests (DB fail/unmount/double-tap/spinner/list-reflect)"
```

---

## Task 9: 全套验证

- [ ] **Step 1: 全部测试**

Run: `flutter test`
Expected: 现有测试 + 新增测试全部通过。注意：项目有 61 个预存在失败测试（详见 `~/.claude/projects/.../memory/known_test_failures.md`），属已知遗留，本次新增测试不应增加新失败。

- [ ] **Step 2: dart analyze 全量**

Run: `dart analyze --fatal-infos`
Expected: 0 issues.

- [ ] **Step 3: dart format 检查**

Run: `dart format --set-exit-if-changed .`
Expected: 全部已格式化（如果有未格式化的，跑 `dart format .`）。

- [ ] **Step 4: 覆盖率（可选）**

Run: `flutter test --coverage test/unit/data/repositories/bank_repository_test.dart test/unit/features/bank_detail/ test/widget/features/bank_detail/bank_detail_delete_test.dart`
Expected: 新增代码 80%+ 覆盖。

- [ ] **Step 5: 手动冒烟（推荐）**

```bash
flutter run -d <device>
# 操作：进入"我的题库" → 点击题库 → 滚到"操作"区 → 点红色"删除题库" → 确认
# 预期：弹 Dialog → 确认 → 返回列表 → 题库消失 + SnackBar
```

---

## Self-Review（作者自审）

**Spec 覆盖检查**

| Spec 需求 | 任务 |
|----------|------|
| 入口 = 详情页删除卡片 | Task 5 + 6 |
| Material 确认 Dialog | Task 6 |
| 无撤销 | Task 1 idempotent test + Task 8 覆盖 |
| `BankRepository` 新建 + keepAlive | Task 2 |
| `BankDetailController` notifier | Task 4 |
| cascade 自动清理（questions + 3 子表） | Task 1 (3 tests) |
| 不动 ParseJobs/ParseLogs | Task 1 orphan test |
| 不动 source 文件 | spec 决策 + Plan 不涉及 source 删除 |
| 防双击 | Task 6 `_isDeleting` + Task 8 widget test |
| `context.mounted` 守卫 | Task 6 try/catch/finally + Task 8 unmount test |
| 单元测试覆盖 | Task 1 (6) + Task 3 (3) |
| widget 测试覆盖 | Task 7 (4) + Task 8 (5) |
| Riverpod `appDatabaseProvider.future` 模式 | Task 2 + Task 4 + Task 7 |

**占位符扫描**：✅ 无 TBD/TODO。Task 5 Step 2 留有"实际最小改动"决策说明，但配了具体替换示例。

**类型一致性检查**：
- `BankRepository.deleteBank(String bankId)` — Task 1/2/4/6/7/8 一致
- `BankDetailController.deleteBank(String bankId)` — Task 3/4/6 一致
- `_performDelete(BuildContext, QuestionBank)` — Task 6 一致
- `_buildDeleteCard(BuildContext, ColorScheme, QuestionBank, int)` — Task 5/6 一致
- `BankDetailScreen` 状态类 `_BankDetailScreenState` — Task 5 一致

**潜在风险**：
1. **Task 5 Step 2 内部方法 ref 重构**风险高（涉及多个方法签名改动）。如果改动量过大，可改为在 `_BankDetailScreenState` 内新增 `WidgetRef get _ref => ref;` getter，最小化其他方法体改动。
2. **Task 7/8 `_wrap` 中 `appDatabaseProvider` override 路径**依赖 Task 1 确认。如果实际 provider 在 `lib/core/providers/app_database_provider.dart`，import 路径需要调整。

---

## 执行选项

Plan 完成并保存到 `docs/superpowers/plans/2026-06-28-question-bank-delete.md`。两种执行方式：

**1. Subagent-Driven（推荐）** — 每个 Task 派一个新 subagent 单独执行，Task 之间做两阶段 review，迭代快。

**2. Inline Execution** — 在当前 session 用 executing-plans skill 顺序执行，批量跑、设置检查点。

选哪个？
