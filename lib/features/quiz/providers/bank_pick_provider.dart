import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/db/database.dart';
import '../../../data/db/tables/question_banks.dart';
import '../../../data/repositories/ledger_repository.dart';

part 'bank_pick_provider.g.dart';

/// 题库选择页的展示数据 -- D-09。
@immutable
class BankPickItem {
  const BankPickItem({
    required this.bank,
    required this.totalQuestions,
    required this.activeWrongCount,
  });

  final QuestionBank bank;
  final int totalQuestions;
  final int activeWrongCount;

  /// 该题库是否无题目。
  bool get isEmpty => totalQuestions == 0;
}

/// 所有题库的展示数据列表 -- 包含题库名称、总题数、错题数 (D-09)。
///
/// 返回 [Future<List<BankPickItem>>], 每个 item 包含:
/// - [QuestionBank] 元数据 (id, name, source, questionCount, createdAt)
/// - 该题库的总题目数 (COUNT from Questions table)
/// - 该题库的活跃错题数 (via LedgerRepository.getActiveByBank)
@riverpod
Future<List<BankPickItem>> bankPickList(Ref ref) async {
  final db = await ref.watch(appDatabaseProvider.future);
  final repo = LedgerRepository(db);

  final banks = await db.select(db.questionBanks).get();

  final items = <BankPickItem>[];
  for (final bank in banks) {
    // Count total questions in this bank (D-09)
    final questionCount = await (db.selectOnly(db.questions)
      ..addColumns([db.questions.id.count()])
      ..where(db.questions.bankId.equals(bank.id))
    ).map((row) => row.read(db.questions.id.count()) ?? 0).getSingle();

    // Count active wrong questions in this bank (D-09)
    final wrongCount = await repo.getActiveByBank(bank.id);

    items.add(BankPickItem(
      bank: bank,
      totalQuestions: questionCount,
      activeWrongCount: wrongCount,
    ));
  }

  return items;
}
