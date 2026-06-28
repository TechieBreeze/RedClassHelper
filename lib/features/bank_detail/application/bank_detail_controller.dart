// lib/features/bank_detail/application/bank_detail_controller.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/repositories/bank_repository.dart';
import '../../quiz/providers/bank_pick_provider.dart';

part 'bank_detail_controller.g.dart';

/// 题库详情页控制器 — 持有删除等写操作。
@Riverpod(keepAlive: true)
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