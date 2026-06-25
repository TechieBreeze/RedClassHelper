import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redclass/data/file_picker/file_picker_models.dart';
import 'package:redclass/features/import/providers/import_notifier.dart';

void main() {
  test('notifier accepts PickedFile via receiveFiles', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final picked = PickedBytesFile(
      name: 'a.json',
      bytes: Uint8List.fromList(
        '{"name":"x","version":"1","questions":{}}'.codeUnits,
      ),
    );
    final notifier = container.read(importNotifierProvider.notifier);

    notifier.receiveFiles([picked]);
    expect(container.read(importNotifierProvider).files.length, 1);
    expect(container.read(importNotifierProvider).files.first.path, isNull);
  });
}
