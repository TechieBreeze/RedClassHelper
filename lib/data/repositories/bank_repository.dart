import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../db/database.dart';

part 'bank_repository.g.dart';

abstract interface class BankRepository {
  Future<void> deleteBank(String bankId);
}

class BankRepositoryImpl implements BankRepository {
  BankRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<void> deleteBank(String bankId) async {
    await _db.transaction(() async {
      await (_db.delete(
        _db.questionBanks,
      )..where((t) => t.id.equals(bankId))).go();
    });
  }
}

@Riverpod(keepAlive: true)
Future<BankRepository> bankRepository(Ref ref) async {
  final db = await ref.watch(appDatabaseProvider.future);
  return BankRepositoryImpl(db);
}
