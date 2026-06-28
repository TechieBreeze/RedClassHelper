// test/unit/features/import/import_notifier_invalidates_pick_list_test.dart
//
// Regression: import flow wrote QuestionBank + Questions to the DB on success,
// but did NOT invalidate `bankPickListProvider` afterwards. Because
// `bankPickList` is a plain `@riverpod Future<List<BankPickItem>>` (not a
// stream and not listening to drift changes), its cached result stayed stale
// after import — users saw "成功导入 N 道题" on the summary screen, then
// navigated back to /banks and saw no new bank. This test pins down the fix.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redclass/data/db/database.dart';
import 'package:redclass/data/file_picker/file_picker_models.dart';
import 'package:redclass/features/import/providers/import_notifier.dart';
import 'package:redclass/features/quiz/providers/bank_pick_provider.dart';

const String _validJson = '''
{
  "name": "回归测试题库",
  "version": "1.0",
  "questions": {
    "1": {
      "question": "测试问题",
      "answer": {"A": "选项 A", "B": "选项 B"},
      "key": "A",
      "answer_type": 0
    }
  }
}
''';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.openInMemoryDatabase();
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWith((ref) async => db)],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('importJsonFile invalidates bankPickListProvider on success', () async {
    // Step 1: prime the cached value of bankPickListProvider (empty DB).
    final initialBanks = await container.read(bankPickListProvider.future);
    expect(initialBanks, isEmpty);

    // Step 2: trigger import via the JSON fast-track path.
    final notifier = container.read(importNotifierProvider.notifier);
    notifier.receiveFiles([
      PickedBytesFile(
        name: 'regression.json',
        bytes: Uint8List.fromList(utf8.encode(_validJson)),
      ),
    ]);
    await notifier.importJsonFile();

    // Step 3: re-read bankPickListProvider. If the notifier invalidated it,
    // the read triggers a fresh build that sees the freshly inserted bank.
    // If the notifier forgot to invalidate, this read still returns the
    // stale cached empty list and the assertion fails.
    final banksAfter = await container.read(bankPickListProvider.future);
    expect(
      banksAfter.length,
      1,
      reason: 'bankPickListProvider should be invalidated after import',
    );
    expect(banksAfter.first.bank.name, '回归测试题库');
  });
}