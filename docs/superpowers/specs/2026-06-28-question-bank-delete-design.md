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

不复用 `LedgerRepository`（后者语义为错题本），新建 `BankRepository` 封装题库 CRUD。当前只缺 `deleteBank`，未来 `renameBank` / `reorderBanks` / `groupBanks` 都放这里。

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

@riverpod
BankRepository bankRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider).requireValue;
  return BankRepositoryImpl(db);
}
```

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
    ref.invalidate(bankDetailProvider(bankId));
  }
}
```

> 注：`bankDetailProvider(bankId)` 是 `BankDetailScreen.build` 当前已 `ref.watch` 的 provider；如实际未拆分为独立 provider，则只 `invalidate(bankPickListProvider)` 即可。在实现 plan 阶段确认。

### 改动

#### `lib/features/bank_detail/presentation/bank_detail_screen.dart`

1. **新增 `_buildDeleteCard`**：与 `_buildStartReviewCard` / `_buildExportJsonCard` 风格一致，红色 `errorContainer` 底色 + `Icons.delete_outline_rounded` 图标 + `Icons.delete_outline` 文案 "删除题库"，副标题 "删除全部题目、错题、记录（不可撤销）"。

2. **`_buildActionsSection` 追加一行**：在 `_buildExportJsonCard` 后追加 `const SizedBox(height: 8)` 和 `_buildDeleteCard(context, ref, cs, bank)`。

3. **新增 `_showDeleteConfirmDialog`**：弹 `AlertDialog`，标题 `删除「${bank.name}」？`，正文 "将一并删除 ${questions.length} 道题、错题、答题记录。此操作不可撤销。" 取消/删除按钮。

4. **新增 `_performDelete`**：调用 `ref.read(bankDetailControllerProvider.notifier).deleteBank(bankId)`，成功后 `context.safePop()` + SnackBar。

> 不要使用 `ref.read(bankDetailControllerProvider.notifier).deleteBank` 直接调，因为要保证 widget 仍然 mounted。

### 测试

#### `test/unit/data/bank_repository_test.dart`

覆盖：

```dart
group('BankRepository.deleteBank', () {
  late AppDatabase db;
  late BankRepository repo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());  // 见测试约定
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
    // ...类似，验证三层级联
  });

  test('rolls back on error (transaction integrity)', () async {
    // Arrange: 模拟题目插入时抛异常（如 FK 约束）
    // Act: 调用 deleteBank
    // Assert: 题库仍然存在 (transaction 回滚)
  });

  test('throws when bank does not exist', () async {
    expect(
      () => repo.deleteBank('non-existent'),
      throwsA(anything),
    );
  });
});
```

#### `test/widget/features/bank_detail/bank_detail_delete_test.dart`

覆盖：

```dart
testWidgets('shows delete card with destructive color', (tester) async { ... });
testWidgets('opens confirm dialog on tap', (tester) async { ... });
testWidgets('does not delete when dialog cancelled', (tester) async { ... });
testWidgets('deletes and pops when confirmed', (tester) async { ... });
testWidgets('shows SnackBar after deletion', (tester) async { ... });
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
ref.invalidate(bankDetailProvider(bankId))  // 如存在
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
| 大题库删除卡顿 | cascade 是单事务 SQLite 操作，对 ≤ 10000 题的题库应 < 100ms；超大数据集未来可加分批删除 |
| Riverpod invalidate 时序导致 stale UI | `invalidate` 在 `pop` 之前；如未来发现问题再加 `Future.microtask` 延迟 |
| 移动端 SAF 来源字节占用 | 不删除 source 字段；用户重新导入即可重建 |

## 未来扩展（不在本次范围）

- 列表行长按菜单（含删除）
- 撤销（软删除 `deleted_at` schema v3）
- 批量删除
- 题库分组 / 标签