# 题库删除功能设计

| 项目 | 值 |
|------|----|
| 日期 | 2026-06-28 |
| 状态 | Draft (待用户审阅) |
| 作者 | Claude (brainstorming session) |
| 关联 mockup | `docs/superpowers/specs/draft-delete-bank-mockups.html` |

## 背景与动机

RedClass 用户报告：导入的题库没有任何途径可以删除。当前 `BankDetailScreen._buildActionsSection` 仅暴露"开始复习"和"导出 JSON"，`BanksListScreen._BankRow` 只能跳进详情页。drift schema 已配置 `KeyAction.cascade` 外键（`Questions.bankId → QuestionBanks.id` 等），数据库层已经"准备好"——只是缺方法和入口。

## 目标

让用户能够从题库详情页删除一个题库，并保证关联数据（题目、错题、答题记录、收藏）被原子地清理。

## 非目标

- **不做撤销**：误删后可重新导入原文件，不增加 schema 复杂度。
- **不删除源文件**：题库的 `source` / `sourcePath` 可能是原始 .docx/.pdf/.json 路径或字节内容，删除题库不等于删除原始资料。
- **不清理 ParseJobs/ParseLogs**：导入历史审计记录，与题库无 FK 关联，应保留。
- **不动列表行长按/滑动删除**：本次只在详情页加入口。
- **不做批量删除**：一次一个。

## 设计决策

### 决策 1：入口位置 = 详情页"操作"区

在 `BankDetailScreen._buildActionsSection` 追加第三张卡片"删除题库"，红色危险风格，与"导出 JSON"对称。

**理由**：用户对详情页操作区有明确心智模型（"操作 = 改这个题库的事"），可发现性最高。

### 决策 2：确认 = Material AlertDialog

点卡片 → 弹 `AlertDialog`，含题库名 + "将一并删除 N 道题、错题、答题记录。此操作不可撤销。" 取消/删除两个按钮。

**理由**：标准 Material 3 模式，足够防护。

### 决策 3：不实现撤销

SnackBar 仅显示"已删除「X」"，不提供"撤销"按钮。

**理由**：drift FK cascade 级联层级深（题库→题目→错题/答题/收藏），撤销需要复杂快照/恢复逻辑；强行做会引入 schema 升级（软删除 `deleted_at`）或内存快照（仅本次会话有效）。两种方案成本/收益都不划算。

### 决策 4：新建 `BankRepository`

不复用 `LedgerRepository`（后者语义为错题本）。注意：`LedgerRepository` 本身也不通过 Riverpod provider 注入，而是在 `lib/features/quiz/providers/bank_pick_provider.dart:37` 直接 `LedgerRepository(db)` 构造。我们用更规范的 `@Riverpod(keepAlive: true)` async provider 注册 `BankRepository`，未来其他题库操作（rename、reorder、group）也走这个 provider，保持注入一致性。

## 组件与文件改动

### 新增

#### `lib/data/repositories/bank_repository.dart`

```dart
abstract interface class BankRepository {
  Future<void> deleteBank(String bankId);
}

class BankRepositoryImpl implements BankRepository {
  const BankRepositoryImpl(this._db);
  final AppDatabase _db;

  @override
  Future<void> deleteBank(String bankId) async {
    await _db.transaction(() async {
      // 单语句，drift FK cascade 自动级联清理：
      //   questions → answer_attempts / bookmarks / wrong_ledger_entries
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

`keepAlive: true`：BankRepository 是无状态包装层，构造一次即可复用，避免每次 watch 重新构造。

**注意**：BankRepository 必须依赖 `appDatabaseProvider.value`（同步），但 Riverpod 的 `appDatabaseProvider` 是 `Future<AppDatabase>`。在 widget 调用层应使用：

```dart
final db = await ref.read(appDatabaseProvider.future);
final repo = BankRepositoryImpl(db);
```

或更简洁地包一层 provider：

```dart
@riverpod
Future<BankRepository> bankRepository(Ref ref) async {
  final db = await ref.watch(appDatabaseProvider.future);
  return BankRepositoryImpl(db);
}
```

**推荐异步 provider 形式**（与 `bankPickListProvider` 风格一致）。

#### `lib/features/bank_detail/application/bank_detail_controller.dart`

```dart
@riverpod
class BankDetailController extends _$BankDetailController {
  @override
  void build() {}

  Future<void> deleteBank(String bankId) async {
    final repo = await ref.read(bankRepositoryProvider.future);
    await repo.deleteBank(bankId);
    ref.invalidate(bankPickListProvider);
  }
}
```

**防重复点击**：widget 层 (`_performDelete`) 应在调用 `deleteBank` 前 `setState(() => _isDeleting = true)`，将"删除题库"按钮 disable，避免快速双击触发两次事务。

> 注：`BankDetailScreen.build` 当前没有拆出独立的 `bankDetailProvider` —— 直接在 widget 里调 `_loadBankData(db)` 加载数据。删除后 widget 本身会随 `safePop` 销毁，无需 invalidate 自身状态。只 invalidate `bankPickListProvider` 即可让列表页实时反映删除。

### 改动

#### `lib/features/bank_detail/presentation/bank_detail_screen.dart`

1. **新增 `_buildDeleteCard`**：与 `_buildStartReviewCard` / `_buildExportJsonCard` 风格一致，红色 `errorContainer` 底色 + `Icons.delete_outline_rounded` 图标 + `Icons.delete_outline` 文案 "删除题库"，副标题 "删除全部题目、错题、记录（不可撤销）"。

2. **`_buildActionsSection` 追加一行**：在 `_buildExportJsonCard` 后追加 `const SizedBox(height: 8)` 和 `_buildDeleteCard(context, ref, cs, bank)`。

3. **新增 `_showDeleteConfirmDialog`**：弹 `AlertDialog`，标题 `删除「${bank.name}」？`，正文 "将一并删除 ${questions.length} 道题、错题、答题记录。此操作不可撤销。" 取消/删除按钮。

4. **新增 `_performDelete`**：
   ```dart
   if (_isDeleting) return;             // 防双击
   setState(() => _isDeleting = true);
   try {
     await ref.read(bankDetailControllerProvider.notifier).deleteBank(bankId);
     if (!context.mounted) return;      // await 后必须检查
     context.safePop();
     ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(content: Text('已删除「${bank.name}」'), behavior: SnackBarBehavior.floating),
     );
   } on Exception catch (e) {
     if (!context.mounted) return;
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
   ```

### 测试

#### `test/unit/data/bank_repository_test.dart`

覆盖：

```dart
group('BankRepository.deleteBank', () {
  late AppDatabase db;
  late BankRepository repo;

  setUp(() async {
    db = AppDatabase.openInMemoryDatabase();  // 见 ledger_repository_test.dart:13
    repo = BankRepositoryImpl(db);
  });

  tearDown(() async => db.close());

  test('cascades delete to questions', () async {
    // Arrange: 插入题库 + 2 道题
    await db.into(db.questionBanks).insert(bankFixture);
    await db.into(db.questions).insert(questionFixture1);
    await db.into(db.questions).insert(questionFixture2);

    // Act
    await repo.deleteBank(bankFixture.id);

    // Assert
    expect(await db.select(db.questionBanks).get(), isEmpty);
    expect(await db.select(db.questions).get(), isEmpty);
  });

  test('cascades to answer_attempts / bookmarks / wrong_ledger', () async {
    // 完整三层级联：插入 bank → question → answer_attempt + bookmark + wrong_ledger，
    // 删除 bank，断言所有子表为空。
  });

  test('empty bank (0 questions) deletes cleanly without FK violation', () async {
    // 边界：插入空题库，删除应正常返回，无 FK 错误。
  });

  test('preserves orphan parse_jobs after bank deletion', () async {
    // 不变量测试：插入题库 + 引用同一 source_path 的 parse_job（无 FK），
    // 删除题库，断言 parse_job 仍存在。这条守住"不动 ParseJobs"的设计决策。
  });

  test('is idempotent for non-existent bankId', () async {
    // drift 的 delete().go() 在无匹配行时返 0 不抛异常，视为幂等成功。
    await expectLater(repo.deleteBank('non-existent'), completes);
  });

  test('runs inside a transaction', () async {
    // 通过 spy / mock db.verify 验证 db.transaction(...) 被调用，
    // 而非直接调用 db.delete().go()（防回归到无事务实现）。
  });
});
```

> 备注：drift 的 `delete().go()` 在无匹配行时**返回 0，不抛异常**。不要写 `throwsA(anything)`。

#### `test/widget/features/bank_detail/bank_detail_delete_test.dart`

**测试套件初始化**（参考 `test/widget/features/bank_detail/bank_detail_responsive_test.dart` 的 setUp）：

```dart
Widget _wrap({required Widget child, required AppDatabase db}) {
  return ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWith((_) async => db),
    ],
    child: MaterialApp(home: child),
  );
}
```

> 关键：`BankDetailScreen.build` 内部调 `_loadBankData(db)`，没有 `appDatabaseProvider` override 会抛 "no AppDatabase" 错误。这是 spec 初稿漏掉的关键点。

覆盖：

```dart
testWidgets('shows delete card with destructive color', (tester) async { ... });
testWidgets('opens confirm dialog on tap', (tester) async { ... });
testWidgets('does not delete when dialog cancelled', (tester) async { ... });
testWidgets('deletes and pops when confirmed', (tester) async { ... });
testWidgets('shows SnackBar after deletion', (tester) async { ... });
testWidgets('DB failure: shows error SnackBar, no pop, stays on page', (tester) async {
  // override bankRepositoryProvider with fake that throws Exception
  // 点确认删除 → 断言：SnackBar 显示 "删除失败: ..."；context 仍在详情页路由
});
testWidgets('context unmounted during delete: no crash', (tester) async {
  // delete 进行中用 Navigator.pop 模拟用户返回；断言 tester.takeException() 为 null
});
testWidgets('list page reflects deletion after pop', (tester) async {
  // 启动列表页 → 导航到详情页 → 删除 → 断言列表页不再包含该题库
});
testWidgets('delete button disabled while deletion in-flight (prevents double-tap)', (tester) async {
  // mock repository 让 deleteBank 延迟 500ms 返回；
  // 点确认后立即再点删除按钮，断言第二次点击无效（只调一次 repo.deleteBank）
});
```

#### `test/unit/features/bank_detail/bank_detail_controller_test.dart`

```dart
test('deleteBank calls repo and invalidates bankPickListProvider', () async {
  final container = ProviderContainer(overrides: [
    bankRepositoryProvider.overrideWith((_) async => FakeBankRepository()),
  ]);
  addTearDown(container.dispose);

  final controller = container.read(bankDetailControllerProvider.notifier);
  await controller.deleteBank('test-id');

  verify(() => fakeRepo.deleteBank('test-id')).called(1);
  // bankPickListProvider 被 invalidate（重新 build 时会调 fake repo）
  await container.read(bankPickListProvider.future);
  verify(() => fakeRepo.deleteBank('test-id')).called(2);
});
```

## 数据流

```
用户点击 [🗑 删除题库]
        ↓
_showDeleteConfirmDialog(context, ref, bank)
        ↓ 用户点"删除题库"
ref.read(bankDetailControllerProvider.notifier).deleteBank(bankId)
        ↓
ref.read(bankRepositoryProvider.future).deleteBank(bankId)
        ↓
db.transaction(() async {
  await db.delete(db.questionBanks)
    ..where((t) => t.id.equals(bankId)).go();
  // drift cascade 自动清理 questions / answer_attempts / bookmarks / wrong_ledger_entries
})
        ↓
ref.invalidate(bankPickListProvider)
        ↓
context.safePop()
        ↓
ScaffoldMessenger.showSnackBar('已删除「${bank.name}」')
```

## 错误处理

| 失败场景 | 行为 |
|----------|------|
| 数据库事务失败 | 抛 `Exception`，Dialog 内捕获后 SnackBar 显示"删除失败: ${e}"，用户停留在详情页 |
| bankId 不存在 | drift `delete().go()` 返回 affected=0，不抛错 — 视为幂等成功 |
| widget 已 unmount (删除进行中用户返回) | `context.mounted` 检查，跳过 SnackBar；删除本身仍完成 |
| riverpod `appDatabaseProvider` 尚未初始化 | `await ref.read(appDatabaseProvider.future)` 自然阻塞，不会出现 |

## 测试策略

- **单元测试** (BankRepository)：覆盖 cascade 行为、事务回滚、不存在场景
- **Widget 测试** (BankDetailScreen)：覆盖 UI 触发、Dialog 拦截、成功流程
- **覆盖率目标**：≥ 80%（业务逻辑 100%，UI 触发链 100%）
- **不需要**：集成测试 (cascade 已由 drift 验证)；E2E 测试 (交互太短)

## 升级 / 回滚

- 不改 schema，无需迁移
- 不改 API，无需版本
- 改一个 widget + 新增 2 个文件 + 2 个测试文件，回滚 = revert 一次 commit

## 风险

| 风险 | 缓解 |
|------|------|
| 用户误删（无撤销） | Dialog 强制展示题库名 + 列出"将删除什么"；按钮文案直接说"删除题库"而非"确定" |
| 大题库删除卡顿 | drift FK cascade 是单事务 SQLite 递归操作（题库→题→三层子表）。对 ≤ 5000 题的题库应 < 100ms；超大数据集（如 10k+ 题）可能 0.5-2s 阻塞 UI。建议：未来加分批删除 + 进度指示器，本次不做（YAGNI）。 |
| Riverpod invalidate 时序导致 stale UI | `invalidate` 在 `pop` 之前；如未来发现问题再加 `Future.microtask` 延迟 |
| 移动端 SAF 来源字节占用 | 不删除 source 字段；用户重新导入即可重建 |
| 快速双击触发两次删除 | `_performDelete` 入口置 `_isDeleting = true` 并 disable 按钮，事务完成或失败后重置 |

## 未来扩展（不在本次范围）

- 列表行长按菜单（含删除）
- 撤销（软删除 `deleted_at` schema v3）
- 批量删除
- 题库分组 / 标签