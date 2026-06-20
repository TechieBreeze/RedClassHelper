import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/db/database.dart';
import '../../../data/repositories/ledger_repository.dart';

part 'wrong_questions_provider.g.dart';

/// 错题总数 Stream (D-14, D-15)。
///
/// 返回 [Stream<int>] — 全局活跃错题数 (WHERE mastered_at IS NULL)。
/// 每当 LedgerRepository 中的账本状态变更 (markWrong / markMastered)，
/// 所有监听此 stream 的 widget 自动重建。
///
/// D-14: 用于主页模式卡片右上角 badge 显示。
/// D-15: 答题结束后用于判断是否需要展示"已加入错题本"反馈。
///
/// 使用 async* generator 桥接异步 DB 解析与 Stream 返回。
/// [appDatabaseProvider] 是 keepAlive:true 的 FutureProvider，
/// 所以 DB 解析在应用启动后仅执行一次。
@riverpod
Stream<int> wrongQuestions(Ref ref) async* {
  final db = await ref.watch(appDatabaseProvider.future);
  final repo = LedgerRepository(db);
  yield* repo.watchActiveCount();
}
