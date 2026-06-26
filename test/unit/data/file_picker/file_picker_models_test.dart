import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:redclass/data/file_picker/file_picker_models.dart';

void main() {
  test('PickedBytesFile openRead returns single-chunk stream', () async {
    final file = PickedBytesFile(
      name: 'a.pdf',
      bytes: Uint8List.fromList([1, 2, 3]),
    );
    final chunks = await file.openRead().toList();
    expect(chunks, hasLength(1));
    expect(chunks.first, [1, 2, 3]);
  });
  test('PickedPathFile exposes path', () {
    final file = PickedPathFile(name: 'a.pdf', path: '/x/a.pdf', length: 10);
    expect(file.path, '/x/a.pdf');
  });
}
