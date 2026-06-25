import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:redclass/data/file_picker/file_picker_models.dart';
import 'package:redclass/features/import/providers/import_state.dart';

void main() {
  group('ImportFile', () {
    test('allows null path for mobile bytes source', () {
      final f = ImportFile.fromPicked(
        PickedBytesFile(name: 'a.pdf', bytes: Uint8List.fromList([1, 2, 3])),
      );
      expect(f.path, isNull);
      expect(f.name, 'a.pdf');
      expect(f.sizeBytes, 3);
    });

    test('fromPicked derives ImportFile from PickedBytesFile', () {
      final picked = PickedBytesFile(
        name: 'a.pdf',
        bytes: Uint8List.fromList([1, 2, 3]),
      );
      final f = ImportFile.fromPicked(picked);
      expect(f.path, isNull);
      expect(f.name, 'a.pdf');
      expect(f.sizeBytes, 3);
    });

    test('fromPicked derives ImportFile from PickedPathFile', () {
      final picked = PickedPathFile(
        path: '/tmp/a.pdf',
        name: 'a.pdf',
        length: 4096,
      );
      final f = ImportFile.fromPicked(picked);
      expect(f.path, '/tmp/a.pdf');
      expect(f.name, 'a.pdf');
      expect(f.sizeBytes, 4096);
    });

    test('fromPath factory creates ImportFile with path', () {
      final f = ImportFile.fromPath(
        path: '/tmp/a.pdf',
        name: 'a.pdf',
        sizeBytes: 1024,
      );
      expect(f.path, '/tmp/a.pdf');
      expect(f.name, 'a.pdf');
      expect(f.sizeBytes, 1024);
    });

    test('source getter exposes the wrapped PickedFile', () {
      final picked = PickedBytesFile(
        name: 'a.pdf',
        bytes: Uint8List.fromList([1, 2, 3]),
      );
      final f = ImportFile.fromPicked(picked);
      expect(f.source, same(picked));
    });
  });
}
